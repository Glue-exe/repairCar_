import 'package:flutter/material.dart';

// โทนสีและขนาดตัวอักษรมาตรฐานของระบบ (App Design System Tokens)
// ออกแบบเพื่อใช้งานร่วมกันได้ทุกหน้าในระบบ (Owner, Technician, Accountant, Shared)

class AppColors {
  // สีหลักของระบบ (Brand & Layout Colors)
  static const Color primaryGreen = Color(0xFF588B5B);
  static const Color background = Color(0xFFF4F6F4);
  static const Color inputBackground = Color(0xFFEFF2EE);
  static const Color textDark = Color(0xFF2C322E);
  static const Color textMuted = Color(0xFF7A817C);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);

  // สีสถานะและความสำคัญ (Semantic & Status Colors)
  // อันตราย / ด่วนมาก / ยกเลิก / Error (Danger)
  static const Color danger = Color(0xFFC81E1E);
  static const Color dangerBg = Color(0xFFFDE8E8);
  static const Color dangerText = Color(0xFFC81E1E);

  // แจ้งเตือน / ด่วน / รอดำเนินการ / รอชำระเงิน (Warning / Pending)
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFDF6B2);
  static const Color warningText = Color(0xFF9F580A);

  // สำเร็จ / เสร็จสิ้น / อนุมัติ / ชำระแล้ว (Success / Completed)
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFDEF7EC);
  static const Color successText = Color(0xFF03543F);

  // ข้อมูล / กำลังซ่อม / กำลังดำเนินการ (Info / In Progress)
  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFE1EFFE);
  static const Color infoText = Color(0xFF1E429F);

  // ปิดใช้งาน / Disable (Disabled State)
  static const Color disabled = Color(0xFF9CA3AF);
  static const Color disabledBg = Color(0xFFF3F4F6);

  // ขนาดตัวอักษรมาตรฐานแบบขยายใหญ่ (Enlarged Font Sizes)
  static const double fontStat = 28.0; // ตัวเลขสถิติ Dashboard / ยอดเงินรวม
  static const double fontAppBar = 22.0; // หัวข้อหน้าจอ AppBar
  static const double fontHeadline = 20.0; // หัวข้อหลัก / ฟอร์ม / Modal
  static const double fontTitle = 19.0; // ชื่อการ์ด / ยี่ห้อ-รุ่นรถยนต์
  static const double fontSection =
      18.0; // หัวข้อหมวดหมู่ เช่น รายการงาน, รายการอะไหล่
  static const double fontSubtitle = 16.0; // ข้อความรองขนาดกลาง / คำแนะนำ
  static const double fontInput = 16.0; // ข้อความในช่องกรอกข้อมูล TextField
  static const double fontButton = 16.0; // ข้อความบนปุ่มกด Action Button
  static const double fontPlate = 16.0; // ป้ายทะเบียนรถยนต์
  static const double fontBody =
      15.0; // เนื้อหาทั่วไป / อาการเสีย / ข้อมูลลูกค้า / สี / ปี
  static const double fontTag = 14.0; // ป้ายรหัสงาน (#ID)
  static const double fontBadge = 13.0; // ป้ายสถานะงาน และ ระดับความสำคัญ
  static const double fontCaption =
      12.0; // ข้อความกำกับย่อย / วันที่-เวลา / หมายเหตุ

  // Global ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        secondary: primaryGreen,
        surface: inputBackground,
        onPrimary: Colors.white,
        onSurface: textDark,
        error: danger,
      ),
    );
  }
}

/// คลาสขนาดตัวอักษรสำหรับเรียกใช้งานตรงๆ (AppFontSizes)
class AppFontSizes {
  static const double stat = AppColors.fontStat;
  static const double appBar = AppColors.fontAppBar;
  static const double headline = AppColors.fontHeadline;
  static const double title = AppColors.fontTitle;
  static const double section = AppColors.fontSection;
  static const double subtitle = AppColors.fontSubtitle;
  static const double input = AppColors.fontInput;
  static const double button = AppColors.fontButton;
  static const double plate = AppColors.fontPlate;
  static const double body = AppColors.fontBody;
  static const double tag = AppColors.fontTag;
  static const double badge = AppColors.fontBadge;
  static const double caption = AppColors.fontCaption;
}

/// สไตล์ข้อความสำเร็จรูปสำหรับใช้ซ้ำทั่วทั้งแอป (AppTextStyles)
class AppTextStyles {
  // หัวข้อหน้าจอ (AppBar)
  static const TextStyle appBar = TextStyle(
    fontSize: AppFontSizes.appBar,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  // หัวข้อส่วน / หมวดหมู่ (Section Title)
  static const TextStyle sectionTitle = TextStyle(
    fontSize: AppFontSizes.section,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  // หัวข้อการ์ด / รายการ (Card Title)
  static const TextStyle cardTitle = TextStyle(
    fontSize: AppFontSizes.title,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  // ป้ายทะเบียนรถ (License Plate)
  static const TextStyle licensePlate = TextStyle(
    fontSize: AppFontSizes.plate,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    letterSpacing: 0.4,
  );

  // เนื้อหาทั่วไป (Body)
  static const TextStyle body = TextStyle(
    fontSize: AppFontSizes.body,
    color: AppColors.textDark,
    height: 1.4,
  );

  // เนื้อหาเน้น (Body Bold)
  static const TextStyle bodyBold = TextStyle(
    fontSize: AppFontSizes.body,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  // ข้อความสีเทา / รอง (Muted Body)
  static const TextStyle bodyMuted = TextStyle(
    fontSize: AppFontSizes.body,
    color: AppColors.textMuted,
  );

  // ข้อความบนปุ่มกด (Button)
  static const TextStyle button = TextStyle(
    fontSize: AppFontSizes.button,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // ตัวเลขสถิติ Dashboard / ยอดเงิน
  static const TextStyle statNumber = TextStyle(
    fontSize: AppFontSizes.stat,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  // คำอธิบายสถิติ Dashboard
  static const TextStyle statLabel = TextStyle(
    fontSize: AppFontSizes.body,
    color: AppColors.textMuted,
  );

  // ป้าย Badge / Chip
  static const TextStyle badge = TextStyle(
    fontSize: AppFontSizes.badge,
    fontWeight: FontWeight.bold,
  );

  // ข้อความกำกับย่อย / เวลา / หมายเหตุ (Caption)
  static const TextStyle caption = TextStyle(
    fontSize: AppFontSizes.caption,
    color: AppColors.textMuted,
  );
}
