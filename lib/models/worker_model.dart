// نموذج حركة السلف أو الدفعات المالية للعامل
class WorkerTransaction {
  final String id;
  final double amount;        // المبلغ بالدولار المحول
  final double originalAmount;// المبلغ بالعملة المدخلة
  final String currency;      // العملة ('USD' أو 'SYP')
  final DateTime date;        // التاريخ الحقيقي للدفعة
  final String note;          // ملاحظة

  WorkerTransaction({
    required this.id,
    required this.amount,
    required this.originalAmount,
    required this.currency,
    required this.date,
    this.note = '',
  });
}

// نموذج بيانات العامل الأساسية
class WorkerModel {
  final String id;
  final String name;          // اسم العامل
  final String phone;         // رقم الهاتف
  final double dailyRate;     // الأجر اليومي بالدولار
  final List<WorkerTransaction> transactions; // سجل السلف والدفعات

  WorkerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.dailyRate,
    List<WorkerTransaction>? transactions,
  }) : transactions = transactions ?? [];

  // إجمالي السلف والدفعات المسحوبة من قبل العامل
  double get totalAdvances {
    return transactions.fold(0.0, (sum, t) => sum + t.amount);
  }
}