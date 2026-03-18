import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sponsor_activity_selection_screen.dart';
import '../services/sponsor_density_service.dart';
import '../widgets/sponsor_map_widget.dart';
import '../services/sponsor_pricing_service.dart';

import 'contract_selection_screen.dart';

class BecomeSponsorScreen extends StatefulWidget {
  const BecomeSponsorScreen({super.key});

  @override
  State<BecomeSponsorScreen> createState() => _BecomeSponsorScreenState();
}

class _BecomeSponsorScreenState extends State<BecomeSponsorScreen> {


  void _showInfoSheet({
    required String title,
    required String message,
    IconData icon = Icons.info_outline,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: _cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ============================
                // HEADER
                // ============================
                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: _cs.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: _cs.primary,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        title,
                        style: _tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ============================
                // CONTENT CARD
                // ============================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: _cs.surfaceVariant.withOpacity(0.35),
                    border: Border.all(
                      color: _cs.outlineVariant.withOpacity(0.7),
                    ),
                  ),
                  child: _buildFormattedMessage(message),
                ),

                const SizedBox(height: 18),

                // ============================
                // CLOSE BUTTON
                // ============================
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Got it'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormattedMessage(String message) {
    final lines = message.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {

        final trimmed = line.trim();

        if (trimmed.isEmpty) {
          return const SizedBox(height: 10);
        }

        // Bullet style lines
        if (trimmed.startsWith('•') ||
            trimmed.startsWith('-') ||
            trimmed.startsWith('*')) {

          final text = trimmed.replaceFirst(RegExp(r'[•\-*]\s*'), '');

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.circle,
                  size: 6,
                  color: _cs.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: _tt.bodyMedium?.copyWith(
                      color: _cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Normal paragraph
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            trimmed,
            style: _tt.bodyMedium?.copyWith(
              color: _cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        );

      }).toList(),
    );
  }


  // ============================================================
// STATE / NATIONAL COVERAGE
// ============================================================

  List<Map<String, dynamic>> _statePricing = [];
  Set<String> _selectedStates = {};
  double? _nationalPrice;

  final Map<String, double> _activityColors = {};

  void _generateActivityColors() {
    const hues = [
      BitmapDescriptor.hueRed,
      BitmapDescriptor.hueBlue,
      BitmapDescriptor.hueGreen,
      BitmapDescriptor.hueOrange,
      BitmapDescriptor.hueViolet,
      BitmapDescriptor.hueCyan,
    ];

    _activityColors.clear();

    int i = 0;




    for (final id in _selectedActivityIds) {
      _activityColors[id] = hues[i % hues.length];
      i++;
    }
  }


  // ============================================================
  // INPUT STATE
  // ============================================================
  String _coverageType = 'local'; // local | state | national
  String _sponsorType = 'venue'; // venue | instructor


  String _sponsorTypeDescription() {
    switch (_sponsorType) {
      case 'venue':
        return 'Venues appear as physical locations where activities take place. '
            'Best for studios, gyms, courts, and event spaces seeking local bookings and foot traffic.';

      case 'instructor':
        return 'Instructors appear as personal trainers or activity leaders. '
            'Ideal for independent professionals offering sessions across multiple locations.';

      default:
        return '';
    }
  }


  String _coverageDescription() {
    switch (_coverageType) {
      case 'local':
        return 'Your sponsorship appears within a selected radius around your map pin. '
            'Best for studios, venues, and hyper-local targeting. Pricing is based on users within your radius.';

      case 'state':
        return 'Your sponsorship appears across your selected state. '
            'Ideal for regional brands or multi-location operators. Radius does not affect pricing.';

      case 'national':
        return 'Your sponsorship is visible nationwide. '
            'Best for large brands seeking broad exposure. Pricing reflects total national reach.';

      default:
        return '';
    }
  }

  // ============================================================
  // ACTIVITY SELECTION STATE
  // ============================================================
  Set<String> _selectedActivityIds = {};
  Map<String, String> _selectedActivityNames = {}; // id -> display name

  // For extra polish, we keep a stable ordered list for rendering chips.
  // This prevents chips from jumping around when map ordering changes.
  List<String> _selectedOrderedIds = [];

  // ============================================================
  // LOCAL-ONLY RADIUS (KM)
  // ============================================================
  int _radiusKm = 30;


  int _visibleDensityCount = 0;
  int _totalDensityPoints = 0;

  // ============================================================
  // MAP STATE
  // ============================================================
  GoogleMapController? _mapCtrl;
  LatLng? _center; // current advertising center (draggable + tappable)
  bool _locLoading = true;

  // Circle + markers
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};

  // Guard to avoid spamming camera animations
  bool _mapReady = false;
  Timer? _fitDebounce;

  // ============================================================
  // PRICING STATE
  // ============================================================
  Map<String, dynamic>? _pricing;
  bool _pricingLoading = false;
  String? _pricingError;

  Timer? _debounce;

  // ============================================================
  // MATERIAL 3 VISUAL CONSTANTS
  // ============================================================
  static const double _pagePad = 16.0;
  static const double _cardRadius = 18.0;
  static const double _sectionGap = 32.0;

  // ============================================================
  // LIFECYCLE
  // ============================================================
  @override
  void initState() {
    super.initState();
    _initLocationAndLoad();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fitDebounce?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  // ============================================================
  // LOCATION
  // ============================================================
  Future<void> _initLocationAndLoad() async {
    setState(() {
      _locLoading = true;
      _pricingError = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw Exception('Location services are disabled.');
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
      if (perm == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied.');
      }

      // ✅ Performance improvement: use medium accuracy (commercial feel / less battery)
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      _center = LatLng(pos.latitude, pos.longitude);

      _rebuildOverlays(shouldFit: false);

      if (_coverageType != 'national') {
        await _loadPricing();
      }

      if (!mounted) return;
      setState(() => _locLoading = false);

      // If map already created (hot reload etc), fit now
      _scheduleFitCameraToRadius();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locLoading = false;
        _pricingError = e.toString();
      });
    }
  }

  void _removeActivity(String id) {
    setState(() {
      _selectedActivityIds.remove(id);
      _selectedActivityNames.remove(id);
      _selectedOrderedIds.remove(id);
    });

    _scheduleRefresh();
  }

  // ============================================================
  // DEBOUNCED REFRESH
  // ============================================================
  void _scheduleRefresh() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () async {

      _rebuildOverlays(shouldFit: true);

      if (_coverageType == 'local') {
        await _loadDensityMarkers();
      }

      await _loadPricing();
    });
  }

  // ============================================================
  // MAP: SET / DRAG CENTER
  // ============================================================
  void _setCenter(LatLng next, {required bool shouldFit}) {
    _center = next;
    _rebuildOverlays(shouldFit: shouldFit);
    _scheduleRefresh();
  }

  // ============================================================
  // OVERLAYS (CIRCLE ALWAYS VISIBLE + CENTER MARKER)
  // ============================================================
  void _rebuildOverlays({required bool shouldFit}) {
    if (_center == null) return;

    // ✅ Circle always visible (even for state/national, it acts as “pin focus”)
    final circle = Circle(
      circleId: const CircleId('coverage'),
      center: _center!,
      // For non-local, keep a subtle “focus” circle rather than removing it
      radius: (_coverageType == 'local' ? _radiusKm : 30) * 1000.0,
      strokeWidth: 2,
      fillColor: Colors.blue.withOpacity(0.10),
      strokeColor: Colors.blue.withOpacity(0.65),
    );

    // ✅ Draggable center marker
    final centerMarker = Marker(
      markerId: const MarkerId('ad_center'),
      position: _center!,
      draggable: false,
      anchor: const Offset(0.5, 1.0),
      infoWindow: InfoWindow(
        title: 'Advertising center',
        snippet: 'Tap map to reposition • Zoom in for precision',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      ),
    );

    setState(() {
      _circles = {circle};
      // Keep any density markers plus our center marker (center marker wins by id)
      final others = _markers.where((m) => m.markerId.value != 'ad_center');
      _markers = {...others, centerMarker};
    });

    if (shouldFit) _scheduleFitCameraToRadius();
  }

  // ============================================================
  // AUTO-FIT CAMERA TO RADIUS
  // ============================================================
  void _scheduleFitCameraToRadius() {
    if (!_mapReady || _mapCtrl == null || _center == null) return;

    _fitDebounce?.cancel();
    _fitDebounce = Timer(const Duration(milliseconds: 140), () async {
      if (!_mapReady || _mapCtrl == null || _center == null) return;

      final radiusMeters = (_coverageType == 'local' ? _radiusKm : 30) * 1000.0;

      // Convert radius to bounds using cardinal points.
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
            LatLngBounds(southwest: sw, northeast: ne),
            46, // padding
          ),
        );
      } catch (_) {
        // Bounds can throw if map not laid out yet; fallback to zoom.
        final fallbackZoom = _coverageType == 'local' ? 11.5 : 6.5;
        await _mapCtrl!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _center!, zoom: fallbackZoom),
          ),
        );
      }
    });
  }

  // Offset helper: distance (m) + bearing (deg)
  LatLng _offsetLatLng(LatLng from, double distanceMeters, double bearingDeg) {
    const earthRadius = 6378137.0; // meters
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

  double _degToRad(double d) => d * (math.pi / 180.0);
  double _radToDeg(double r) => r * (180.0 / math.pi);

  // ============================================================
  // USER DENSITY MARKERS (PLACEHOLDER)
  // ============================================================
// ============================================================
// USER DENSITY MARKERS (DEBUG ENABLED)
// ============================================================
  Future<void> _loadDensityMarkers() async {

    if (_center == null) {
      return;
    }
    if (_selectedActivityIds.isEmpty) {
      return;
    }

    if (_coverageType != 'local') {
      return;
    }
    try {
      final result = await SponsorDensityService.loadDensity(
        center: _center!,
        radiusKm: _radiusKm,
        activityIds: _selectedActivityIds.toList(),
        activityColors: _activityColors,
      );
      final centerMarker =
      _markers.where((m) => m.markerId.value == 'ad_center');

      if (!mounted) return;

      setState(() {
        _visibleDensityCount = result.insideRadius;
        _totalDensityPoints = result.totalPoints;

        _markers = {
          ...centerMarker,
          ...result.markers,
        };
      });

    } catch (e, stack) {
      debugPrint('🔴 [DENSITY] ERROR: $e');
      debugPrint('🔴 [DENSITY] STACK: $stack');
    }
  }

  // ============================================================
  // ACTIVITY NAMES (FOR DISPLAY)
  // ============================================================
  Future<void> _loadSelectedActivityNames(Set<String> ids) async {
    if (ids.isEmpty) {
      _selectedActivityNames = {};
      _selectedOrderedIds = [];
      return;
    }

    try {
      final rows = await Supabase.instance.client
          .from('activities')
          .select('id, name')
          .inFilter('id', ids.toList());

      final map = <String, String>{};
      for (final r in rows) {
        final id = r['id'] as String;
        final name = (r['name'] ?? '').toString().replaceAll('_', ' ').trim();
        if (name.isNotEmpty) map[id] = name;
      }

      // Preserve prior ordering if possible, append new ones at the end
      final existing = _selectedOrderedIds.where(ids.contains).toList();
      final extras = ids.where((id) => !existing.contains(id)).toList();
      _selectedOrderedIds = [...existing, ...extras];

      _selectedActivityNames = map;
    } catch (_) {
      // If names fail to load, we still keep IDs.
      // UI will fall back to showing count only.
    }
  }

  // ============================================================
  // PRICING RPC
  // ============================================================
  Future<void> _loadPricing() async {

    if (_center == null) return;

    // Do not load pricing until at least one activity selected
    if (_selectedActivityIds.isEmpty) {
      if (mounted) {
        setState(() {
          _pricing = null;
          _pricingLoading = false;
          _pricingError = null;
        });
      }
      return;
    }

    setState(() {
      _pricingLoading = true;
      _pricingError = null;
    });

    try {

      final result = await SponsorPricingService.loadPricingPreview(
        activityIds: _selectedActivityIds.toList(),
        lat: _center!.latitude,
        lng: _center!.longitude,
        radiusKm: _radiusKm,
        sponsorType: _sponsorType,
        activityCount: _selectedActivityIds.length,
        coverageType: _coverageType,
        stateCodes: _selectedStates.toList(),
      );

      if (!mounted) return;

      setState(() {
        _pricing = result;
        _pricingLoading = false;
      });

    } catch (e) {

      if (!mounted) return;

      setState(() {
        _pricingLoading = false;
        _pricingError = e.toString();
      });

    }
  }

  // ============================================================
  // UI HELPERS: SECTION + CARDS (Material 3 polish)
  // ============================================================


  Future<void> _loadStatePricing() async {
    try {

      final result = await SponsorPricingService.loadStatePricing(
        sponsorType: _sponsorType,
      );

      if (!mounted) return;

      setState(() {
        _statePricing = result;
      });

    } catch (e) {
      debugPrint('State pricing load error: $e');
    }
  }

  Future<void> _loadNationalPrice() async {

    try {

      final result = await SponsorPricingService.loadNationalPricing(
        sponsorType: _sponsorType,
      );

      if (!mounted) return;

      final price = result['national_price'];

      if (price == null) {
        throw Exception('National price missing from RPC result');
      }

      setState(() {
        _nationalPrice = (price as num).toDouble();
      });

    } catch (e, stack) {

      debugPrint('🔴 National pricing error: $e');
      debugPrint(stack.toString());

      if (!mounted) return;

      setState(() {
        _nationalPrice = null;
      });

    }
  }

  ColorScheme get _cs => Theme.of(context).colorScheme;
  TextTheme get _tt => Theme.of(context).textTheme;

  // Small "pill" info element used for pro UI.
  Widget _infoPill({
    required IconData icon,
    required String label,
    Color? tone,
  }) {
    final bg = (tone ?? _cs.primary).withOpacity(0.10);
    final fg = (tone ?? _cs.primary).withOpacity(0.95);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: (tone ?? _cs.primary).withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Text(
            label,
            style: _tt.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
      String title, {
        IconData? icon,
        String? subtitle,
        Widget? trailing,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: _cs.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: _cs.primary),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: _tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                subtitle,
                style: _tt.bodyMedium?.copyWith(
                  color: _cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _elevatedCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _cs.outlineVariant.withOpacity(0.75)),
        color: _cs.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: child,
    );
  }

  // A small, premium "hero" header to make the page feel commercial.
  Widget _heroHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _cs.outlineVariant.withOpacity(0.7),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _cs.surface,
            _cs.primary.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: _cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: _cs.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Become a Featured Sponsor',
                  style: _tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Choose your reach, select activities, and preview pricing in real time.',
            style: _tt.bodyMedium?.copyWith(
              color: _cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _featureBadge(
                icon: Icons.shield_outlined,
                label: 'Privacy-safe targeting',
              ),
              _featureBadge(
                icon: Icons.bolt_outlined,
                label: 'Live pricing engine',
              ),
              _featureBadge(
                icon: Icons.place_outlined,
                label: 'Pin-based coverage',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureBadge({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _cs.outlineVariant.withOpacity(0.8),
        ),
        color: _cs.surfaceVariant.withOpacity(0.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: _tt.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COVERAGE + SPONSOR TYPE CONTROLS (polished)
  // ============================================================
  Widget _coverageToggle() {
    return _elevatedCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // HEADER
          Row(
            children: [
              Icon(Icons.public, color: _cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Coverage',
                  style: _tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, color: _cs.onSurfaceVariant),
                onPressed: () {
                  _showInfoSheet(
                    title: 'Coverage',
                    icon: Icons.public,
                    message:
                    'Coverage controls how widely your sponsorship appears across The Mates App.\n\n'
                        'Local: Ads appear within a radius around your map pin.\n'
                        'State: Ads appear to users across an entire state.\n'
                        'National: Ads appear to users across the entire country.\n\n'
                        'Choosing a broader coverage increases potential reach but also increases cost.',
                  );
                },
              )
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Choose how widely your sponsorship appears in The Mates App.',
            style: _tt.bodyMedium?.copyWith(
              color: _cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 18),

          _coverageSelector(),

          const SizedBox(height: 18),

          // CONTEXT PANEL
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  _cs.surfaceVariant.withOpacity(0.5),
                  _cs.surfaceVariant.withOpacity(0.2),
                ],
              ),
              border: Border.all(
                color: _cs.outlineVariant.withOpacity(0.8),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ICON
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: _cs.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _coverageType == 'national'
                        ? Icons.public
                        : _coverageType == 'state'
                        ? Icons.map_outlined
                        : Icons.place_outlined,
                    color: _cs.primary,
                  ),
                ),

                const SizedBox(width: 12),

                // TEXT
                Expanded(
                  child: Text(
                    _coverageDescription(),
                    style: _tt.bodyMedium?.copyWith(
                      color: _cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _sponsorTypeToggle() {
    return _elevatedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            children: [
              Icon(Icons.storefront_outlined, color: _cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sponsor type',
                  style: _tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, color: _cs.onSurfaceVariant),
                onPressed: () {
                  _showInfoSheet(
                    title: 'Sponsor Type',
                    icon: Icons.business_center,
                    message:
                    'Sponsor type determines how your business is displayed inside activity listings.\n\n'
                        'Venue: Your location appears as a place where activities happen, such as a gym, studio, or sports venue.\n\n'
                        'Instructor: You appear as a trainer or activity leader offering sessions across multiple locations.',
                  );
                },
              )
            ],
          ),

          const SizedBox(height: 6),

          // SHORT EXPLANATION
          Text(
            'Select how your business is represented inside The Mates App.',
            style: _tt.bodyMedium?.copyWith(
              color: _cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 18),

// SEGMENTED CONTROL (MATCHES COVERAGE STYLE)
          Container(
            height: 52,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _cs.outlineVariant),
              color: _cs.surfaceVariant.withOpacity(0.25),
            ),
            child: Row(
              children: [

                // VENUE
                Expanded(
                  child: GestureDetector(
                    onTap: () async {

                      setState(() {
                        _sponsorType = 'venue';
                      });

                      // Reload state pricing if currently viewing state coverage
                      if (_coverageType == 'state') {
                        await _loadStatePricing();
                      }

                      // Reload national pricing if viewing national coverage
                      if (_coverageType == 'national') {
                        await _loadNationalPrice();
                      }

                      _scheduleRefresh();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: _sponsorType == 'venue'
                            ? _cs.primary.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              size: 18,
                              color: _sponsorType == 'venue'
                                  ? _cs.primary
                                  : _cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Venue',
                              style: _tt.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _sponsorType == 'venue'
                                    ? _cs.primary
                                    : _cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // INSTRUCTOR
                Expanded(
                  child: GestureDetector(
                    onTap: () async {

                      setState(() {
                        _sponsorType = 'instructor';
                      });

                      // Reload state pricing if currently viewing state coverage
                      if (_coverageType == 'state') {
                        await _loadStatePricing();
                      }

                      // Reload national pricing if viewing national coverage
                      if (_coverageType == 'national') {
                        await _loadNationalPrice();
                      }

                      _scheduleRefresh();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: _sponsorType == 'instructor'
                            ? _cs.primary.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 18,
                              color: _sponsorType == 'instructor'
                                  ? _cs.primary
                                  : _cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Instructor',
                              style: _tt.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _sponsorType == 'instructor'
                                    ? _cs.primary
                                    : _cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),

          const SizedBox(height: 18),

          // DYNAMIC CONTEXT BLOCK
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _cs.surfaceVariant.withOpacity(0.4),
              border: Border.all(
                color: _cs.outlineVariant.withOpacity(0.7),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.business_center_outlined,
                  size: 18,
                  color: _cs.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _sponsorTypeDescription(),
                    style: _tt.bodySmall?.copyWith(
                      color: _cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


// ============================================================
// COVERAGE SELECTOR
// ============================================================

  Widget _coverageSelector() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _cs.outlineVariant),
        color: _cs.surfaceVariant.withOpacity(0.25),
      ),
      child: Row(
        children: [
          _coverageSegment(
            value: 'local',
            icon: Icons.place_outlined,
            label: 'Local',
          ),
          _coverageSegment(
            value: 'state',
            icon: Icons.map_outlined,
            label: 'State',
          ),
          _coverageSegment(
            value: 'national',
            icon: Icons.public,
            label: 'National',
          ),
        ],
      ),
    );
  }

  Widget _coverageSegment({
    required String value,
    required IconData icon,
    required String label,
  }) {
    final selected = _coverageType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () async {

          setState(() {
            _coverageType = value;
          });

          if (value == 'state' && _statePricing.isEmpty) {
            await _loadStatePricing();
          }

          if (value == 'national') {
            await _loadNationalPrice();
          }

          _scheduleRefresh();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected ? _cs.primary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? _cs.primary : _cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: _tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected ? _cs.primary : _cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sponsorTypeSegment({
    required String value,
    required IconData icon,
    required String label,
  }) {
    final selected = _sponsorType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () async {

          setState(() {
            _sponsorType = value;
          });

          if (_coverageType == 'state') {
            await _loadStatePricing();
          }

          if (_coverageType == 'national') {
            await _loadNationalPrice();
          }

          _scheduleRefresh();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected
                ? _cs.primary.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? _cs.primary
                      : _cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: _tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? _cs.primary
                        : _cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RADIUS SLIDER (polished)
  // ============================================================
  Widget _radiusSlider() {
    return _elevatedCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle_outlined, color: _cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Local radius',
                  style: _tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              _infoPill(
                icon: Icons.my_location_outlined,
                label: '$_radiusKm km',
                tone: _cs.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            value: _radiusKm.toDouble(),
            min: 5,
            max: 250,
            divisions: 49, // 5 km steps
            label: '$_radiusKm km',
            onChanged: (v) {
              setState(() => _radiusKm = v.round());
              _rebuildOverlays(shouldFit: true);
              _scheduleRefresh();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Tip: Keep it tight for better relevance. You can expand later.',
              style: _tt.bodySmall?.copyWith(
                color: _cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nonLocalCoverageNote() {
    return _elevatedCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: _cs.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _coverageType == 'state'
                  ? 'State coverage does not use a radius for pricing.\nUse the pin as your reference location for listing & discovery.'
                  : 'National coverage does not use a radius for pricing.\nUse the pin as your reference location for listing & discovery.',
              style: _tt.bodyMedium?.copyWith(
                color: _cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _stateSelector() {



    if (_statePricing.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: _statePricing.map((state) {

        final code = state['region_code'];
        final name = state['region_name'];
        final price = (state['state_price'] as num).toDouble();
        final users = (state['user_count'] ?? 0) as int;

        final selected = _selectedStates.contains(code);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? _cs.primary
                  : _cs.outlineVariant,
              width: selected ? 2 : 1,
            ),
            color: selected
                ? _cs.primary.withOpacity(0.06)
                : _cs.surface,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {

              setState(() {
                if (selected) {
                  _selectedStates.remove(code);
                } else {
                  _selectedStates.add(code);
                }
              });

              _scheduleRefresh();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [

                  // STATE ICON
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: _cs.primary.withOpacity(0.12),
                    ),
                    child: Icon(
                      Icons.public,
                      size: 20,
                      color: _cs.primary,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // STATE NAME
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          name,
                          style: _tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '${users.toString()} users',
                          style: _tt.bodySmall?.copyWith(
                            color: _cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // PRICE
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [

                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: _tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: _cs.primary,
                        ),
                      ),

                      Text(
                        '/ month',
                        style: _tt.bodySmall?.copyWith(
                          color: _cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // CHECK ICON
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: selected
                        ? _cs.primary
                        : _cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );

      }).toList(),
    );
  }

  Widget _nationalCard() {

    if (_nationalPrice == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return _elevatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            'National Sponsorship',
            style: _tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 12),

          Text(
            '\$${_nationalPrice!.toStringAsFixed(2)} / month',
            style: _tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: _cs.primary,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Your sponsorship will appear across the entire country.',
            style: _tt.bodySmall,
          ),
        ],
      ),
    );
  }


  // ============================================================
  // MAP CARD (polished + instructions)
  // ============================================================
  Widget _mapCard({required bool canShowMap}) {
    return _elevatedCard(
      padding: const EdgeInsets.all(0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                color: _cs.surface,
                border: Border(
                  bottom: BorderSide(color: _cs.outlineVariant.withOpacity(0.7)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.map_outlined, color: _cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Advertising location',
                      style: _tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),

                  IconButton(
                    icon: Icon(Icons.info_outline, color: _cs.onSurfaceVariant),
                    onPressed: () {
                      _showInfoSheet(
                        title: 'Advertising Location',
                        icon: Icons.map,
                        message:
                        'Your advertising pin represents the centre of your local sponsorship area.\n\n'
                            'Move the pin to the location you want to target.\n'
                            'The circle shows your selected radius.\n\n'
                            'Zooming in helps you place the pin more precisely.',
                      );
                    },
                  )
                ],
              ),
            ),
            SizedBox(
              height: 280,
              child: !canShowMap
                  ? _mapLoadingOrError()
                  : SponsorMapWidget(
                center: _center!,
                circles: _circles,
                markers: _markers,
                onTap: (p) => _setCenter(p, shouldFit: true),
                onMapCreated: (c) async {
                  _mapCtrl = c;
                  _mapReady = true;

                  _rebuildOverlays(shouldFit: false);
                  _scheduleFitCameraToRadius();

                  await _loadDensityMarkers();
                },
              )
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                color: _cs.surface,
                border: Border(
                  top: BorderSide(color: _cs.outlineVariant.withOpacity(0.7)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.touch_app_outlined,
                          color: _cs.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tap to place your pin. Zoom in for more precise placement.',
                          style: _tt.bodySmall?.copyWith(
                            color: _cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _infoPill(
                        icon: Icons.circle_outlined,
                        label: '$_radiusKm km',
                        tone: _cs.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_totalDensityPoints > 0) ...[
                    Text(
                      '$_visibleDensityCount of $_totalDensityPoints interest clusters inside your selected radius.',
                      style: _tt.bodySmall?.copyWith(
                        color: _cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.insights_outlined,
                          size: 18,
                          color: _cs.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pins show clusters of nearby users interested in your selected activities.',
                            style: _tt.bodySmall?.copyWith(
                              color: _cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text(
                        'Each cluster represents users within roughly a 1 km area. '
                            'Locations are grouped to protect individual privacy while still providing '
                            'accurate demand insights.',
                        style: _tt.bodySmall?.copyWith(
                          color: _cs.onSurfaceVariant.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ),

                    if (_selectedActivityNames.isNotEmpty) ...[
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            size: 18,
                            color: _cs.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Activity colour legend',
                            style: _tt.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _selectedActivityNames.entries.map((e) {
                          final hue = _activityColors[e.key] ?? BitmapDescriptor.hueRed;

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: HSVColor.fromAHSV(
                                  1.0,
                                  hue,
                                  1.0,
                                  1.0,
                                ).toColor(),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                e.value,
                                style: _tt.bodySmall,
                              ),
                            ],
                          );
                        }).toList(),
                      ),



                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapLoadingOrError() {
    if (_pricingError != null && _center == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _pricingError!,
            textAlign: TextAlign.center,
            style: _tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: _cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  // ============================================================
  // SPONSORED ACTIVITIES CARD (polished + icons + chips + empty state)
  // ============================================================
  IconData _iconForActivityName(String name) {
    final lower = name.toLowerCase();

    // This is a light heuristic for flair; safe to refine later.
    if (lower.contains('yoga')) return Icons.self_improvement_outlined;
    if (lower.contains('pilates')) return Icons.accessibility_new_outlined;
    if (lower.contains('boxing')) return Icons.sports_mma_outlined;
    if (lower.contains('run') || lower.contains('jog')) return Icons.directions_run_outlined;
    if (lower.contains('walk') || lower.contains('hike')) return Icons.hiking_outlined;
    if (lower.contains('cycle') || lower.contains('bike')) return Icons.directions_bike_outlined;
    if (lower.contains('swim')) return Icons.pool_outlined;
    if (lower.contains('tennis')) return Icons.sports_tennis_outlined;
    if (lower.contains('football') || lower.contains('soccer')) return Icons.sports_soccer_outlined;
    if (lower.contains('basketball')) return Icons.sports_basketball_outlined;
    if (lower.contains('netball')) return Icons.sports_handball_outlined;
    if (lower.contains('dance')) return Icons.music_note_outlined;
    if (lower.contains('gym') || lower.contains('fitness')) return Icons.fitness_center_outlined;

    return Icons.local_activity_outlined;
  }

  Widget _activitySelectorCard() {
    final hasNames = _selectedActivityNames.isNotEmpty;
    final selectedCount = _selectedActivityIds.length;

    // Build ordered names list for stable chip rendering.
    final orderedNames = <String>[];
    if (hasNames && _selectedOrderedIds.isNotEmpty) {
      for (final id in _selectedOrderedIds) {
        final n = _selectedActivityNames[id];
        if (n != null && n.trim().isNotEmpty) orderedNames.add(n);
      }
      // If some are missing (race condition), append remaining
      if (orderedNames.length < _selectedActivityNames.length) {
        for (final e in _selectedActivityNames.entries) {
          if (!orderedNames.contains(e.value)) orderedNames.add(e.value);
        }
      }
    } else if (hasNames) {
      orderedNames.addAll(_selectedActivityNames.values);
    }

    return _elevatedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category_outlined, color: _cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sponsored activities',
                  style: _tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              _infoPill(
                icon: Icons.check_circle_outline,
                label: selectedCount == 1 ? '1 selected' : '$selectedCount selected',
                tone: selectedCount == 0 ? _cs.onSurfaceVariant : _cs.primary,
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (selectedCount == 0) ...[
            _emptySelectionState(),
          ] else ...[
            // Chips with icons (Material 3 polish)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _selectedOrderedIds.map((id) {
                final name = _selectedActivityNames[id] ?? 'Activity';
                final icon = _iconForActivityName(name);
                return _activityChip(
                  id: id,
                  name: name,
                  icon: icon,
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              'These activities will be used to calculate reach and pricing.',
              style: _tt.bodySmall?.copyWith(
                color: _cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.playlist_add_outlined),
              label: Text(selectedCount == 0 ? 'Select activities' : 'Edit selection'),
              onPressed: () async {
                final result = await Navigator.push<Set<String>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SponsorActivitySelectionScreen(
                      initialSelected: _selectedActivityIds,
                    ),
                  ),
                );

                if (result != null) {
                  await _loadSelectedActivityNames(result);
                  _generateActivityColors();

                  setState(() {
                    _selectedActivityIds = result;
                  });

                  _generateActivityColors();

                  await _loadDensityMarkers();
                  _scheduleRefresh();

                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityChip({
    required String name,
    required IconData icon,
    required String id,
  }) {
    final bg = _cs.primary.withOpacity(0.10);
    final border = _cs.primary.withOpacity(0.22);

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: _cs.primary),
            const SizedBox(width: 8),
            Text(
              name,
              style: _tt.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _removeActivity(id),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: _cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptySelectionState() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cs.surfaceVariant.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cs.outlineVariant.withOpacity(0.70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_outlined, color: _cs.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Select one or more activities to sponsor.\nThis keeps your ads relevant and improves conversion.',
              style: _tt.bodyMedium?.copyWith(
                color: _cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRICING CARD (polished)
  // ============================================================
  Widget _pricingCard() {

    if (_selectedActivityIds.isEmpty) {
      return _elevatedCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.price_check_outlined, color: _cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Select activities to preview pricing.',
                style: _tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (_pricingLoading) {
      return _elevatedCard(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_pricingError != null) {
      return _elevatedCard(
        padding: const EdgeInsets.all(14),
        child: Text(
          _pricingError!,
          style: _tt.bodyMedium?.copyWith(color: _cs.error),
        ),
      );
    }

    if (_pricing == null) {
      return const SizedBox();
    }

    final activities = (_pricing!['activities'] ?? []) as List;

    final stateBase = (_pricing!['state_base_total'] ?? 0) as num;
    final nationalBase = (_pricing!['national_base_total'] ?? 0) as num;
    final activityTotal = (_pricing!['activity_total'] ?? 0) as num;

    final grandTotal = _pricing!['grand_total'];

    return _elevatedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: _cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pricing preview',
                  style: _tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ==========================================================
          // BASE COVERAGE COSTS
          // ==========================================================

          if (stateBase > 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _cs.surfaceVariant.withOpacity(0.4),
                border: Border.all(color: _cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.map_outlined, color: _cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'State sponsorship base',
                      style: _tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '\$${stateBase.toStringAsFixed(2)} / month',
                    style: _tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (nationalBase > 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _cs.surfaceVariant.withOpacity(0.4),
                border: Border.all(color: _cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.public, color: _cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'National sponsorship base',
                      style: _tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '\$${nationalBase.toStringAsFixed(2)} / month',
                    style: _tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (activityTotal > 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _cs.surfaceVariant.withOpacity(0.4),
                border: Border.all(color: _cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_activity_outlined, color: _cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Activity targeting',
                      style: _tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '\$${activityTotal.toStringAsFixed(2)} / month',
                    style: _tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ==========================================================
          // ACTIVITY BREAKDOWN
          // ==========================================================

          ...activities.map((a) {

            final activityId = a['activity_id'];
            final rawName = _selectedActivityNames[activityId] ?? 'Activity';

            final name = rawName.isNotEmpty
                ? rawName[0].toUpperCase() + rawName.substring(1)
                : rawName;

            final users = a['eligible_users'];
            final base = a['base_price'];
            final discount = a['discount_percent'];
            final finalPrice = a['final_price'];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _cs.surfaceVariant.withOpacity(0.4),
                border: Border.all(color: _cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    name,
                    style: _tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 10),

                  _pricingRow(
                    icon: Icons.groups_outlined,
                    label: 'Eligible users',
                    value: users.toString(),
                  ),

                  const SizedBox(height: 6),

                  _pricingRow(
                    icon: Icons.payments_outlined,
                    label: 'Base price',
                    value: '\$$base',
                  ),

                  const SizedBox(height: 6),

                  _pricingRow(
                    icon: Icons.discount_outlined,
                    label: 'Discount',
                    value: '$discount%',
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Spacer(),
                      Text(
                        '\$${(finalPrice as num).toDouble().toStringAsFixed(2)} / month',
                        style: _tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: _cs.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );

          }),

          const SizedBox(height: 10),

          // ==========================================================
          // GRAND TOTAL
          // ==========================================================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _cs.primary.withOpacity(0.10),
              border: Border.all(color: _cs.primary.withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Icon(Icons.workspace_premium, color: _cs.primary),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        'Grand total',
                        style: _tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        '\$${(grandTotal as num).toDouble().toStringAsFixed(2)} / month',
                        style: _tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: _cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'All prices shown are monthly sponsorship costs. Pricing is calculated securely by the sponsorship engine based on coverage, location, and activity demand.',
            style: _tt.bodySmall?.copyWith(
              color: _cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),

        ],
      ),
    );
  }

  Widget _pricingRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _cs.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: _tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),

        Text(
          value,
          style: _tt.bodyMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.1,
          ),

        ),
      ],
    );
  }

  Widget _hintForRpcMismatchIfPresent(String err) {
    final lower = err.toLowerCase();
    final looksLikeSignature = lower.contains('could not find the function') &&
        (lower.contains('p_activity_ids') || lower.contains('p_activity_id'));

    if (!looksLikeSignature) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cs.tertiary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cs.tertiary.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.build_outlined, color: _cs.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'It looks like your database function signature is out of sync.\n'
                  'Your app is sending p_activity_ids (UUID[]), but the DB may still expect p_activity_id (UUID).\n'
                  'Update the RPC to accept UUID[] or add a wrapper function.',
              style: _tt.bodySmall?.copyWith(
                color: _cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CTA BUTTON (polished + disabled rules)
  // ============================================================
  bool get _canContinue {
    if (_locLoading) return false;
    if (_center == null) return false;
    if (_selectedActivityIds.isEmpty) return false;

    // 🔴 REQUIRE STATE SELECTION
    if (_coverageType == 'state' && _selectedStates.isEmpty) return false;

    if (_pricingLoading) return false;
    if (_pricingError != null) return false;
    if (_pricing == null) return false;

    return true;
  }

  Widget _continueCta() {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _canContinue
            ? () {

          final price = (_pricing!['grand_total'] as num).toDouble();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContractSelectionScreen(
                sponsorType: _sponsorType,
                activityIds: _selectedActivityIds.toList(),
                lat: _center!.latitude,
                lng: _center!.longitude,
                radiusKm: _radiusKm,
                monthlyPrice: price,
              ),
            ),
          );

        }
            : null,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Continue'),
      ),
    );
  }

  Widget _ctaHint() {
    if (_canContinue) return const SizedBox.shrink();

    String msg = 'Complete the steps above to continue.';
    IconData icon = Icons.info_outline;

    if (_selectedActivityIds.isEmpty) {
      msg = 'Select at least one activity to sponsor.';
      icon = Icons.category_outlined;
    } else if (_pricingError != null) {
      msg = 'Fix the pricing error to continue.';
      icon = Icons.error_outline;
    } else if (_pricing == null) {
      msg = 'Pricing preview will appear once loaded.';
      icon = Icons.price_check_outlined;
    } else if (_pricingLoading) {
      msg = 'Calculating pricing…';
      icon = Icons.hourglass_bottom_outlined;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: _tt.bodySmall?.copyWith(
                color: _cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final canShowMap = !_locLoading && _center != null;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sponsorship',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                'Featured Sponsor Setup',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh pricing',
            onPressed: _pricingLoading ? null : _loadPricing,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
    body: SafeArea(
    bottom: true,
    child: _locLoading
    ? const Center(child: CircularProgressIndicator())
        : ListView(
        padding: const EdgeInsets.all(_pagePad),
        children: [
          _heroHeader(),
          const SizedBox(height: _sectionGap),

          // -------------------------
          // YOUR REACH
          // -------------------------
          _sectionTitle(
            'Your reach',
            icon: Icons.radar_outlined,
            subtitle:
            'Pick a coverage tier and fine-tune the local radius. Your map pin is the reference point.',
          ),
          const SizedBox(height: 24),
          _coverageToggle(),
          const SizedBox(height: 24),
          _sponsorTypeToggle(),
          const SizedBox(height: 24),

          // -------------------------
          // ACTIVITIES
          // -------------------------
          _sectionTitle(
            'Sponsored activities',
            icon: Icons.local_activity_outlined,
            subtitle:
            'Select what you want to sponsor so your ads appear in the right places.',
          ),
          const SizedBox(height: 24),
          _activitySelectorCard(),
          const SizedBox(height: _sectionGap),

          // -------------------------
          // MAP
          // -------------------------
// -------------------------
// MAP / STATE / NATIONAL
// -------------------------

          if (_coverageType == 'local') ...[

            _sectionTitle(
              'Map',
              icon: Icons.map_outlined,
              subtitle:
              'Place your advertising pin. The circle shows your radius for local coverage.',
            ),

            const SizedBox(height: _sectionGap),

            _radiusSlider(),
            const SizedBox(height: 24),
            _mapCard(canShowMap: canShowMap),

          ],

          if (_coverageType == 'state') ...[

            _sectionTitle(
              'Select states',
              icon: Icons.map_outlined,
              subtitle:
              'Choose which states your sponsorship will appear in.',
            ),

            const SizedBox(height: 24),

            _stateSelector(),

          ],

          if (_coverageType == 'national') ...[

            _sectionTitle(
              'National coverage',
              icon: Icons.public,
              subtitle:
              'Your sponsorship will appear across the entire country.',
            ),

            const SizedBox(height: 24),

            _nationalCard(),

          ],

          // -------------------------
          // PRICING
          // -------------------------
          const SizedBox(height: _sectionGap),
          _sectionTitle(
            'Pricing preview',
            icon: Icons.price_check_outlined,
            subtitle:
            'A live preview based on location, coverage, and selected activities.',
          ),
          const SizedBox(height: 24),
          _pricingCard(),
          const SizedBox(height: _sectionGap),

          // -------------------------
          // CTA
          // -------------------------
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _continueCta(),
          ),
          _ctaHint(),
          const SizedBox(height: 24),

          // Footer spacing / subtle brand line
          Center(
            child: Text(
              'Powered by The Mates App Sponsorship Engine',
              style: _tt.bodySmall?.copyWith(
                color: _cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    ),
    );
  }
}