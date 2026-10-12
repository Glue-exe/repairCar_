

class OrderPoolMainModel {
  int oId;
  String? oSymptom;
  int oOrderStatusId;
  String osName;
  int oPriorityId;
  String pName;
  String vLicensePlate;
  int vbId;
  String vbName;
  int vVehicleModelId;
  String vmName;
  String? vColor;
  int? vYear;
  int idTitle;
  String tName;
  String cusFirstName;
  String cusLastName;
  String cusPhone;
  bool acceptByMe;

  OrderPoolMainModel({
    required this.oId,
    this.oSymptom,
    required this.oOrderStatusId,
    required this.osName,
    required this.oPriorityId,
    required this.pName,
    required this.vLicensePlate,
    required this.vbId,
    required this.vbName,
    required this.vVehicleModelId,
    required this.vmName,
    this.vColor,
    this.vYear,
    required this.idTitle,
    required this.tName,
    required this.cusFirstName,
    required this.cusLastName,
    required this.cusPhone,
    required this.acceptByMe,
  });

  factory OrderPoolMainModel.fromJson(Map<String, dynamic> json) {
    return OrderPoolMainModel(
      oId: json['o_id'] as int,
      oSymptom: json['o_symptom'] as String?,
      oOrderStatusId: json['o_order_status_id'] as int,
      osName: json['os_name'] as String,
      oPriorityId: json['o_priority_id'] as int,
      pName: json['p_name'] as String,
      vLicensePlate: json['v_license_plate'] as String,
      vbId: json['vb_id'] as int,
      vbName: json['vb_name'] as String,
      vVehicleModelId: json['v_vehicle_model_id'] as int,
      vmName: json['vm_name'] as String,
      vColor: json['v_color'] as String?,
      vYear: json['v_year'] as int?,
      idTitle: json['t_id'] as int,
      tName: json['t_name'] as String,
      cusFirstName: json['cus_first_name'] as String,
      cusLastName: json['cus_last_name'] as String,
      cusPhone: json['cus_phone'] as String,
      acceptByMe: json['accept_by_me'] as bool,
    );
  }
}

class OrderPoolMainResponse {
  bool isError;
  List<OrderPoolMainModel> data;
  String errorMessage;

  OrderPoolMainResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory OrderPoolMainResponse.fromJson(Map<String, dynamic> json) {
    return OrderPoolMainResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) =>
              OrderPoolMainModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
