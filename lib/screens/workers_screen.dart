import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/worker_model.dart';
import '../services/database_helper.dart';
import '../services/pdf_service.dart';
import 'add_worker_screen.dart';

class WorkersScreen extends StatefulWidget {
  final double currentExchangeRate;

  const WorkersScreen({super.key, required this.currentExchangeRate});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  List<WorkerModel> _workers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  // جلب العمال وسلفهم من قاعدة البيانات المحلية
  Future<void> _loadWorkers() async {
    setState(() => _isLoading = true);
    final workers = await DatabaseHelper.instance.fetchWorkers();
    if (!mounted) return;
    setState(() {
      _workers = workers;
      _isLoading = false;
    });
  }

  // الانتقال لصفحة إضافة عامل جديد وحفظه
  void _navigateToAddWorker() async {
    final WorkerModel? newWorker = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddWorkerScreen()),
    );

    if (newWorker != null) {
      await DatabaseHelper.instance.insertWorker(newWorker);
      if (!mounted) return;
      _loadWorkers();
    }
  }

  // نافذة تأكيد تصفية حساب العامل (بدء أسبوع جديد)
  void _showClearAccountDialog(WorkerModel worker) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E222B),
          title: Text('تصفية حساب ${worker.name}', style: const TextStyle(color: Colors.white, fontSize: 18)),
          content: const Text(
            'هل أنت متأكد من تصفية الحساب؟ سيتم مسح سجل السلف الحالية وإرجاع إجمالي السلف إلى الصفر لبدء أسبوع جديد، مع الحفاظ على بيانات العامل الأساسية.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B)),
              onPressed: () async {
                // إغلاق النافذة أولاً لتجنب مشاكل الـ Context
                Navigator.pop(dialogContext);

                // مسح الحركات من قاعدة البيانات
                await DatabaseHelper.instance.clearWorkerTransactions(worker.id);
                _loadWorkers(); // تحديث القائمة
              },
              child: const Text('تصفية وبدء أسبوع جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // نافذة تسجيل سلفة أو دفعة للعامل مع تحديد التاريخ والعملة
  void _showAddAdvanceDialog(WorkerModel worker) {
    TextEditingController amountController = TextEditingController();
    TextEditingController noteController = TextEditingController();
    String selectedCurrency = 'USD';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E222B),
              title: Text('تسجيل سلفة لـ ${worker.name}', style: const TextStyle(color: Colors.white, fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'المبلغ',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF9F43))),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('اختر العملة:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('دولار \$')),
                            selected: selectedCurrency == 'USD',
                            selectedColor: const Color(0xFFFF9F43),
                            backgroundColor: const Color(0xFF121212),
                            labelStyle: TextStyle(color: selectedCurrency == 'USD' ? Colors.black : Colors.white),
                            onSelected: (selected) {
                              setDialogState(() => selectedCurrency = 'USD');
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('ليرة سورية SYP')),
                            selected: selectedCurrency == 'SYP',
                            selectedColor: const Color(0xFFFF9F43),
                            backgroundColor: const Color(0xFF121212),
                            labelStyle: TextStyle(color: selectedCurrency == 'SYP' ? Colors.black : Colors.white),
                            onSelected: (selected) {
                              setDialogState(() => selectedCurrency = 'SYP');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: noteController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'ملاحظة (مثلاً: سلفة أسبوعية)',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF9F43))),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'التاريخ: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                          child: const Text('تغيير التاريخ', style: TextStyle(color: Color(0xFFFF9F43))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9F43)),
                  onPressed: () async {
                    if (amountController.text.isNotEmpty) {
                      double inputAmount = double.tryParse(amountController.text) ?? 0.0;
                      double finalAmountInUSD = inputAmount;

                      if (selectedCurrency == 'SYP') {
                        finalAmountInUSD = inputAmount / widget.currentExchangeRate;
                      }

                      final newTx = WorkerTransaction(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        amount: finalAmountInUSD,
                        originalAmount: inputAmount,
                        currency: selectedCurrency,
                        date: selectedDate,
                        note: noteController.text,
                      );

                      // إغلاق النافذة أولاً لتفادي مشاكل الـ Context
                      Navigator.pop(dialogContext);

                      // الحفظ في قاعدة البيانات وتحديث العرض
                      await DatabaseHelper.instance.insertWorkerTransaction(worker.id, newTx);
                      _loadWorkers();
                    }
                  },
                  child: const Text('حفظ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العمال والسلف', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFFFF9F43)),
            onPressed: _navigateToAddWorker,
            tooltip: 'إضافة عامل جديد',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9F43)))
          : _workers.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'لا يوجد عمال مضافون حالياً.\nاضغط على زر الإضافة بالأعلى لإدخال عمالك.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _workers.length,
        itemBuilder: (context, index) {
          final worker = _workers[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E222B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(worker.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    Row(
                      children: [
                        // زر تصفية الحساب (بدء أسبوع جديد)
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Color(0xFFFF6B6B), size: 20),
                          onPressed: () => _showClearAccountDialog(worker),
                          tooltip: 'تصفية الحساب وبدء أسبوع جديد',
                        ),
                        // زر إضافة سلفة
                        IconButton(
                          icon: const Icon(Icons.add_card, color: Color(0xFFFF9F43), size: 22),
                          onPressed: () => _showAddAdvanceDialog(worker),
                          tooltip: 'إضافة سلفة / دفعة',
                        ),

                        // أضف هذه الأيقونة في صف أزرار العامل العلوي:
                        IconButton(
                          icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF1DD1A1), size: 20),
                          onPressed: () async {
                            try {
                              // توليد كشف الحساب للعامل
                              final pdfBytes = await PdfService.generateWorkerStatement(worker);

                              // اسم ملف آمن يخلو من الأخطاء والمسافات العربية
                              String safeFileName = 'worker_statement_${worker.id}.pdf';

                              await PdfService.shareOrPrintPdf(pdfBytes, safeFileName);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('فشل تصدير كشف الحساب: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          tooltip: 'تصدير كشف حساب PDF',
                        ),
                      ],
                    ),
                  ],
                ),
                if (worker.phone.isNotEmpty) ...[
                  Text('الهاتف: ${worker.phone}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                ],
                Text('الأجر اليومي: \$${worker.dailyRate}', style: const TextStyle(color: Colors.white70, fontSize: 13)),

                // --- قسم عرض سجل السلف وتواريخها الحقيقية ---
                if (worker.transactions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('سجل السلف والتاريخ:', style: TextStyle(color: Color(0xFFFF9F43), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...worker.transactions.map((tx) {
                    String formattedTxDate = DateFormat('yyyy-MM-dd').format(tx.date);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${tx.note.isNotEmpty ? tx.note : 'سلفة'}: ${tx.originalAmount} ${tx.currency}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            formattedTxDate,
                            style: const TextStyle(color: Color(0xFFFF9F43), fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                const Divider(color: Colors.white12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي السلف المدفوعة:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text('\$ ${worker.totalAdvances.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}