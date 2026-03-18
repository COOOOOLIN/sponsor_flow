import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SponsorDensityPoint {
  final LatLng location;
  final int userCount;
  final String activityId;

  SponsorDensityPoint({
    required this.location,
    required this.userCount,
    required this.activityId,
  });
}

class SponsorDensityResult {
  final Set<Marker> markers;
  final int totalPoints;
  final int insideRadius;

  SponsorDensityResult({
    required this.markers,
    required this.totalPoints,
    required this.insideRadius,
  });
}

class SponsorDensityService {
  static Future<SponsorDensityResult> loadDensity({
    required LatLng center,
    required int radiusKm,
    required List<String> activityIds,
    required Map<String,double> activityColors,
  }) async {
    final client = Supabase.instance.client;

    // 🔹 Replace with your real RPC name
    debugPrint('🔵 [RPC] Calling rpc_get_activity_interest_density_v1');
    debugPrint('🔵 [RPC] Activity IDs: $activityIds');

    final rows = await client.rpc(
      'rpc_get_activity_interest_density_v1',
      params: {
        'p_activity_ids': activityIds,
        'p_lat': center.latitude,
        'p_lng': center.longitude,
        'p_radius_km': radiusKm,
      },
    );

    debugPrint('🔵 [RPC] Raw rows type: ${rows.runtimeType}');
    debugPrint('🔵 [RPC] Raw rows: $rows');
    debugPrint('🔵 [RPC] Row count: ${rows is List ? rows.length : 'NOT A LIST'}');

    final List<SponsorDensityPoint> points = [];

    for (final r in rows) {
      points.add(
        SponsorDensityPoint(
          location: LatLng(
            (r['lat'] as num).toDouble(),
            (r['lng'] as num).toDouble(),
          ),
          userCount: r['user_count'] as int,
          activityId: r['activity_id'].toString(),
        ),
      );
    }

    final markers = <Marker>{};
    int inside = 0;

    final rand = math.Random();

    for (final p in points) {
      final distanceKm = _distanceKm(center, p.location);

      final isInside = distanceKm <= radiusKm;
      if (isInside) inside++;

      final hue =
          activityColors[p.activityId] ?? BitmapDescriptor.hueRed;

      // 🔒 Privacy offset (3–8km randomised)
      final randomDistanceKm = 3 + rand.nextDouble() * 5; // 3–8 km
      final randomBearing = rand.nextDouble() * 360;

      final offsetLocation = _offsetLatLng(
        p.location,
        randomDistanceKm * 1000,
        randomBearing,
      );

      markers.add(
        Marker(
          markerId: MarkerId(
            'density_${offsetLocation.latitude}_${offsetLocation.longitude}_${p.activityId}',
          ),
          position: offsetLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: '${p.userCount} interested users',
            snippet: isInside
                ? 'Inside selected radius'
                : 'Outside selected radius',
          ),
        ),
      );
    }



    return SponsorDensityResult(
      markers: markers,
      totalPoints: points.length,
      insideRadius: inside,
    );
  }

  static double _distanceKm(LatLng a, LatLng b) {
    const R = 6371; // km
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);

    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);

    final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
    return R * c;
  }

  static LatLng _offsetLatLng(
      LatLng from,
      double distanceMeters,
      double bearingDeg,
      ) {
    const earthRadius = 6378137.0;

    final bearing = bearingDeg * (math.pi / 180);

    final lat1 = from.latitude * (math.pi / 180);
    final lon1 = from.longitude * (math.pi / 180);

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

    return LatLng(
      lat2 * (180 / math.pi),
      lon2 * (180 / math.pi),
    );
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180);
}