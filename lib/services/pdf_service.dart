import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart' as intl;
import '../models/project_model.dart';
import '../models/worker_model.dart';

class PdfService {
  // 📄 1. توليد فاتورة مشروع للعميل
  static Future<Uint8List> generateProjectInvoice(ProjectModel project) async {
    final pdf = pw.Document();

    // تحميل خط عربي متوافق (Cairo) لدعم النصوص العربية
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final formattedDate = intl.DateFormat('yyyy-MM-dd').format(project.paymentDate);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl, // توجيه النص من اليمين لليسار
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // الهيدر الرئيسي / ترويسة الورشة
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('شركة الوسيم للخدمات', style: pw.TextStyle(font: fontBold, fontSize: 22, color: PdfColors.orange800)),
                        pw.Text('فاتورة / كشف حساب مشروع', style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('التاريخ: $formattedDate', style: pw.TextStyle(font: font, fontSize: 12)),
                        pw.Text('الحالة: ${project.projectStatus}', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.orange700)),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 1.5, color: PdfColors.orange300),
                pw.SizedBox(height: 15),

                // بيانات العميل والموقع
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('اسم العميل: ${project.clientName}', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                      if (project.clientPhone.isNotEmpty)
                        pw.Text('رقم الهاتف: ${project.clientPhone}', style: pw.TextStyle(font: font, fontSize: 12)),
                      if (project.clientAddress.isNotEmpty)
                        pw.Text('عنوان الورشة: ${project.clientAddress}', style: pw.TextStyle(font: font, fontSize: 12)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // جدول سجل الدفعات المستلمة
                pw.Text('سجل الدفعات المستلمة:', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                pw.SizedBox(height: 8),

                pw.TableHelper.fromTextArray(
                  context: context,
                  cellStyle: pw.TextStyle(font: font, fontSize: 11),
                  headerStyle: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
                  headers: ['#', 'المبلغ (\$)', 'التاريخ', 'الملاحظة'],
                  data: project.payments.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final p = entry.value;
                    return [
                      '$index',
                      '\$${p.amount.toStringAsFixed(2)}',
                      intl.DateFormat('yyyy-MM-dd').format(p.date),
                      p.note.isNotEmpty ? p.note : 'دفعة حساب',
                    ];
                  }).toList(),
                ),
                pw.SizedBox(height: 20),

                // الملخص المالي النهائي
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Container(
                    width: 220,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.orange400),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('إجمالي العقد:', style: pw.TextStyle(font: font, fontSize: 12)),
                            pw.Text('\$${project.totalContract.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('إجمالي المقبوض:', style: pw.TextStyle(font: font, fontSize: 12)),
                            pw.Text('\$${project.paidAmount.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.green700)),
                          ],
                        ),
                        pw.Divider(),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('المتبقي للسداد:', style: pw.TextStyle(font: fontBold, fontSize: 13)),
                            pw.Text('\$${project.remainingAmount.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.red700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Spacer(),

                // ذيل الفاتورة
                pw.Center(
                  child: pw.Text('شكراً لتعاملكم معنا - شركة الوسيم للخدمات', style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey600)),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

// 📄 2. توليد كشف حساب أسبوعي للعامل
  static Future<Uint8List> generateWorkerStatement(WorkerModel worker) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('كشف حساب عامل / سلف', style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfColors.orange800)),
                    pw.Text('التاريخ: ${intl.DateFormat('yyyy-MM-dd').format(DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 12)),
                  ],
                ),
                pw.Divider(thickness: 1.5, color: PdfColors.orange300),
                pw.SizedBox(height: 15),

                pw.Text('اسم العامل: ${worker.name}', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                if (worker.phone.isNotEmpty) pw.Text('رقم الهاتف: ${worker.phone}', style: pw.TextStyle(font: font, fontSize: 12)),
                pw.Text('الأجر اليومي: \$${worker.dailyRate}', style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 15),

                pw.Text('سجل السلف والدفعات المسحوبة:', style: pw.TextStyle(font: fontBold, fontSize: 13)),
                pw.SizedBox(height: 8),

                worker.transactions.isEmpty
                    ? pw.Text('لا توجد سلف أو دفعات مسجلة لهذا العامل حالياً.', style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700))
                    : pw.TableHelper.fromTextArray(
                  context: context,
                  cellStyle: pw.TextStyle(font: font, fontSize: 11),
                  headerStyle: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
                  headers: ['#', 'المبلغ المدخل', 'المعادل بالدولار', 'التاريخ', 'ملاحظة'],
                  data: worker.transactions.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final tx = entry.value;
                    return [
                      '$index',
                      '${tx.originalAmount} ${tx.currency}',
                      '\$${tx.amount.toStringAsFixed(2)}',
                      intl.DateFormat('yyyy-MM-dd').format(tx.date),
                      tx.note.isNotEmpty ? tx.note : 'سلفة',
                    ];
                  }).toList(),
                ),
                pw.SizedBox(height: 20),

                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Container(
                    width: 200,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.red400),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('مجموع السلف:', style: pw.TextStyle(font: fontBold, fontSize: 13)),
                        pw.Text('\$${worker.totalAdvances.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.red700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // 📤 3. مشاركة أو طباعة ملف الـ PDF مباشرة (WhatsApp / Print)
  static Future<void> shareOrPrintPdf(Uint8List pdfData, String filename) async {
    await Printing.sharePdf(bytes: pdfData, filename: filename);
  }
}