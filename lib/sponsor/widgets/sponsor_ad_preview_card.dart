import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SponsorAdPreviewCard extends StatelessWidget {
  final String sponsorId;

  const SponsorAdPreviewCard({
    super.key,
    required this.sponsorId,
  });

  @override
  Widget build(BuildContext context) {
    final future = Supabase.instance.client
        .from('sponsor_activity_profiles')
        .select('''
          business_name,
          logo_path,
          about_text,
          website_url,
          offer_title,
          offer_description
        ''')
        .eq('sponsor_id', sponsorId);

    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const CircularProgressIndicator(),
          );
        }

        final profiles = snapshot.data!;
        if (profiles.isEmpty) {
          return Container(
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text('No advertising profile yet'),
          );
        }

        final profile = Map<String, dynamic>.from(profiles.first as Map);

        String? logoUrl;
        final logoPath = profile['logo_path']?.toString();
        if (logoPath != null && logoPath.trim().isNotEmpty) {
          logoUrl = Supabase.instance.client.storage
              .from('sponsor-logos')
              .getPublicUrl(logoPath);
        }

        final businessName =
        (profile['business_name'] ?? 'Your business').toString();
        final aboutText =
        (profile['about_text'] ?? 'Add your business profile details.')
            .toString();
        final offerTitle = profile['offer_title']?.toString();
        final offerDescription = profile['offer_description']?.toString();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Advertising preview',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (logoUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          logoUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.storefront_outlined),
                      ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            businessName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            aboutText,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.3,
                            ),
                          ),
                          if (offerTitle != null && offerTitle.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              offerTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          if (offerDescription != null &&
                              offerDescription.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              offerDescription,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This is a simple website preview of your sponsorship card.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}