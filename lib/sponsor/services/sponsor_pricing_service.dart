import 'package:supabase_flutter/supabase_flutter.dart';

class SponsorPricingService {
  static final _client = Supabase.instance.client;

  // ==========================================================
  // PRICING PREVIEW (SECURE BACKEND ENGINE)
  // ==========================================================

  static Future<Map<String, dynamic>> loadPricingPreview({
    required List<String> activityIds,
    required double lat,
    required double lng,
    required int radiusKm,
    required String sponsorType,
    required int activityCount,
    required String coverageType,
    List<String> stateCodes = const [],
  }) async {
    final result = await _client.rpc(
      'rpc_get_sponsor_pricing_preview_v2',
      params: {
        'p_activity_ids': activityIds,
        'p_lat': lat,
        'p_lng': lng,
        'p_radius_km': radiusKm,
        'p_sponsor_type': sponsorType,
        'p_activity_count': activityCount,
        'p_coverage_type': coverageType,
        'p_state_codes': stateCodes,
      },
    );

    return Map<String, dynamic>.from(result as Map);
  }

  // ==========================================================
  // STATE PRICING LIST
  // ==========================================================

  static Future<List<Map<String, dynamic>>> loadStatePricing({
    required String sponsorType,
  }) async {

    final result = await _client.rpc(
      'rpc_get_state_sponsorship_prices',
      params: {
        'p_sponsor_type': sponsorType,
      },
    );

    return List<Map<String, dynamic>>.from(result);
  }

  // ==========================================================
  // NATIONAL PRICING
  // ==========================================================

  static Future<Map<String, dynamic>> loadNationalPricing({
    required String sponsorType,
  }) async {

    final result = await _client.rpc(
      'rpc_get_national_sponsorship_price',
      params: {
        'p_sponsor_type': sponsorType,
      },
    );

    return Map<String, dynamic>.from((result as List).first as Map);
  }
}