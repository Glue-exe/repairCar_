class RequestPartModel {
  int id;
  int subTaskId;
  int statusId;
  String statusName;
  int requestedByAccountId;
  String requesterName;
  String requestedAt;
  int partId;
  String partName;
  double partPrice;
  String partBrand;
  int quantity;
  bool canCancel;
  String? cancelledAt;
  String? cancelledByName;

  RequestPartModel({
    required this.id,
    required this.subTaskId,
    required this.statusId,
    required this.statusName,
    required this.requestedByAccountId,
    required this.requesterName,
    required this.requestedAt,
    required this.partId,
    required this.partName,
    required this.partPrice,
    required this.partBrand,
    required this.quantity,
    required this.canCancel,
    this.cancelledAt,
    this.cancelledByName,
  });

  factory RequestPartModel.fromJson(Map<String, dynamic> json) {
    return RequestPartModel(
      id: json['id'] as int,
      subTaskId: json['sub_task_id'] as int,
      statusId: json['status_id'] as int,
      statusName: json['status_name'] as String,
      requestedByAccountId: json['requested_by_account_id'] as int,
      requesterName: json['requester_name'] as String? ?? '',
      requestedAt: json['requested_at'].toString(),
      partId: json['part_id'] as int,
      partName: json['part_name'] as String,
      partPrice: double.tryParse(json['part_price']?.toString() ?? '') ?? 0,
      partBrand: json['part_brand'] as String? ?? '',
      quantity: json['quantity'] as int,
      canCancel: json['can_cancel'] as bool,
      cancelledAt: json['cancelled_at'] as String?,
      cancelledByName: json['cancelled_by_name'] as String?,
    );
  }

  double get totalPrice => partPrice * quantity;
}

class RequestPartResponse {
  bool isError;
  List<RequestPartModel> data;
  String errorMessage;

  RequestPartResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory RequestPartResponse.fromJson(Map<String, dynamic> json) {
    return RequestPartResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map(
            (item) => RequestPartModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
