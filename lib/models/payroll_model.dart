class MonthlyPayrollResponse {
  final bool isError;
  final MonthlyPayrollData? data;
  final String errorMessage;

  MonthlyPayrollResponse({
    required this.isError,
    this.data,
    required this.errorMessage,
  });

  factory MonthlyPayrollResponse.fromJson(Map<String, dynamic> json) {
    return MonthlyPayrollResponse(
      isError: json['isError'] ?? false,
      data: json['data'] != null ? MonthlyPayrollData.fromJson(json['data']) : null,
      errorMessage: json['errorMessage'] ?? '',
    );
  }
}

class MonthlyPayrollData {
  final String month;
  final MonthlyPayrollSummary summary;
  final List<TechnicianPayrollItem> technicians;

  MonthlyPayrollData({
    required this.month,
    required this.summary,
    required this.technicians,
  });

  factory MonthlyPayrollData.fromJson(Map<String, dynamic> json) {
    return MonthlyPayrollData(
      month: json['month'] ?? '',
      summary: MonthlyPayrollSummary.fromJson(json['summary'] ?? {}),
      technicians: (json['technicians'] as List? ?? [])
          .map((item) => TechnicianPayrollItem.fromJson(item))
          .toList(),
    );
  }
}

class MonthlyPayrollSummary {
  final double totalPayout;
  final int paidCount;
  final double paidTotalAmount;
  final int pendingCount;
  final double pendingTotalAmount;
  final int totalTechnicians;

  MonthlyPayrollSummary({
    required this.totalPayout,
    required this.paidCount,
    required this.paidTotalAmount,
    required this.pendingCount,
    required this.pendingTotalAmount,
    required this.totalTechnicians,
  });

  factory MonthlyPayrollSummary.fromJson(Map<String, dynamic> json) {
    return MonthlyPayrollSummary(
      totalPayout: (json['total_payout'] ?? 0).toDouble(),
      paidCount: (json['paid_count'] ?? 0) as int,
      paidTotalAmount: (json['paid_total_amount'] ?? 0).toDouble(),
      pendingCount: (json['pending_count'] ?? 0) as int,
      pendingTotalAmount: (json['pending_total_amount'] ?? 0).toDouble(),
      totalTechnicians: (json['total_technicians'] ?? 0) as int,
    );
  }
}

class TechnicianPayrollItem {
  final int empId;
  final String firstName;
  final String lastName;
  final String fullName;
  final String phone;
  final double baseSalary;
  final int? roleId;
  final String roleName;
  final int? salaryHistoryId;
  final bool isPaid;
  final double paidAmount;
  final String? paidDate;
  final int? paymentMethodId;
  final String? paymentMethodName;
  final String? slipImageUrl;
  final String? paidAt;

  TechnicianPayrollItem({
    required this.empId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.phone,
    required this.baseSalary,
    this.roleId,
    required this.roleName,
    this.salaryHistoryId,
    required this.isPaid,
    required this.paidAmount,
    this.paidDate,
    this.paymentMethodId,
    this.paymentMethodName,
    this.slipImageUrl,
    this.paidAt,
  });

  factory TechnicianPayrollItem.fromJson(Map<String, dynamic> json) {
    return TechnicianPayrollItem(
      empId: json['emp_id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      baseSalary: (json['base_salary'] ?? 0).toDouble(),
      roleId: json['role_id'],
      roleName: json['role_name'] ?? 'ช่าง',
      salaryHistoryId: json['salary_history_id'],
      isPaid: json['is_paid'] ?? false,
      paidAmount: (json['paid_amount'] ?? json['base_salary'] ?? 0).toDouble(),
      paidDate: json['paid_date'],
      paymentMethodId: json['payment_method_id'],
      paymentMethodName: json['payment_method_name'],
      slipImageUrl: json['slip_image_url'],
      paidAt: json['paid_at'],
    );
  }
}
