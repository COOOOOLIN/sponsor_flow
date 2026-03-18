import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sponsor_access.dart';
import '../services/sponsor_service.dart';

final sponsorServiceProvider = Provider<SponsorService>((ref) {
  return SponsorService(Supabase.instance.client);
});

final sponsorAccessProvider = FutureProvider<SponsorAccess?>((ref) async {
  final service = ref.read(sponsorServiceProvider);
  return service.getMyAccess();
});