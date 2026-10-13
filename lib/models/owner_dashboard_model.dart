class OwnerDashboardModel {
  String range;
  double income;
  double unpaidTotal;
  int vehiclesInRange;
  int activeRepairs;
  double laborTotal;
  double partsTotal;
  List<DashboardTrendItemModel> trend;

  OwnerDashboardModel({
    required this.range,
    required this.income,
    required this.unpaidTotal,
    required this.vehiclesInRange,
    required this.activeRepairs,
    required this.laborTotal,
    required this.partsTotal,
    required this.trend,
  });

  factory OwnerDashboardModel.fromJson(Map<String, dynamic> json) {
    return OwnerDashboardModel(
      range: json['range'] as String,
      income: (json['income'] as num).toDouble(),
      unpaidTotal: (json['unpaidTotal'] as num).toDouble(),
      vehiclesInRange: json['vehiclesInRange'] as int,
      activeRepairs: json['activeRepairs'] as int,
      laborTotal: (json['laborTotal'] as num).toDouble(),
      partsTotal: (json['partsTotal'] as num).toDouble(),
      trend: (json['trend'] as List)
          .map((item) => DashboardTrendItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

// แท่งกราฟแนวโน้ม — period: 'YYYY-MM' (ปี) หรือ 'YYYY-MM-DD' (ช่วงอื่น)
class DashboardTrendItemModel {
  String period;
  double total;

  DashboardTrendItemModel({
    required this.period,
    required this.total,
  });

  factory DashboardTrendItemModel.fromJson(Map<String, dynamic> json) {
    return DashboardTrendItemModel(
      period: json['period'] as String,
      total: (json['total'] as num).toDouble(),
    );
  }

  // ป้ายแกน X ย่อ: '01' หรือ '13/10'
  String get axisLabel {
    if (period.length == 7) {
      // '2026-01' → เลขเดือน: '01'
      return period.substring(5, 7);
    }
    // '2026-10-13' → '13/10'
    return '${period.substring(8, 10)}/${period.substring(5, 7)}';
  }
}
