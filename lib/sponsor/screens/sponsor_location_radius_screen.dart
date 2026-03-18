import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/sponsor_density_service.dart';
import '../services/sponsor_pricing_service.dart';
import '../widgets/sponsor_map_widget.dart';

class SponsorLocationRadiusScreen extends StatefulWidget {
  final String sponsorId;

  const SponsorLocationRadiusScreen({
    super.key,
    required this.sponsorId,
  });

  @override
  State<SponsorLocationRadiusScreen> createState() =>
      _SponsorLocationRadiusScreenState();
}

class _SponsorLocationRadiusScreenState
    extends State<SponsorLocationRadiusScreen> {

  bool get _hasChanges {

    if (_originalCenter == null || _center == null) return false;

    final locationChanged =
        (_center!.latitude - _originalCenter!.latitude).abs() > 0.00001 ||
            (_center!.longitude - _originalCenter!.longitude).abs() > 0.00001;

    final radiusChanged = _radiusKm != _originalRadiusKm;

    return locationChanged || radiusChanged;
  }

  GoogleMapController? _mapCtrl;
  bool _mapReady = false;

  LatLng? _center;
  int _radiusKm = 30;

// original contract values
  LatLng? _originalCenter;
  int _originalRadiusKm = 30;

  bool _loading = true;
  bool _pricingLoading = false;

  double? _currentPrice;
  double? _newPrice;

  Set<Circle> _circles = {};
  Set<Marker> _markers = {};

// Cluster caching (prevents reloading)
  Set<Marker> _allClusterMarkers = {};
  List<LatLng> _clusterPoints = [];

  Timer? _debounce;

  final Set<String> _activityIds = {};
  final Map<String,String> _activityNames = {};
  final Map<String,double> _activityColors = {};

  int _visibleDensity = 0;
  int _totalDensity = 0;

  ColorScheme get _cs => Theme.of(context).colorScheme;
  TextTheme get _tt => Theme.of(context).textTheme;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _mapCtrl?.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {

      final client = Supabase.instance.client;

      final results = await Future.wait<dynamic>([
        client
            .from('sponsor_locations')
            .select()
            .eq('sponsor_id', widget.sponsorId)
            .maybeSingle(),

        client
            .from('sponsor_contracts')
            .select('price_locked')
            .eq('sponsor_id', widget.sponsorId)
            .eq('status', 'active')
            .maybeSingle(),

        client
            .from('sponsor_activities')
            .select('activity_id')
            .eq('sponsor_id', widget.sponsorId),
      ]);

      final location = results[0] as Map<String, dynamic>?;
      final sub = results[1] as Map<String, dynamic>?;
      final acts = results[2] as List;

      final actIds = acts.map((e) => e['activity_id'] as String).toList();
      _activityIds.addAll(actIds);

      if (actIds.isNotEmpty) {
        final actNames = await client
            .from('activities')
            .select('id,name')
            .inFilter('id', actIds);

        for (final a in actNames) {
          _activityNames[a['id']] =
              (a['name'] as String).replaceAll('_', ' ');
        }
      }

      _generateActivityColors();

      // ================================
      // LOCATION LOAD
      // ================================

      if (location == null) {

        await client.from('sponsor_locations').insert({
          'sponsor_id': widget.sponsorId,
          'lat': -27.4698,
          'lng': 153.0251,
          'radius_km': 30,
        });

        _center = const LatLng(-27.4698, 153.0251);
        _radiusKm = 30;

      } else {

        final lat = (location['lat'] as num?)?.toDouble();
        final lng = (location['lng'] as num?)?.toDouble();

        if (lat != null && lng != null) {
          _center = LatLng(lat, lng);
        } else {
          _center = const LatLng(-27.4698, 153.0251);
        }

        _radiusKm = location['radius_km'] ?? 30;

      }

      _originalCenter = LatLng(_center!.latitude, _center!.longitude);
      _originalRadiusKm = _radiusKm;

      _currentPrice = (sub?['price_locked'] as num?)?.toDouble();

      _rebuildOverlays();

      await Future.wait([
        _loadDensity(),
        _loadPricing(),
      ]);

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _scheduleFitCameraToRadius();

    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  void _generateActivityColors() {

    const hues = [
      BitmapDescriptor.hueRed,
      BitmapDescriptor.hueBlue,
      BitmapDescriptor.hueGreen,
      BitmapDescriptor.hueOrange,
      BitmapDescriptor.hueViolet,
      BitmapDescriptor.hueCyan,
    ];

    int i = 0;

    for (final id in _activityIds) {
      _activityColors[id] = hues[i % hues.length];
      i++;
    }
  }

  void _setCenter(LatLng next) {

    setState(() {
      _center = LatLng(next.latitude, next.longitude);
    });

    _rebuildOverlays();

    _recalculateVisibleClusters();

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      await _loadPricing();
    });
  }

  void _resetToContract() async {

    if (_originalCenter == null) return;

    setState(() {

      _center = _originalCenter;
      _radiusKm = _originalRadiusKm;

    });

    _rebuildOverlays();

    _scheduleFitCameraToRadius();

    _recalculateVisibleClusters();

    await _loadPricing();
  }

  Future<void> _refreshRadiusData() async {
    await _loadDensity();
    await _loadPricing();
  }

  Future<void> _loadDensity() async {

    if (_center == null) return;

    try {

      final result = await SponsorDensityService.loadDensity(
        center: _center!,
        radiusKm: 250, // load a large area once
        activityIds: _activityIds.toList(),
        activityColors: _activityColors,
      );

      // Cache clusters so we don't reload again
      _allClusterMarkers = result.markers;

      setState(() {

        _visibleDensity = result.insideRadius;
        _totalDensity = result.totalPoints;

        final centerMarker =
        _markers.where((m) => m.markerId.value == 'center');

        _markers = {
          ...centerMarker,
          ..._allClusterMarkers,
        };

      });

    } catch (e) {
      debugPrint("Density error: $e");
    }
  }

  void _recalculateVisibleClusters() {

    if (_center == null) return;

    final centerMarker =
    _markers.where((m) => m.markerId.value == 'center');

    setState(() {

      _markers = {
        ...centerMarker,
        ..._allClusterMarkers,
      };

    });
  }

  Future<void> _loadPricing() async {

    if (_center == null) return;

    setState(() => _pricingLoading = true);

    try {

      final result = await SponsorPricingService.loadPricingPreview(
        activityIds: _activityIds.toList(),
        lat: _center!.latitude,
        lng: _center!.longitude,
        radiusKm: _radiusKm,
        sponsorType: "venue",
        activityCount: _activityIds.length,
        coverageType: "local",
        stateCodes: [],
      );

      setState(() {
        _newPrice =
            (result['grand_total'] as num).toDouble();
        _pricingLoading = false;
      });

    } catch (_) {
      setState(() => _pricingLoading = false);
    }
  }

  void _rebuildOverlays() {

    if (_center == null) return;

    final circle = Circle(
      circleId: const CircleId('coverage'),
      center: _center!,
      radius: _radiusKm * 1000,
      strokeWidth: 2,
      strokeColor: Colors.blue,
      fillColor: Colors.blue.withOpacity(.12),
    );

    final marker = Marker(
      markerId: const MarkerId('center'),
      position: _center!,
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      ),
    );

    setState(() {
      _circles = {circle};
      _markers = {marker};
    });
  }

  Timer? _fitDebounce;

  void _scheduleFitCameraToRadius() {

    if (_mapCtrl == null || _center == null) return;

    _fitDebounce?.cancel();

    _fitDebounce = Timer(const Duration(milliseconds: 140), () async {

      if (_mapCtrl == null || _center == null) return;

      final radiusMeters = _radiusKm * 1000.0;

      final north = _offsetLatLng(_center!, radiusMeters, 0);
      final south = _offsetLatLng(_center!, radiusMeters, 180);
      final east = _offsetLatLng(_center!, radiusMeters, 90);
      final west = _offsetLatLng(_center!, radiusMeters, 270);

      final sw = LatLng(
        math.min(south.latitude, north.latitude),
        math.min(west.longitude, east.longitude),
      );

      final ne = LatLng(
        math.max(south.latitude, north.latitude),
        math.max(west.longitude, east.longitude),
      );

      try {

        await _mapCtrl!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: sw,
              northeast: ne,
            ),
            46,
          ),
        );

      } catch (_) {

        await _mapCtrl!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _center!,
              zoom: 11.5,
            ),
          ),
        );

      }
    });
  }

  LatLng _offsetLatLng(LatLng from, double distanceMeters, double bearingDeg) {

    const earthRadius = 6378137.0;

    final bearing = _degToRad(bearingDeg);

    final lat1 = _degToRad(from.latitude);
    final lon1 = _degToRad(from.longitude);

    final dr = distanceMeters / earthRadius;

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(dr) +
          math.cos(lat1) * math.sin(dr) * math.cos(bearing),
    );

    final lon2 = lon1 +
        math.atan2(
          math.sin(bearing) * math.sin(dr) * math.cos(lat1),
          math.cos(dr) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(_radToDeg(lat2), _radToDeg(lon2));
  }

  double _distanceKm(LatLng a, LatLng b) {

    const earthRadius = 6371;

    final dLat = _degToRad(b.latitude - a.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);

    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
            math.cos(lat1) * math.cos(lat2) *
                math.sin(dLng / 2) * math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));

    return earthRadius * c;
  }

  double _degToRad(double d) => d * (math.pi / 180.0);
  double _radToDeg(double r) => r * (180.0 / math.pi);



  Widget _priceCard() {

    if (_pricingLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_newPrice == null) return const SizedBox();

    final diff = _newPrice! - (_currentPrice ?? 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _cs.surfaceVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "Estimated price if updated",
            style: _tt.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.receipt_long),
              const SizedBox(width: 10),
              Expanded(child: Text("Current contract")),
              Text("\$${_currentPrice?.toStringAsFixed(2) ?? '-'}"),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.calculate),
              const SizedBox(width: 10),
              Expanded(child: Text("New estimated price")),
              Text("\$${_newPrice!.toStringAsFixed(2)}"),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.trending_up),
              const SizedBox(width: 10),
              Expanded(child: Text("Difference")),
              Text(
                diff >= 0
                    ? "+\$${diff.toStringAsFixed(2)}"
                    : "-\$${diff.abs().toStringAsFixed(2)}",
                style: TextStyle(
                  color: diff > 0 ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mapCard() {

    if (_center == null) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SponsorMapWidget(
        center: _center!,
        circles: _circles,
        markers: _markers,
        onTap: _setCenter,
        onMapCreated: (c) async {
          _mapCtrl = c;

          // Mark map ready so camera fit can run
          _mapReady = true;

          // Rebuild overlays (circle + center marker)
          _rebuildOverlays();

          // Auto-fit camera to the sponsorship radius
          _scheduleFitCameraToRadius();

          // Load density markers after map exists
          await _loadDensity();
        },
      ),
    );
  }

  Widget _radiusSlider() {

    return Column(
      children: [

        Row(
          children: [
            const Icon(Icons.circle_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Sponsorship radius",
                style: _tt.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Text("$_radiusKm km"),
          ],
        ),

        Slider(
          value: _radiusKm.toDouble(),
          min: 5,
          max: 250,
          divisions: 49,
          label: "$_radiusKm km",
          onChanged: (v) async {

            setState(() {
              _radiusKm = v.round();
            });

            _rebuildOverlays();

            _scheduleFitCameraToRadius();

            _recalculateVisibleClusters();

            await _loadPricing();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    if (_loading) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(

      appBar: AppBar(
        title: const Text("Location & radius"),
      ),

      body: SafeArea(

        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [

            Text(
              "Your sponsorship location",
              style: _tt.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 8),

            Text(
              "Adjust the location or radius to change where your promotion appears.",
              style: _tt.bodyMedium
                  ?.copyWith(color: _cs.onSurfaceVariant),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _cs.primaryContainer,
              ),
              child: Row(
                children: [

                  Icon(
                    Icons.location_on,
                    color: _cs.primary,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      "Current coverage: $_radiusKm km radius",
                      style: _tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _mapCard(),

            const SizedBox(height: 20),

            _radiusSlider(),

            const SizedBox(height: 12),

            if (_hasChanges)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _resetToContract,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reset to current contract"),
                ),
              ),

            const SizedBox(height: 16),

            if (_totalDensity > 0)
              Text(
                "$_visibleDensity of $_totalDensity interest clusters inside your radius",
                style: _tt.bodySmall?.copyWith(
                  color: _cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 20),

            _priceCard(),

            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                icon: const Icon(Icons.update),
                label: const Text("Update contract"),
                onPressed: (!_hasChanges || _newPrice == null)
                    ? null
                    : () {

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Contract update flow would start here",
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "Changing location may affect your monthly sponsorship price.",
              textAlign: TextAlign.center,
              style: _tt.bodySmall
                  ?.copyWith(color: _cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}