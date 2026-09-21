class PhoneSearchResultModel {
  final int cusId;
  final int vId;
  final String fullName;
  final String cusPhone;
  final String vLicensePlate;
  final int vYear;
  final String vColor;
  final String vmName;
  final String vbName;

  PhoneSearchResultModel({
    required this.cusId,
    required this.vId,
    required this.fullName,
    required this.cusPhone,
    required this.vLicensePlate,
    required this.vYear,
    required this.vColor,
    required this.vmName,
    required this.vbName,
  });

  factory PhoneSearchResultModel.fromJson(Map<String, dynamic> json) {
    return PhoneSearchResultModel(
      cusId: json['cus_id'] as int? ?? 0,
      vId: json['v_id'] as int,
      fullName: json['fullname'] as String,
      cusPhone: json['cus_phone'] as String,
      vLicensePlate: json['v_license_plate'] as String,
      vYear: json['v_year'] as int,
      vColor: json['v_color'] as String,
      vmName: json['vm_name'] as String,
      vbName: json['vb_name'] as String,
    );
  }
}

class PhoneSearchResultResponse {
  bool isError;
  List<PhoneSearchResultModel> data;
  String errorMessage;

  PhoneSearchResultResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory PhoneSearchResultResponse.fromJson(Map<String, dynamic> json) {
    return PhoneSearchResultResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) =>
              PhoneSearchResultModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}