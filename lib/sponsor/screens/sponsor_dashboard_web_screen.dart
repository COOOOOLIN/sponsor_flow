import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/sponsor_access_provider.dart';
import '../providers/sponsor_dashboard_provider.dart';
import '../screens/sponsor_profile_edit_screen.dart';
import 'sponsor_billing_contract_screen.dart';
import '../widgets/sponsor_ad_preview_card.dart';
import '../screens/sponsor_location_radius_screen.dart';
// import '../providers/sponsor_activity_breakdown_provider.dart';
import 'package:go_router/go_router.dart';

String formatDate(DateTime? date) {
  if (date == null) return '—';

  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  return "${date.day} ${months[date.month - 1]} ${date.year}";
}

class SponsorDashboardScreen extends ConsumerWidget {

  final String? activityFilterId;
  final String? activityFilterName;

  const SponsorDashboardScreen({
    super.key,
    this.activityFilterId,
    this.activityFilterName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(sponsorAccessProvider);

    return accessAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Sponsor dashboard')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Unable to load sponsor access.\n$e'),
          ),
        ),
      ),
      data: (access) {
        if (access == null) {
          return const _SponsorNoAccessScreen();
        }

        final dashAsync = ref.watch(
          sponsorDashboardProvider(activityFilterId),
        );

        // final activitiesAsync = FutureProvider.autoDispose((ref) async {
        //   final client = Supabase.instance.client;
        //
        //   return await client
        //       .from('sponsor_activity_profiles')
        //       .select('activity_id, activity_name')
        //       .eq('sponsor_id', access.sponsorId);
        // });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Sponsor dashboard'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(sponsorDashboardProvider(activityFilterId));
                },
              ),
            ],
          ),
          body: SafeArea(
            child: dashAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Unable to load dashboard.\n$e'),
              ),
              data: (summary) {
                if (summary == null) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: _EmptyStateCard(
                      title: 'No contract found',
                      body:
                      'You are linked to a sponsor, but there is no active, trial, or awaiting contract yet.',
                    ),
                  );
                }

                final status = summary.contractStatus;

                if (status == 'active') {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    final client = Supabase.instance.client;

                    final profile = await client
                        .from('sponsor_activity_profiles')
                        .select('sponsor_id')
                        .eq('sponsor_id', summary.sponsorId)
                        .limit(1)
                        .maybeSingle();

                    if (profile == null && context.mounted) {
                      context.go('/sponsor-profile-edit?sponsorId=${summary.sponsorId}');
                    }
                  });
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    _DashboardHero(
                      status: status,
                      tierName: summary.tierName ?? 'Sponsor',
                      isOwner: access.isOwner,
                      priceLocked: summary.priceLocked,
                      contractEnd: summary.contractEnd,
                      nextBillingDate: summary.nextBillingDate,
                    ),

                    const SizedBox(height: 18),

                    if (activityFilterName != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sports),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Viewing analytics for $activityFilterName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],



                    const _SectionTitle(
                      title: 'Overview',
                      subtitle: 'A snapshot of your sponsorship performance.',
                    ),
                    const SizedBox(height: 12),

                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.70,
                      children: [

                        _KpiCard(
                          label: 'Users reached',
                          value: summary.uniqueUsers.toString(),
                          icon: Icons.people_alt_outlined,
                          helper:
                          'Number of unique people who saw your sponsorship at least once.',
                        ),

                        _KpiCard(
                          label: 'Impressions',
                          value: summary.totalImpressions.toString(),
                          icon: Icons.visibility_outlined,
                          helper:
                          'Total number of times your sponsorship appeared across the app.',
                        ),

                        _KpiCard(
                          label: 'Clicks',
                          value: summary.totalClicks.toString(),
                          icon: Icons.ads_click_outlined,
                          helper:
                          'How many times users tapped your promotion to view your business.',
                        ),

                        _KpiCard(
                          label: 'CTR',
                          value: '${summary.ctr}%',
                          icon: Icons.show_chart_outlined,
                          helper:
                          'Percentage of impressions that resulted in a tap.',
                          highlight: true,
                        ),

                      ],
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [

                          Row(
                            children: [
                              Icon(Icons.trending_up_outlined),
                              SizedBox(width: 10),
                              Text(
                                "Grow your activity",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 8),

                          Text(
                            "Sponsors who stay active longer reach significantly more players as the community grows.",
                            style: TextStyle(height: 1.35),
                          ),

                          SizedBox(height: 6),

                          Text(
                            "Consider extending your sponsorship to lock your price while the user base expands.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    const _SectionTitle(
                      title: 'Promotion health',
                      subtitle: 'Monitor boosts, delivery state, and plan readiness.',
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _InfoPanel(
                            icon: Icons.local_fire_department_outlined,
                            title: 'Boosts remaining',
                            value: summary.boostsRemaining.toString(),
                            subtitle: summary.boostsRemaining > 0
                                ? 'You can activate another boost'
                                : 'No boosts currently available',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoPanel(
                            icon: Icons.schedule_outlined,
                            title: 'Boost hours left',
                            value: summary.boostHoursRemaining.toString(),
                            subtitle: summary.boostHoursRemaining > 0
                                ? 'A boost is currently active'
                                : 'No active boost running',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    const SizedBox(height: 22),

                    const _SectionTitle(
                      title: 'Preview your advertising',
                      subtitle: 'See how your promotion appears to users inside the app.',
                    ),

                    const SizedBox(height: 12),

                    SponsorAdPreviewCard(
                      sponsorId: summary.sponsorId,
                    ),

                    const SizedBox(height: 22),

                    _ContractAnalyticsCard(
                      status: status,
                      tierName: summary.tierName ?? '—',
                      priceLocked: summary.priceLocked,
                      boostsRemaining: summary.boostsRemaining,
                      boostHoursRemaining: summary.boostHoursRemaining,
                    ),

                    const SizedBox(height: 22),

                    // Builder(
                    //   builder: (context) {
                    //
                    //     final activityStatsAsync =
                    //     ref.watch(sponsorActivityBreakdownProvider(summary.sponsorId));
                    //
                    //     return activityStatsAsync.when(
                    //       loading: () => const SizedBox(),
                    //       error: (_, __) => const SizedBox(),
                    //
                    //       data: (rows) {
                    //
                    //         if (rows.length <= 1) {
                    //           return const SizedBox();
                    //         }
                    //
                    //         return Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //
                    //             const _SectionTitle(
                    //               title: 'Activity analytics',
                    //               subtitle:
                    //               'Performance breakdown for each sponsored activity.',
                    //             ),
                    //
                    //             const SizedBox(height: 12),
                    //
                    //             Container(
                    //               padding: const EdgeInsets.all(18),
                    //               decoration: BoxDecoration(
                    //                 color: const Color(0xFFF8FAFC),
                    //                 borderRadius: BorderRadius.circular(24),
                    //                 border: Border.all(color: const Color(0xFFE2E8F0)),
                    //               ),
                    //               child: Column(
                    //                 children: rows.map((row) {
                    //
                    //                   final name =
                    //                   formatActivityName(row['activity_name'] ?? 'Activity');
                    //
                    //                   final impressions =
                    //                   (row['impressions'] ?? 0).toString();
                    //
                    //                   final clicks =
                    //                   (row['clicks'] ?? 0).toString();
                    //
                    //                   final ctr =
                    //                   (row['ctr_percent'] ?? 0).toString();
                    //
                    //                   return Container(
                    //                     margin: const EdgeInsets.only(bottom: 14),
                    //                     padding: const EdgeInsets.all(16),
                    //                     decoration: BoxDecoration(
                    //                       color: Colors.white,
                    //                       borderRadius: BorderRadius.circular(20),
                    //                       border: Border.all(color: const Color(0xFFE2E8F0)),
                    //                       boxShadow: const [
                    //                         BoxShadow(
                    //                           color: Color(0x08000000),
                    //                           blurRadius: 8,
                    //                           offset: Offset(0, 4),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     child: Column(
                    //                       crossAxisAlignment: CrossAxisAlignment.start,
                    //                       children: [
                    //
                    //                         /// Activity Title
                    //                         Row(
                    //                           children: [
                    //                             const Icon(Icons.sports_score_outlined, size: 20),
                    //                             const SizedBox(width: 8),
                    //                             Text(
                    //                               name,
                    //                               style: const TextStyle(
                    //                                 fontWeight: FontWeight.w800,
                    //                                 fontSize: 16,
                    //                               ),
                    //                             ),
                    //                           ],
                    //                         ),
                    //
                    //                         const SizedBox(height: 14),
                    //
                    //                         /// Stats Row
                    //                         Row(
                    //                           children: [
                    //
                    //                             Expanded(
                    //                               child: _MetricTile(
                    //                                 label: "Views",
                    //                                 value: impressions,
                    //                                 icon: Icons.visibility_outlined,
                    //                               ),
                    //                             ),
                    //
                    //                             Expanded(
                    //                               child: _MetricTile(
                    //                                 label: "Clicks",
                    //                                 value: clicks,
                    //                                 icon: Icons.ads_click_outlined,
                    //                               ),
                    //                             ),
                    //
                    //                             Expanded(
                    //                               child: _MetricTile(
                    //                                 label: "CTR",
                    //                                 value: "$ctr%",
                    //                                 icon: Icons.show_chart,
                    //                                 highlight: true,
                    //                               ),
                    //                             ),
                    //
                    //                           ],
                    //                         ),
                    //                       ],
                    //                     ),
                    //                   );
                    //
                    //                 }).toList(),
                    //               ),
                    //             ),
                    //
                    //             const SizedBox(height: 22),
                    //           ],
                    //         );
                    //       },
                    //     );
                    //   },
                    // ),

                    const SizedBox(height: 22),

                    if (access.isOwner)
                      _OwnerToolsCard(
                        status: status,
                        sponsorId: summary.sponsorId,
                      )
                    else
                      const _EmptyStateCard(
                        title: 'Staff access',
                        body:
                        'You can view performance and sponsorship status here, but billing and management actions are limited to the sponsor owner.',
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SponsorNoAccessScreen extends StatelessWidget {
  const _SponsorNoAccessScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sponsor dashboard')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: _EmptyStateCard(
            title: 'Not a sponsor yet',
            body:
            'This dashboard is available for venue owners and instructors who are set up as sponsors.',
          ),
        ),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final String status;
  final String tierName;
  final bool isOwner;
  final num? priceLocked;
  final DateTime? contractEnd;
  final DateTime? nextBillingDate;

  const _DashboardHero({
    required this.status,
    required this.tierName,
    required this.isOwner,
    required this.priceLocked,
    required this.contractEnd,
    required this.nextBillingDate,
  });



  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    int? daysRemaining;
    double progress = 0;

    if (contractEnd != null) {
      daysRemaining = contractEnd!.difference(now).inDays;

      final start = contractEnd!.subtract(
        Duration(days: _estimateContractLength(contractEnd!, now)),
      );

      final total = contractEnd!.difference(start).inDays;
      final elapsed = now.difference(start).inDays;

      progress = (elapsed / total).clamp(0, 1);
    }

    final expired =
        contractEnd != null && contractEnd!.isBefore(now);

    final endingSoon =
        contractEnd != null &&
            !expired &&
            contractEnd!.difference(now).inDays <= 14;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFDCE7F4),
            Color(0xFFF4F7FB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD6DEE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: const [
              _CircleIcon(
                icon: Icons.verified_outlined,
                radius: 20,
                size: 20,
                background: Color(0xFFDBEAFE),
                foreground: Color(0xFF2563EB),
              ),
              SizedBox(width: 10),
              Text(
                "Active sponsorship",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            expired
                ? "Your sponsorship has ended. Renew to continue appearing to users."
                : endingSoon
                ? "Your sponsorship ends soon. Renew now to keep appearing without interruption."
                : "Your sponsorship is active and currently being delivered to users.",
            style: const TextStyle(
              color: Colors.black54,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 18),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [

              _InfoChip(
                Icons.workspace_premium_outlined,
                tierName,
              ),

              if (priceLocked != null)
                _InfoChip(
                  Icons.payments_outlined,
                  "Locked price: \$${priceLocked!.toStringAsFixed(0)}",
                ),

              _InfoChip(
                Icons.admin_panel_settings_outlined,
                isOwner ? "Owner access" : "Staff access",
              ),

              if (contractEnd != null)
                _InfoChip(
                  Icons.calendar_today_outlined,
                  "Contract ends ${_formatDate(contractEnd!)}",
                ),
            ],
          ),

          const SizedBox(height: 18),

          if (expired)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Restart sponsorship"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  context.go('/sponsor-billing-contract');
                },
              ),
            )

          else if (endingSoon)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoChip(
                  Icons.schedule_outlined,
                  "Contract ends ${_formatDate(contractEnd!)}",
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.autorenew),
                    label: const Text("Extend sponsorship"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      context.go('/sponsor-billing-contract');
                    },
                  ),
                ),
              ],
            )

          else if (nextBillingDate != null &&
                contractEnd != null &&
                !nextBillingDate!.isAtSameMomentAs(contractEnd!))
              _InfoChip(
                Icons.autorenew_outlined,
                "Renews on ${_formatDate(nextBillingDate!)}",
              ),

          const SizedBox(height: 22),

          if (contractEnd != null) ...[

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Contract progress",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (daysRemaining != null)
                  Text(
                    "$daysRemaining days remaining",
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static int _estimateContractLength(DateTime end, DateTime now) {
    final diff = end.difference(now).inDays;

    if (diff > 300) return 365;
    if (diff > 150) return 180;
    if (diff > 60) return 90;
    return 30;
  }

  static String _formatDate(DateTime d) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];

    return "${d.day} ${months[d.month - 1]} ${d.year}";
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String helper;
  final bool highlight;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.helper,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? accent.withOpacity(0.06) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlight
              ? accent.withOpacity(0.22)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          _CircleIcon(
            icon: icon,
            background:
            highlight ? accent.withOpacity(0.12) : const Color(0xFFFFFFFF),
            foreground: highlight ? accent : Colors.grey.shade800,
            size: 18,
            radius: 18,
          ),

          const SizedBox(height: 14),

          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Expanded(
            child: Text(
              helper,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CircleIcon(
            icon: icon,
            background: Colors.white,
            foreground: Colors.grey.shade800,
            size: 18,
            radius: 18,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractAnalyticsCard extends StatelessWidget {
  final String status;
  final String tierName;
  final num? priceLocked;
  final int boostsRemaining;
  final int boostHoursRemaining;

  const _ContractAnalyticsCard({
    required this.status,
    required this.tierName,
    required this.priceLocked,
    required this.boostsRemaining,
    required this.boostHoursRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final price =
    priceLocked == null ? '—' : '\$${priceLocked!.toString()}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan analytics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A clearer view of your current sponsorship contract and delivery state.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          _AnalyticsRow(label: 'Status', value: _readableStatus(status)),
          const Divider(height: 22),
          _AnalyticsRow(label: 'Tier', value: tierName),
          const Divider(height: 22),
          _AnalyticsRow(label: 'Locked price', value: price),
          const Divider(height: 22),
          _AnalyticsRow(
            label: 'Boost inventory',
            value: '$boostsRemaining remaining',
          ),
          const Divider(height: 22),
          _AnalyticsRow(
            label: 'Boost runtime',
            value: boostHoursRemaining > 0
                ? '$boostHoursRemaining hours left'
                : 'No active boost',
          ),
        ],
      ),
    );
  }
}


String formatActivityName(String raw) {
  final cleaned = raw.replaceAll('_', ' ');
  return cleaned
      .split(' ')
      .map((w) =>
  w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}


class _ActivityAnalyticsPanel extends StatelessWidget {
  final List<dynamic> activities;

  const _ActivityAnalyticsPanel({
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {

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
            'Activity analytics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Tap an activity to view its performance.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: activities.map((activity) {

              final map = activity as Map<String, dynamic>;

              final rawName =
                  map['activities']?['name'] ?? 'activity';

              final name = formatActivityName(rawName);

              final activityId = map['activity_id']?.toString();

              return OutlinedButton.icon(
                icon: const Icon(Icons.analytics_outlined),
                label: Text(name),
                onPressed: () {

                  context.go(
                    '/sponsor-dashboard?activityId=$activityId&activityName=${Uri.encodeComponent(name)}',
                  );

                },
              );

            }).toList(),
          ),

        ],
      ),
    );
  }
}


class _OwnerToolsCard extends ConsumerWidget {
  final String status;
  final String sponsorId;

  const _OwnerToolsCard({
    required this.status,
    required this.sponsorId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsAction = status == 'awaiting_activation' ||
        status == 'pending_conversion' ||
        status == 'payment_failed';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: needsAction ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: needsAction
              ? const Color(0xFFFED7AA)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            needsAction ? 'Action required' : 'Owner tools',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            needsAction
                ? 'Your sponsorship is not currently eligible for injection. Resolve this to resume promotion.'
                : 'Manage your business profile, sponsorship presence, and contract settings from one place.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),

          _OwnerActionButton(
            icon: Icons.edit_outlined,
            title: 'Edit business profile',
            subtitle: 'Update your public sponsor details, website, and contact links.',
            onTap: () {
              context.go('/sponsor-profile-edit?sponsorId=$sponsorId');
            },
          ),

          const SizedBox(height: 10),

          _OwnerActionButton(
            icon: Icons.location_on_outlined,
            title: 'Location & sponsorship radius',
            subtitle: 'Update where your sponsorship appears and how far it reaches.',
            onTap: () {
              context.go('/sponsor-location-radius?sponsorId=$sponsorId');
            },
          ),

          const SizedBox(height: 10),

          _OwnerActionButton(
            icon: Icons.local_fire_department_outlined,
            title: 'Manage boosts',
            subtitle: 'Boost activation controls can be connected here next.',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Boost controls coming next.'),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          _OwnerActionButton(
            icon: Icons.receipt_long_outlined,
            title: 'Billing and contract',
            subtitle: 'View billing status, renewal state, and contract actions.',
            onTap: () {
              context.go('/sponsor-billing-contract');
            },
          ),
          if (needsAction) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.flash_on_outlined),
                label: const Text('Activate or fix sponsorship'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stripe activation flow coming next.'),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OwnerActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OwnerActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              _CircleIcon(
                icon: icon,
                background: const Color(0xFFF8FAFC),
                foreground: Colors.black87,
                size: 18,
                radius: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {

    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      children: [

        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: highlight
                ? accent.withOpacity(0.12)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: highlight ? accent : Colors.grey.shade800,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  final String label;
  final String value;

  const _AnalyticsRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final double radius;
  final double size;

  const _CircleIcon({
    required this.icon,
    required this.background,
    required this.foreground,
    this.radius = 20,
    this.size = 20,
  });



  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
      ),
      child: Icon(icon, color: foreground, size: size),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip(
      this.icon,
      this.text, {
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String body;

  const _EmptyStateCard({
    required this.title,
    required this.body,
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade800,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusConfig {
  final IconData icon;
  final String title;
  final String body;
  final Color background;
  final Color border;
  final Color shadow;
  final Color iconBg;
  final Color iconFg;

  const _StatusConfig({
    required this.icon,
    required this.title,
    required this.body,
    required this.background,
    required this.border,
    required this.shadow,
    required this.iconBg,
    required this.iconFg,
  });
}

_StatusConfig _statusConfig(
    String status,
    bool isOwner,
    ColorScheme cs,
    ) {
  switch (status) {
    case 'active':
      return _StatusConfig(
        icon: Icons.verified_outlined,
        title: 'Active sponsorship',
        body: 'Your sponsorship is active and currently eligible for delivery.',
        background: cs.primary.withOpacity(0.08),
        border: cs.primary.withOpacity(0.18),
        shadow: cs.primary.withOpacity(0.10),
        iconBg: cs.primary.withOpacity(0.14),
        iconFg: cs.primary,
      );

    case 'trial':
      return const _StatusConfig(
        icon: Icons.timer_outlined,
        title: 'Trial period',
        body: 'You are currently in a sponsorship trial period.',
        background: Color(0xFFFFFBEB),
        border: Color(0xFFFDE68A),
        shadow: Color(0x14F59E0B),
        iconBg: Color(0xFFFFF3C4),
        iconFg: Color(0xFFB45309),
      );

    case 'awaiting_activation':
      return _StatusConfig(
        icon: Icons.lock_outline,
        title: 'Awaiting activation',
        body: isOwner
            ? 'Your founding period has ended. Activate a paid plan to continue being promoted.'
            : 'This sponsor needs owner activation to continue.',
        background: const Color(0xFFFFF7ED),
        border: const Color(0xFFFED7AA),
        shadow: const Color(0x14EA580C),
        iconBg: const Color(0xFFFFEDD5),
        iconFg: const Color(0xFFC2410C),
      );

    case 'payment_failed':
      return _StatusConfig(
        icon: Icons.error_outline,
        title: 'Payment failed',
        body: isOwner
            ? 'Billing failed. Update payment details to restore promotion.'
            : 'Billing failed. Owner action required.',
        background: const Color(0xFFFEF2F2),
        border: const Color(0xFFFECACA),
        shadow: const Color(0x14DC2626),
        iconBg: const Color(0xFFFEE2E2),
        iconFg: const Color(0xFFDC2626),
      );

    case 'pending_conversion':
      return _StatusConfig(
        icon: Icons.hourglass_bottom,
        title: 'Pending conversion',
        body: isOwner
            ? 'Your trial has ended. Convert to a paid plan to resume promotion.'
            : 'Owner action required to convert this sponsorship.',
        background: const Color(0xFFFFF7ED),
        border: const Color(0xFFFED7AA),
        shadow: const Color(0x14EA580C),
        iconBg: const Color(0xFFFFEDD5),
        iconFg: const Color(0xFFC2410C),
      );

    default:
      return const _StatusConfig(
        icon: Icons.info_outline,
        title: 'Status unavailable',
        body: 'Current sponsorship status information is unavailable.',
        background: Color(0xFFF8FAFC),
        border: Color(0xFFE2E8F0),
        shadow: Color(0x14000000),
        iconBg: Color(0xFFFFFFFF),
        iconFg: Colors.black87,
      );
  }
}

String _readableStatus(String status) {
  switch (status) {
    case 'active':
      return 'Active';
    case 'trial':
      return 'Trial';
    case 'awaiting_activation':
      return 'Awaiting activation';
    case 'payment_failed':
      return 'Payment failed';
    case 'pending_conversion':
      return 'Pending conversion';
    default:
      return status.isEmpty ? 'Unknown' : status;
  }
}