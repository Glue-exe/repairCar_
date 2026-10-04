class AppConfig {
  static const String apiBaseUri = "http://10.0.2.2:3000/api";
  static const String imageBaseUri = "http://10.0.2.2:3000/images";

  /// แปลงชื่อไฟล์ภาพให้เป็น Full URL
  static String getImageUrl(String? fileName) {
    if (fileName == null || fileName.trim().isEmpty) return '';
    final trimmed = fileName.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final cleanName = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    return "$imageBaseUri/$cleanName";
  }
}
//"http://10.0.2.2:3000/api"
//"http://localhost:3000/api"
