class SponsorDashboardSummary {
  final String sponsorId;
  final String contractStatus;
  final String? tierName;
  final num? priceLocked;

  final int boostsRemaining;
  final int boostHoursRemaining;

  final int uniqueUsers;
  final int totalImpressions;
  final int totalClicks;
  final num ctr;

  final DateTime? contractEnd;
  final DateTime? nextBillingDate;

  final List<ActivityAnalytics> activities;

  const SponsorDashboardSummary({
    required this.sponsorId,
    required this.contractStatus,
    required this.tierName,
    required this.priceLocked,
    required this.boostsRemaining,
    required this.boostHoursRemaining,
    required this.uniqueUsers,
    required this.totalImpressions,
    required this.totalClicks,
    required this.ctr,
    required this.activities,
    this.contractEnd,
    this.nextBillingDate,
  });

  factory SponsorDashboardSummary.fromJson(Map<String, dynamic> json) {

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    num _toNum(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v;
      return num.tryParse(v.toString()) ?? 0;
    }

    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    List<ActivityAnalytics> _parseActivities(dynamic raw) {
      if (raw == null) return [];

      if (raw is List) {
        return raw
            .map((e) => ActivityAnalytics.fromJson(e))
            .toList();
      }

      return [];
    }

    return SponsorDashboardSummary(
      sponsorId: json['sponsor_id'] as String,
      contractStatus: (json['contract_status'] ?? '') as String,
      tierName: json['tier_name'] as String?,
      priceLocked: json['price_locked'] as num?,
      boostsRemaining: _toInt(json['boosts_remaining']),
      boostHoursRemaining: _toInt(json['boost_hours_remaining']),
      uniqueUsers: _toInt(json['unique_users']),
      totalImpressions: _toInt(json['total_impressions']),
      totalClicks: _toInt(json['total_clicks']),
      ctr: _toNum(json['ctr']),
      contractEnd: _toDate(json['contract_end']),
      nextBillingDate: _toDate(json['next_billing_date']),
      activities: _parseActivities(json['activities']),
    );
  }
}

class ActivityAnalytics {
  final String activityName;
  final int impressions;
  final int clicks;
  final double ctr;

  const ActivityAnalytics({
    required this.activityName,
    required this.impressions,
    required this.clicks,
    required this.ctr,
  });

  factory ActivityAnalytics.fromJson(Map<String, dynamic> json) {

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double _toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return ActivityAnalytics(
      activityName: (json['activity_name'] ?? 'Activity').toString(),
      impressions: _toInt(json['impressions']),
      clicks: _toInt(json['clicks']),
      ctr: _toDouble(json['ctr']),
    );
  }
}