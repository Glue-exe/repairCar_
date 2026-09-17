class AppovalPartModel {
  int id;
  int requestPartItemId;
  int? accountId;
  int approvalStatusId;
  String createdAt;
  int quantity;
  String partName;
  double partPrice;
  String partBrand;
  String? partUrl;
  int subTaskId;
  String subTaskName;
  int orderId;
  String licensePlate;
  String empFirstName;
  String empLastName;

  AppovalPartModel({
    required this.id,
    required this.requestPartItemId,
    this.accountId,
    required this.approvalStatusId,
    required this.createdAt,
    required this.quantity,
    required this.partName,
    required this.partPrice,
    required this.partBrand,
    this.partUrl,
    required this.subTaskId,
    required this.subTaskName,
    required this.orderId,
    required this.licensePlate,
    required this.empFirstName,
    required this.empLastName,
  });

  factory AppovalPartModel.fromJson(Map<String, dynamic> json) {
    return AppovalPartModel(
      id: json['app_p_id'] as int,
      requestPartItemId: json['app_p_request_part_item_id'] as int,
      accountId: json['app_p_account_id'] as int?,
      approvalStatusId: json['app_p_approval_status_id'] as int,
      createdAt: json['app_p_created_at'].toString(),
      quantity: json['rpi_quantity'] as int,
      partName: json['part_name'] as String,
      partPrice: double.parse(json['part_price'].toString()),
      partBrand: json['part_brand'] as String,
      partUrl: json['part_url'] as String?,
      subTaskId: json['st_id'] as int,
      subTaskName: json['sub_task_name'] as String,
      orderId: json['order_id'] as int,
      licensePlate: json['v_license_plate'] as String,
      empFirstName: json['emp_first_name'] as String,
      empLastName: json['emp_last_name'] as String,
    );
  }
}

class AppovalPartResponse {
  bool isError = false;
  List<AppovalPartModel> data = [];
  String errorMessage = "";

  AppovalPartResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory AppovalPartResponse.fromJson(Map<String, dynamic> json) {
    return AppovalPartResponse(
      isError: json['isError'],
      data: (json['data'] as List)
          .map((item) => AppovalPartModel.fromJson(item))
          .toList(),
      errorMessage: json['errorMessage']
    );
  }
}
