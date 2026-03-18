import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/sponsor_dashboard_provider.dart';
import 'become_sponsor_screen.dart';

class SponsorBillingContractScreen extends ConsumerStatefulWidget {
  const SponsorBillingContractScreen({super.key});

  @override
  ConsumerState<SponsorBillingContractScreen> createState() =>
      _SponsorBillingContractScreenState();
}

class _SponsorBillingContractScreenState
    extends ConsumerState<SponsorBillingContractScreen> {

  bool _processing = false;

  ColorScheme get _cs => Theme.of(context).colorScheme;
  TextTheme get _tt => Theme.of(context).textTheme;

  Future<void> _openStripePortal(String sponsorId) async {

    setState(() => _processing = true);

    try {

      final result = await Supabase.instance.client.functions.invoke(
        'create_stripe_portal_session',
        body: {
          "sponsor_id": sponsorId
        },
      );

      final url = result.data['url'];

      if (url != null && mounted) {
        Navigator.pushNamed(context, '/external', arguments: url);
      }

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to open billing portal: $e"),
        ),
      );
    }

    if (mounted) {
      setState(() => _processing = false);
    }
  }

  Future<void> _cancelContract(String sponsorId) async {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {

        final tt = Theme.of(context).textTheme;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Cancel automatic renewal",
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Text(
                  "Your sponsorship will remain active until the end of the current billing period.",
                  style: tt.bodyMedium?.copyWith(height: 1.35),
                ),

                const SizedBox(height: 10),

                Text(
                  "After this date your promotion will stop appearing in the app unless you restart your sponsorship.",
                  style: tt.bodyMedium?.copyWith(height: 1.35),
                ),

                const SizedBox(height: 10),

                Text(
                  "You can reactivate your sponsorship at any time.",
                  style: tt.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Cancel renewal"),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Keep sponsorship"),
                  ),
                ),

              ],
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    setState(() => _processing = true);

    try {

      await Supabase.instance.client.rpc(
        "cancel_sponsor_contract_v1",
        params: {
          "p_sponsor_id": sponsorId
        },
      );

      if (mounted) {
        ref.invalidate(sponsorDashboardProvider(null));
      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cancellation failed: $e"),
        ),
      );
    }

    if (mounted) {
      setState(() => _processing = false);
    }
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {

    final dashAsync = ref.watch(sponsorDashboardProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Billing & Contract"),
      ),
      body: SafeArea(
        child: dashAsync.when(

          loading: () =>
          const Center(child: CircularProgressIndicator()),

          error: (e, _) =>
              Center(child: Text("Failed to load billing: $e")),

          data: (summary) {

            if (summary == null) {
              return const Center(
                child: Text("No sponsorship found"),
              );
            }

            final contractEnd = summary.contractEnd;
            final nextBilling = summary.nextBillingDate;

            final isSubscription =
                nextBilling != null &&
                    contractEnd != null &&
                    !nextBilling.isAtSameMomentAs(contractEnd);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [

                /// CONTRACT OVERVIEW
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        "Contract overview",
                        style: _tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 14),

                      _row("Status", summary.contractStatus),
                      _row("Tier", summary.tierName ?? "—"),
                      _row("Locked price",
                          "\$${summary.priceLocked?.toStringAsFixed(0) ?? "—"} / month"),

                      if (contractEnd != null)
                        _row(
                          "Contract ends",
                          "${contractEnd.day}/${contractEnd.month}/${contractEnd.year}",
                        ),

                      if (isSubscription)
                        _row(
                          "Next billing date",
                          "${nextBilling!.day}/${nextBilling.month}/${nextBilling.year}",
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// GROWTH / RETENTION PANEL
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: const [
                          Icon(Icons.trending_up_outlined),
                          SizedBox(width: 8),
                          Text(
                            "Grow your activity",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Sponsors who stay active longer reach significantly more players as the community grows.",
                        style: TextStyle(height: 1.35),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Consider extending your sponsorship to lock your price while the user base expands.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.upgrade),
                          label: const Text("View longer plans"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BecomeSponsorScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// PAYMENT MANAGEMENT
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        "Payment management",
                        style: _tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.credit_card),
                          label: const Text("Manage payment method"),
                          onPressed: _processing
                              ? null
                              : () => _openStripePortal(summary.sponsorId),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.receipt_long),
                          label: const Text("View invoices"),
                          onPressed: _processing
                              ? null
                              : () => _openStripePortal(summary.sponsorId),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// CONTRACT ACTIONS
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        "Contract actions",
                        style: _tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.autorenew),
                          label: const Text("Extend sponsorship"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BecomeSponsorScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text("Cancel contract"),
                          onPressed: _processing
                              ? null
                              : () => _cancelContract(summary.sponsorId),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  "Your sponsorship will remain active until the contract end date if cancelled.",
                  style: _tt.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),

              ],
            );
          },
        ),
      ),
    );
  }

  Widget _row(String label, String value) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [

          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}