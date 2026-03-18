import 'package:flutter/material.dart';
import 'package:sponsor_flow/sponsor/legal/sponsor_terms_screen.dart';
import 'package:sponsor_flow/sponsor/legal/sponsor_cancellation_policy_screen.dart';
import 'package:sponsor_flow/sponsor/legal/sponsor_advertising_policy_screen.dart';
import 'package:sponsor_flow/sponsor/legal/sponsor_privacy_notice_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth/sponsor_auth_gate.dart';

class ContractSelectionScreen extends StatefulWidget {
  final String sponsorType;
  final List<String> activityIds;
  final double lat;
  final double lng;
  final int radiusKm;
  final double monthlyPrice;

  const ContractSelectionScreen({
    super.key,
    required this.sponsorType,
    required this.activityIds,
    required this.lat,
    required this.lng,
    required this.radiusKm,
    required this.monthlyPrice,
  });

  @override
  State<ContractSelectionScreen> createState() =>
      _ContractSelectionScreenState();
}

class _ContractSelectionScreenState extends State<ContractSelectionScreen> {

  bool _loading = false;

  double _selectedMonthlyPrice() {
    switch (_selectedTerm) {
      case '3m':
        return _priceForDiscount(5);
      case '6m':
        return _priceForDiscount(10);
      case '12m':
        return _priceForDiscount(15);
      case 'monthly':
      default:
        return widget.monthlyPrice;
    }
  }

  bool _acceptedTerms = false;

  String _selectedTerm = 'monthly';

  ColorScheme get _cs => Theme.of(context).colorScheme;
  TextTheme get _tt => Theme.of(context).textTheme;

  double _priceForDiscount(double discount) {
    return widget.monthlyPrice * (1 - discount / 100);
  }

  Widget _contractCard({
    required String term,
    required String title,
    required int months,
    required double discount,
    required IconData icon,
    bool highlight = false,
  }) {

    final selected = _selectedTerm == term;
    final price = _priceForDiscount(discount);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTerm = term;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? _cs.primary
                : _cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? _cs.primary.withOpacity(0.05)
              : _cs.surface,
        ),
        child: Row(
          children: [

            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: _cs.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _cs.primary),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    title,
                    style: _tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  if (highlight) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _cs.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "BEST VALUE",
                        style: _tt.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  Text(
                    "$months month contract",
                    style: _tt.bodySmall,
                  ),

                  if (discount > 0)
                    Text(
                      "$discount% discount",
                      style: _tt.bodySmall?.copyWith(
                        color: _cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              )
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [

                Text(
                  "\$${price.toStringAsFixed(2)}",
                  style: _tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _cs.primary,
                  ),
                ),

                Text(
                  "/ month",
                  style: _tt.bodySmall,
                ),
              ],
            ),

            const SizedBox(width: 10),

            Icon(
              selected
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              color: selected
                  ? _cs.primary
                  : _cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _legalSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _cs.outlineVariant,
        ),
        color: _cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.gavel_rounded,
                  size: 20,
                  color: _cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Sponsorship Agreement",
                style: _tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            "Review the sponsorship policies below. You must agree before activating your contract.",
            style: _tt.bodySmall?.copyWith(
              color: _cs.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 16),

          Divider(color: _cs.outlineVariant),

          const SizedBox(height: 8),

          // Policy links
          _policyTile(
            icon: Icons.description_outlined,
            title: "Sponsorship Terms",
            subtitle: "Contract terms and pricing agreement",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SponsorTermsScreen(),
                ),
              );
            },
          ),

          _policyTile(
            icon: Icons.cancel_outlined,
            title: "Cancellation Policy",
            subtitle: "Rules for contract cancellation",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const SponsorCancellationPolicyScreen(),
                ),
              );
            },
          ),

          _policyTile(
            icon: Icons.campaign_outlined,
            title: "Advertising Guidelines",
            subtitle: "Advertising standards and content rules",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const SponsorAdvertisingPolicyScreen(),
                ),
              );
            },
          ),

          _policyTile(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Notice",
            subtitle: "How sponsorship data is handled",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const SponsorPrivacyNoticeScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          Divider(color: _cs.outlineVariant),

          const SizedBox(height: 10),

          // Agreement checkbox
          CheckboxListTile(
            value: _acceptedTerms,
            onChanged: (v) {
              setState(() {
                _acceptedTerms = v ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(
              "I agree to the sponsorship agreement and policies",
              style: _tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _policyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: _cs.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _cs.primary, size: 20),
      ),
      title: Text(
        title,
        style: _tt.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: _cs.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  Widget _launchCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _cs.primary.withOpacity(0.07),
        border: Border.all(
          color: _cs.primary.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Icon(Icons.rocket_launch_outlined, color: _cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Launch opportunity",
                  style: _tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            "The Mates App is launching now. Early sponsors lock in pricing before the user base grows.",
            style: _tt.bodyMedium,
          ),

          const SizedBox(height: 12),

          Text(
            "Growth projections:",
            style: _tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          _projectionRow("6 months", "5,000+ active users"),
          _projectionRow("12 months", "20,000+ active users"),
          _projectionRow("24 months", "50,000+ active users"),

          const SizedBox(height: 10),

          Text(
            "Sponsors who lock pricing now keep today's rates even as the platform grows.",
            style: _tt.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }

  Widget _projectionRow(String time, String users) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.trending_up, size: 18, color: _cs.primary),
          const SizedBox(width: 8),
          Text("$time  →  $users"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Contract"),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [

          Text(
            "Lock in your sponsorship price",
            style: _tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "If the user base grows your price stays locked for the duration of the contract.",
            style: _tt.bodyMedium,
          ),

          const SizedBox(height: 24),

          _launchCard(),

          _contractCard(
            term: "monthly",
            title: "Monthly",
            months: 1,
            discount: 0,
            icon: Icons.calendar_today_outlined,
          ),

          _contractCard(
            term: "3m",
            title: "3 Month Contract",
            months: 3,
            discount: 5,
            icon: Icons.event_repeat_outlined,
          ),

          _contractCard(
            term: "6m",
            title: "6 Month Contract",
            months: 6,
            discount: 10,
            icon: Icons.workspace_premium_outlined,
          ),

          _contractCard(
            term: "12m",
            title: "12 Month Contract",
            months: 12,
            discount: 15,
            icon: Icons.emoji_events_outlined,
            highlight: true,
          ),

          const SizedBox(height: 24),
          _legalSection(),
          const SizedBox(height: 24),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          bottomInset + 16,
        ),
        child: SizedBox(
          height: 54,
          child: FilledButton.icon(
            icon: const Icon(Icons.lock_outline),
            onPressed: _loading
                ? null
                : () async {

              if (!_acceptedTerms) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("You must accept the sponsorship agreement"),
                  ),
                );
                return;
              }

              setState(() {
                _loading = true;
              });

              try {

                final supabase = Supabase.instance.client;

                // 🔐 AUTH GATE (NEW)
                final user = supabase.auth.currentUser;
                if (user == null) {
                  await launchUrl(
                    Uri.parse('https://www.thematesapp.com/login'),
                    mode: LaunchMode.externalApplication,
                  );

                  setState(() => _loading = false);
                  return;
                }

                final session = supabase.auth.currentSession;
                final accessToken = session?.accessToken;

                final response = await supabase.functions.invoke(
                  'create-sponsor-checkout',
                  body: {
                    'sponsor_type': widget.sponsorType,
                    'activity_ids': widget.activityIds,
                    'lat': widget.lat,
                    'lng': widget.lng,
                    'radius_km': widget.radiusKm,
                    'term_type': _selectedTerm,
                    'price_locked': _selectedMonthlyPrice(),
                  },
                  headers: accessToken != null
                      ? {
                    'Authorization': 'Bearer $accessToken',
                  }
                      : {},
                );

                final checkoutUrl = response.data['checkout_url'];

                if (checkoutUrl == null) {
                  throw Exception("Checkout URL missing");
                }

                await launchUrl(
                  Uri.parse(checkoutUrl),
                  mode: LaunchMode.externalApplication, // ✅ web-safe
                );

              } catch (e) {

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Payment error: $e"),
                  ),
                );

              } finally {

                if (mounted) {
                  setState(() {
                    _loading = false;
                  });
                }

              }

            },
            label: _loading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text("Continue to Payment"),
          ),
        ),
      ),
    );
  }
}