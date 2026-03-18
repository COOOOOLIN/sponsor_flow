// lib/sponsor/utils/sponsor_access_utils.dart

import 'package:sponsor_flow/sponsor/services/sponsor_service.dart';

Future<bool> isUserSponsor(SponsorService service) async {
  final access = await service.getMyAccess();
  return access != null;
}