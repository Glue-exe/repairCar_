class OrderDetailTechniciansModel {
  int otId;
  String otAssignedAt;
  int accId;
  String accUsername;
  int empId;
  String tName;
  String empFirstName;
  String empLastName;
  String empPhone;
  int arId;
  String arName;

  OrderDetailTechniciansModel({
    required this.otId,
    required this.otAssignedAt,
    required this.accId,
    required this.accUsername,
    required this.empId,
    required this.tName,
    required this.empFirstName,
    required this.empLastName,
    required this.empPhone,
    required this.arId,
    required this.arName,
  });

  factory OrderDetailTechniciansModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailTechniciansModel(
      otId: json['ot_id'] as int,
      otAssignedAt: json['ot_assigned_at'] as String? ?? '',
      accId: json['acc_id'] as int,
      accUsername: json['acc_username'] as String,
      empId: json['emp_id'] as int,
      tName: json['t_name'] as String? ?? '',
      empFirstName: json['emp_first_name'] as String,
      empLastName: json['emp_last_name'] as String,
      empPhone: json['emp_phone'] as String? ?? '',
      arId: json['ar_id'] as int,
      arName: json['ar_name'] as String,
    );
  }
}

class OrderDetailTechniciansResponse {
  bool isError;
  List<OrderDetailTechniciansModel> data;
  String errorMessage;

  OrderDetailTechniciansResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory OrderDetailTechniciansResponse.fromJson(Map<String, dynamic> json) {
    return OrderDetailTechniciansResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map(
            (item) => OrderDetailTechniciansModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
