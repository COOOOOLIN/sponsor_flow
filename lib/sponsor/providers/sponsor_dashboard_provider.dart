import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sponsor_dashboard_summary.dart';
import 'sponsor_access_provider.dart';

final sponsorDashboardProvider =
FutureProvider.family<SponsorDashboardSummary?, String?>((ref, activityId) async {

  final access = await ref.watch(sponsorAccessProvider.future);
  if (access == null) return null;

  final service = ref.read(sponsorServiceProvider);

  return service.getDashboardSummary(activityId);

});