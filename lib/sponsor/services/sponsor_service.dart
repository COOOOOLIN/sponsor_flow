import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sponsor_flow/sponsor/models/sponsor_access.dart';
import 'package:sponsor_flow/sponsor/models/sponsor_dashboard_summary.dart';

class SponsorService {
  final SupabaseClient _client;

  SponsorService(this._client);

  /// ------------------------------------------------------------
  /// Get sponsor access for the logged in user
  /// ------------------------------------------------------------
  Future<SponsorAccess?> getMyAccess() async {
    final res = await _client.rpc('get_my_sponsor_access_v1');

    // Supabase RPC can return:
    // - null
    // - []
    // - [{...}]
    if (res == null) return null;
    if (res is List && res.isEmpty) return null;

    final row = (res is List) ? res.first : res;
    if (row is! Map) return null;

    return SponsorAccess.fromJson(Map<String, dynamic>.from(row));
  }

  /// ------------------------------------------------------------
  /// Main sponsor dashboard summary
  /// Optional activity filter
  /// ------------------------------------------------------------
  Future<SponsorDashboardSummary?> getDashboardSummary(String? activityId) async {

    final res = await _client.rpc(
      'sponsor_dashboard_summary_v1',
      params: {
        'p_activity_id': activityId,
      },
    );

    if (res == null) return null;
    if (res is List && res.isEmpty) return null;

    final row = (res is List) ? res.first : res;
    if (row is! Map) return null;

    return SponsorDashboardSummary.fromJson(
      Map<String, dynamic>.from(row),
    );
  }

  /// ------------------------------------------------------------
  /// Per-activity analytics breakdown
  /// Used in Activity Analytics panel
  /// ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getActivityBreakdown(String sponsorId) async {

    final res = await _client.rpc(
      'get_sponsor_activity_breakdown_v1',
      params: {
        'p_sponsor_id': sponsorId,
      },
    );

    if (res == null) return [];

    return List<Map<String, dynamic>>.from(res);
  }
}