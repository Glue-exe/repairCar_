class PartModel {
  int id;
  String partCode;
  String name;
  double partPrice;
  String unit;
  bool partIsActive;
  int category;
  int brand;
  String? url;
  String? partBrandName;
  String? partCategoryName;
  int? vehModelId;
  String? modelName;
  String? vehicleBrandName;
  int? yearFrom;
  int? yearTo;
  List<CompatibleVehicleModel> compatibleModels;

  PartModel({
    required this.id,
    required this.partCode,
    required this.name,
    required this.partPrice,
    required this.unit,
    required this.partIsActive,
    required this.category,
    required this.brand,
    this.url,
    this.partBrandName,
    this.partCategoryName,
    this.vehModelId,
    this.modelName,
    this.vehicleBrandName,
    this.yearFrom,
    this.yearTo,
    this.compatibleModels = const [],
  });

  /// Backwards-compatible getter and setter for legacy references to `price`
  double get price => partPrice;
  set price(double val) => partPrice = val;

  factory PartModel.fromJson(Map<String, dynamic> json) {
    List<CompatibleVehicleModel> compatList = [];
    if (json['compatible_models'] != null && json['compatible_models'] is List) {
      for (var item in json['compatible_models'] as List) {
        compatList.add(CompatibleVehicleModel.fromJson(item as Map<String, dynamic>));
      }
    }

    return PartModel(
      id: json['part_id'] as int,
      partCode: json['part_code'] as String,
      name: json['part_name'] as String,
      partPrice: double.parse(json['part_price'].toString()),
      unit: json['unit'] as String,
      partIsActive: json['part_is_active'] as bool,
      category: json['part_category_id'] as int,
      brand: json['part_brand_id'] as int,
      url: json['part_url'] as String?,
      partBrandName: json['pb_name'] as String?,
      partCategoryName: json['pc_name'] as String?,
      vehModelId: json['vpc_vehicle_model_id'] as int?,
      modelName: json['vm_name'] as String?,
      vehicleBrandName: json['vb_name'] as String?,
      yearFrom: json['vpc_year_from'] as int?,
      yearTo: json['vpc_year_to'] as int?,
      compatibleModels: compatList,
    );
  }

  // สรุปรายชื่อรุ่นรถและช่วงปี ค.ศ. ที่รองรับทั้งหมดเป็นข้อความ String เดียว
  // ใช้แสดงผลบน UI และใช้สำหรับระบบค้นหา (Search) ตามชื่อรุ่นรถหรือช่วงปี ค.ศ.
  String get compatibleModelsSummary {
    if (compatibleModels.isNotEmpty == true) {
      List<String> list = [];
      for (var m in compatibleModels) {
        list.add(m.displayText);
      }
      return list.join(', ');
    } else {
      return '';
    }
  }
}

class CompatibleVehicleModel {
  int modelId;
  String modelName;
  String brandName;
  int? yearFrom;
  int? yearTo;

  CompatibleVehicleModel({
    required this.modelId,
    required this.modelName,
    required this.brandName,
    this.yearFrom,
    this.yearTo,
  });

  factory CompatibleVehicleModel.fromJson(Map<String, dynamic> json) {
    final rawModelId = json['vm_id'] ?? json['model_id'];
    int id;
    if (rawModelId is int) {
      id = rawModelId;
    } else {
      id = int.tryParse(rawModelId?.toString() ?? '0') ?? 0;
    }

    return CompatibleVehicleModel(
      modelId: id,
      modelName: (json['vm_name'] ?? json['model_name'] as String?)?.toString() ?? '',
      brandName: (json['vb_name'] ?? json['brand_name'] as String?)?.toString() ?? '',
      yearFrom: json['vpc_year_from'] is int
          ? json['vpc_year_from'] as int
          : (json['year_from'] as int?),
      yearTo: json['vpc_year_to'] is int
          ? json['vpc_year_to'] as int
          : (json['year_to'] as int?),
    );
  }

  String get displayText {
    String name = '';
    if (brandName.isNotEmpty == true) {
      name = '$brandName $modelName';
    } else {
      name = modelName;
    }

    String yearText = '';
    if (yearFrom != null && yearTo != null) {
      if (yearFrom == yearTo) {
        yearText = ' ($yearFrom)';
      } else {
        yearText = ' ($yearFrom - $yearTo)';
      }
    } else if (yearFrom != null) {
      yearText = ' ($yearFrom - ปัจจุบัน)';
    } else if (yearTo != null) {
      yearText = ' (ถึง $yearTo)';
    } else {
      yearText = '';
    }

    return '$name$yearText';
  }

  String get displayName =>
      brandName.isNotEmpty ? '$brandName - $modelName' : modelName;

  String get yearRangeText {
    if (yearFrom != null && yearTo != null) {
      if (yearFrom == yearTo) return '$yearFrom';
      return '$yearFrom - $yearTo';
    } else if (yearFrom != null) {
      return '$yearFrom - ปัจจุบัน';
    } else if (yearTo != null) {
      return 'ถึง $yearTo';
    }
    return 'ทุกปีที่ผลิต';
  }

  bool get isYearRangeInvalid =>
      yearFrom != null && yearTo != null && yearTo! < yearFrom!;
}

class SelectedVehicleModel extends CompatibleVehicleModel {
  SelectedVehicleModel({
    required super.modelId,
    required super.modelName,
    required super.brandName,
    super.yearFrom,
    super.yearTo,
  });

  factory SelectedVehicleModel.fromCompatible(CompatibleVehicleModel compat) {
    return SelectedVehicleModel(
      modelId: compat.modelId,
      modelName: compat.modelName,
      brandName: compat.brandName,
      yearFrom: compat.yearFrom,
      yearTo: compat.yearTo,
    );
  }

  SelectedVehicleModel enriched(List<Map<String, dynamic>> vehicleModels) {
    if (modelName.isNotEmpty && brandName.isNotEmpty) {
      return this;
    }
    for (var vm in vehicleModels) {
      if (vm['vm_id'] == modelId) {
        return SelectedVehicleModel(
          modelId: modelId,
          modelName: modelName.isNotEmpty ? modelName : (vm['vm_name'] ?? '').toString(),
          brandName: brandName.isNotEmpty ? brandName : (vm['vb_name'] ?? '').toString(),
          yearFrom: yearFrom,
          yearTo: yearTo,
        );
      }
    }
    return this;
  }

  Map<String, dynamic> toJson() {
    return {
      'model_id': modelId,
      'vpc_year_from': yearFrom,
      'vpc_year_to': yearTo,
    };
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
