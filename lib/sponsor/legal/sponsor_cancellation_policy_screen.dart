import 'package:flutter/material.dart';

class SponsorCancellationPolicyScreen extends StatelessWidget {
  const SponsorCancellationPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cancellation Policy"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _header(
              icon: Icons.cancel_outlined,
              title: "Cancellation Policy",
              subtitle:
              "These rules describe how sponsorship contracts can be cancelled.",
              cs: cs,
              tt: tt,
            ),

            const SizedBox(height: 24),

            _section(
              tt,
              "Monthly Plans",
              "Monthly sponsorships may be cancelled at any time. Cancellation takes effect at the end of the current billing period.",
            ),

            _section(
              tt,
              "Fixed-Term Contracts",
              "3-month, 6-month and 12-month contracts are locked for the selected duration and are non-refundable.",
            ),

            _section(
              tt,
              "Failure to Pay",
              "If a payment fails, sponsorship placement may be paused or removed until payment is resolved.",
            ),

            _section(
              tt,
              "Platform Termination",
              "The platform reserves the right to suspend or terminate sponsorships that violate advertising policies or legal requirements.",
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