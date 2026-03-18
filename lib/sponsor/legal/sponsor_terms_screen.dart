import 'package:flutter/material.dart';

class SponsorTermsScreen extends StatelessWidget {
  const SponsorTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
        appBar: AppBar(
        title: const Text("Sponsorship Terms"),
    ),
    body: SafeArea(
    child: SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

            _header(
              icon: Icons.description_outlined,
              title: "Sponsorship Agreement",
              subtitle:
              "These terms govern the sponsorship relationship between your business and The Mates App.",
              cs: cs,
              tt: tt,
            ),

            const SizedBox(height: 24),

            _section(
              tt,
              "1. Sponsorship Placement",
              "Sponsors are displayed within The Mates App based on activity categories, geographic targeting and platform ranking algorithms. Placement order may change over time as the platform evolves.",
            ),

            _section(
              tt,
              "2. Pricing",
              "Prices shown are monthly rates. Selecting a multi-month contract locks the monthly rate for the duration of the selected contract term.",
            ),

            _section(
              tt,
              "3. No Performance Guarantee",
              "The Mates App does not guarantee bookings, enquiries, leads or revenue from sponsorship placements.",
            ),

            _section(
              tt,
              "4. Platform Changes",
              "The platform may modify interface design, ranking systems, algorithms or feature availability at any time to improve the product.",
            ),

            _section(
              tt,
              "5. Content Rules",
              "Sponsors must ensure that all information provided is accurate and does not contain misleading, illegal or harmful content.",
            ),

            _section(
              tt,
              "6. Liability",
              "The Mates App is not responsible for financial outcomes, user behaviour, or business results resulting from sponsorship placement.",
            ),

            _section(
              tt,
              "7. Governing Law",
              "This agreement is governed by the laws of the jurisdiction in which the platform operator is registered.",
            ),
          ],
        ),
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