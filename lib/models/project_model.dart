// نموذج الدفعة المستلمة من العميل
class ProjectPayment {
  final String id;
  final double amount;      // مبلغ الدفعة بالدولار
  final DateTime date;      // تاريخ الدفعة الحقيقي
  final String note;        // ملاحظة على الدفعة

  ProjectPayment({
    required this.id,
    required this.amount,
    required this.date,
    this.note = '',
  });
}

// نموذج المشروع الرئيسي
class ProjectModel {
  final int? id;
  final String clientName;
  final String clientPhone;
  final String clientAddress;
  final String projectStatus;
  final double totalContract;  // إجمالي العقد/الاتفاق
  final DateTime paymentDate;  // تاريخ بدء/تسجيل المشروع
  final List<ProjectPayment> payments; // قائمة كافة الدفعات المسجلة

  ProjectModel({
    this.id,
    required this.clientName,
    required this.clientPhone,
    required this.clientAddress,
    required this.projectStatus,
    required this.totalContract,
    required this.paymentDate,
    List<ProjectPayment>? payments,
  }) : payments = payments ?? [];

  // إجمالي المبالغ المدفوعة حتى الآن
  double get paidAmount {
    return payments.fold(0.0, (sum, p) => sum + p.amount);
  }

  // المبلغ المتبقي على العميل
  double get remainingAmount => totalContract - paidAmount;
}