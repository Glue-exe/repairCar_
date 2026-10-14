// Dashboard
class OwnerDashboardModel {
  String range;
  double income;
  int vehiclesInRange;
  int pendingRepairs;
  int activeRepairs;
  int awaitingPickup;
  int pendingPartApprovals;
  double laborTotal;
  double partsTotal;

  OwnerDashboardModel({
    required this.range,
    required this.income,
    required this.vehiclesInRange,
    required this.pendingRepairs,
    required this.activeRepairs,
    required this.awaitingPickup,
    required this.pendingPartApprovals,
    required this.laborTotal,
    required this.partsTotal,
  });

  factory OwnerDashboardModel.fromJson(Map<String, dynamic> json) {
    return OwnerDashboardModel(
      range: json['range'] as String,
      income: (json['income'] as num).toDouble(),
      vehiclesInRange: json['vehiclesInRange'] as int,
      pendingRepairs: json['pendingRepairs'] as int,
      activeRepairs: json['activeRepairs'] as int,
      awaitingPickup: json['awaitingPickup'] as int,
      pendingPartApprovals: json['pendingPartApprovals'] as int,
      laborTotal: (json['laborTotal'] as num).toDouble(),
      partsTotal: (json['partsTotal'] as num).toDouble(),
    );
  }

  // กำไรสุทธิของช่วงที่เลือก = รายได้ − ค่าอะไหล่ (เท่ากับค่าแรง)
  double get profit => income - partsTotal;
}
