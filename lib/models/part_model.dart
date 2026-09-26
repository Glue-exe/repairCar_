class PartModel {
  int id;
  String name;
  double price;
  int category;
  int brand;
  String? url;
  int? vehModelId;
  String? modelName;
  String? vehicleBrandName;
  String? partBrandName;
  String? partCategoryName;

  PartModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.brand,
    this.url,
    this.vehModelId,
    this.modelName,
    this.vehicleBrandName,
    this.partBrandName,
    this.partCategoryName,
  });

  factory PartModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    return PartModel(
      id: json['part_id'] as int,
      name: json['part_name'] as String,
      price: double.parse(json['part_price'].toString()),
      category: parseId(json['part_category_id'] ?? json['pc_id']),
      brand: parseId(json['part_brand_id'] ?? json['pb_id']),
      url: json['part_url'] as String?,
      vehModelId: json['veh_model_id'] != null
          ? int.tryParse(json['veh_model_id'].toString())
          : null,
      modelName: json['model_name'] as String?,
      vehicleBrandName: json['vehicle_brand_name'] as String?,
      partBrandName: json['part_brand_name'] as String?,
      partCategoryName: json['part_category_name'] as String?,
    );
  }
}

class PartResponse {
  bool isError;
  List<PartModel> data;
  String errorMessage;

  PartResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory PartResponse.fromJson(Map<String, dynamic> json) {
    return PartResponse(
      isError: json['isError'] as bool,
      data: (json['data'] as List)
          .map((item) => PartModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String,
    );
  }
}
