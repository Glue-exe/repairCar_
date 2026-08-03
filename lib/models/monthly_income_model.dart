class MonthlyIncomeModel {
  final String monthYear;
  final String month;
  final int year;
  final double totalAmount;

  MonthlyIncomeModel({
    required this.monthYear,
    required this.month,
    required this.year,
    required this.totalAmount,
  });

  factory MonthlyIncomeModel.fromJson(Map<String, dynamic> json) {
    // 1. หาค่า rawMonthYear
    String rawMonthYear = '';
    if (json['month_year'] != null) {
      rawMonthYear = json['month_year'].toString();
    } else if (json['month'] != null) {
      rawMonthYear = json['month'].toString();
    } else {
      rawMonthYear = '';
    }

    // 2. นำ rawMonthYear มาแบ่งด้วย - เช่น "2026-07" จะได้ List ["2026", "07"]
    List<String> parts = rawMonthYear.split('-');

    // 3. หาค่า parsedYear (แปลงเป็นตัวเลขจำนวนเต็ม)
    int parsedYear = 0;
    if (parts.isNotEmpty) {
      int? convertedYear = int.tryParse(parts[0]); // try ลองแปลงข้อความใน parts[0] ให้เป็น int
      if (convertedYear != null) {
        parsedYear = convertedYear;
      } else {
        parsedYear = 0;
      }
    } else {
      parsedYear = 0;
    }

    // 4. หาค่า parsedMonth
    String parsedMonth = '';
    if (parts.length > 1) {
      parsedMonth = parts[1];
    } else {
      parsedMonth = rawMonthYear;
    }

    // 5. หาค่ายอดเงินดิบ rawAmount
    dynamic rawAmount;
    if (json['total_amount'] != null) {
      rawAmount = json['total_amount'];
    } else if (json['totalAmount'] != null) {
      rawAmount = json['totalAmount'];
    } else {
      rawAmount = 0;
    }

    // 6. แปลงยอดเงินเป็น double 
    double parsedAmount = 0.0;
    if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else {
      double? convertedAmount = double.tryParse(rawAmount.toString());
      if (convertedAmount != null) {
        parsedAmount = convertedAmount;
      } else {
        parsedAmount = 0.0;
      }
    }

    // 7. คืนค่าเป็น Object MonthlyIncomeModel
    return MonthlyIncomeModel(
      monthYear: rawMonthYear,
      month: parsedMonth,
      year: parsedYear,
      totalAmount: parsedAmount,
    );
  }
}

class IncomeResponse {
  final bool isError;
  final List<MonthlyIncomeModel> data;
  final String errorMessage;

  IncomeResponse({
    required this.isError,
    required this.data,
    required this.errorMessage,
  });

  factory IncomeResponse.fromJson(Map<String, dynamic> json) {
    return IncomeResponse(
      isError: json['isError'] ?? false,
      
      // list เป็น null ได้ ถ้าข้อมูลเป็น null ให้ list [] ค่าว่าง
      data: (json['data'] as List? ?? [])
          .map(
            // loop ทีละตัวใน list แล้วเรียกใช้ MonthlyIncomeModel แปลงเป็น obj
            (item) => MonthlyIncomeModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(), // นำข้อมูลที่แปลงเป็น obj มาใส่ [] กลับเป็น data
          
      errorMessage: json['errorMessage'] ?? '',
    );
  }
}
