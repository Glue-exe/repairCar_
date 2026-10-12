// สถานะของใบเบิกอะไหล่ (ตาราง req_part_status)
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

// รหัสสถานะที่ระบบอ้างอิงเชิงพฤติกรรม (ชื่อจริงดึงจาก /req_part_status ทุกครั้งที่แสดงผล)
// ตรงกับตาราง req_part_status ใน create_table_v2.sql
class ReqPartStatusId {
  static const int pending = 1;
  static const int approved = 2;
  static const int rejected = 3;
}
