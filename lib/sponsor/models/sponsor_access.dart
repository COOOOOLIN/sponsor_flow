class SponsorAccess {
  final String sponsorId;
  final String role; // owner | staff

  const SponsorAccess({
    required this.sponsorId,
    required this.role,
  });

  factory SponsorAccess.fromJson(Map<String, dynamic> json) {
    return SponsorAccess(
      sponsorId: json['sponsor_id'] as String,
      role: json['role'] as String,
    );
  }

  bool get isOwner => role == 'owner';
}