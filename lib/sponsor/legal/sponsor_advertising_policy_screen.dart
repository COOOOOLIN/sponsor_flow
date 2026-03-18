import 'package:flutter/material.dart';

class SponsorAdvertisingPolicyScreen extends StatelessWidget {
  const SponsorAdvertisingPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Advertising Guidelines"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _header(
              icon: Icons.campaign_outlined,
              title: "Advertising Guidelines",
              subtitle:
              "These rules ensure sponsorship placements remain trustworthy and relevant.",
              cs: cs,
              tt: tt,
            ),

            const SizedBox(height: 24),

            _bullet(tt, "Advertising must be truthful and accurate."),
            _bullet(tt, "Advertising must not mislead users."),
            _bullet(tt, "Illegal products or services are prohibited."),
            _bullet(tt, "Content must not be offensive, harmful or discriminatory."),
            _bullet(tt, "The platform may remove advertisements that violate these rules."),
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

  Widget _bullet(TextTheme tt, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• "),
          Expanded(child: Text(text, style: tt.bodyMedium)),
        ],
      ),
    );
  }
}