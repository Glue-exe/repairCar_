class OrderImageModel {
  final int id;
  final String url;

  OrderImageModel({required this.id, required this.url});

  factory OrderImageModel.fromJson(Map<String, dynamic> json) {
    return OrderImageModel(
      id: json['oi_id'] as int,
      url: json['oi_image_url'] as String,
    );
  }
}
