class AppConfig {
  static const String apiBaseUri = "http://10.0.2.2:3000/api";
  static const String imageBaseUri = "http://10.0.2.2:3000/images";

  /// แปลงชื่อไฟล์ภาพให้เป็น Full URL
  /// รองรับ: ชื่อไฟล์เปล่า · "/images/..." · "/uploads/..." (ข้อมูลเก่า) · Full URL
  static String getImageUrl(String? fileName) {
    if (fileName == null || fileName.trim().isEmpty) return '';
    final trimmed = fileName.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // ตัด prefix ของ path ออกให้เหลือชื่อไฟล์ (Express เสิร์ฟที่ /images เท่านั้น)
    String cleanName = trimmed;
    if (cleanName.startsWith('/images/')) {
      cleanName = cleanName.substring('/images/'.length);
    } else if (cleanName.startsWith('/uploads/')) {
      cleanName = cleanName.substring('/uploads/'.length);
    } else if (cleanName.startsWith('/')) {
      cleanName = cleanName.substring(1);
    }

    return "$imageBaseUri/$cleanName";
  }
}
//"http://10.0.2.2:3000/api"
//"http://localhost:3000/api"
