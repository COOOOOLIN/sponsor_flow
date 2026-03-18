import 'package:flutter/material.dart';

class SponsorPrivacyNoticeScreen extends StatelessWidget {
  const SponsorPrivacyNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Notice"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _header(
              icon: Icons.privacy_tip_outlined,
              title: "Sponsor Privacy Notice",
              subtitle:
              "How sponsorship analytics and business data are handled.",
              cs: cs,
              tt: tt,
            ),

            const SizedBox(height: 24),

            _section(
              tt,
              "Analytics Data",
              "The Mates App may collect anonymous analytics related to sponsorship performance.",
            ),

            _section(
              tt,
              "Examples of Analytics",
              "This may include advertisement impressions, engagement metrics and location targeting effectiveness.",
            ),

            _section(
              tt,
              "User Privacy",
              "Personal user data is never shared directly with sponsors.",
            ),

            _section(
              tt,
              "Compliance",
              "All data handling complies with applicable privacy and data protection laws.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _header({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme cs,
    required TextTheme tt,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: cs.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle, style: tt.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(TextTheme tt, String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(text, style: tt.bodyMedium),
        ],
      ),
    );
  }
}