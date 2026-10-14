class ReqPartStatusModel {
  int id;
  String name;

  ReqPartStatusModel({
    required this.id,
    required this.name,
  });

  factory ReqPartStatusModel.fromJson(Map<String, dynamic> json) {
    return ReqPartStatusModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class ReqPartStatusId {
  static const int pending = 1;
  static const int approved = 2;
  static const int rejected = 3;
  static const int cancelled = 4;
}
