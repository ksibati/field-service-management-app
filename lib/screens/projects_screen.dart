import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/project_model.dart';
import '../services/database_helper.dart';
import '../services/pdf_service.dart';
import 'add_project_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<ProjectModel> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final projects = await DatabaseHelper.instance.fetchProjects();
    if (!mounted) return;
    setState(() {
      _projects = projects;
      _isLoading = false;
    });
  }

  void _navigateToAddProject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProjectScreen()),
    );

    if (result != null && result is Map) {
      final ProjectModel newProject = result['project'];
      final double initialPayment = result['initialPayment'] ?? 0.0;

      await DatabaseHelper.instance.insertProject(newProject, initialPayment);
      _loadProjects();
    }
  }

  void _showAddPaymentDialog(ProjectModel project) {
    TextEditingController amountController = TextEditingController();
    TextEditingController noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E222B),
              title: Text('تسجيل دفعة لـ ${project.clientName}', style: const TextStyle(color: Colors.white, fontSize: 18)),
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
                        labelText: 'المبلغ بالدولار \$',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF9F43))),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: noteController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'ملاحظة (مثلاً: دفعة العزل / المرحلة 2)',
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
                    if (amountController.text.isNotEmpty && project.id != null) {
                      double amount = double.tryParse(amountController.text) ?? 0.0;

                      final newPayment = ProjectPayment(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        amount: amount,
                        date: selectedDate,
                        note: noteController.text,
                      );

                      Navigator.pop(dialogContext);
                      await DatabaseHelper.instance.insertProjectPayment(project.id!, newPayment);
                      _loadProjects();
                    }
                  },
                  child: const Text('حفظ الدفعة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showProjectOptionsDialog(ProjectModel project) {
    String selectedStatus = project.projectStatus;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E222B),
              title: Text('تفاصيل مشروع: ${project.clientName}', style: const TextStyle(color: Colors.white, fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الهاتف: ${project.clientPhone.isNotEmpty ? project.clientPhone : 'غير متوفر'}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('العنوان: ${project.clientAddress.isNotEmpty ? project.clientAddress : 'غير متوفر'}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('إجمالي الاتفاق:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text('\$${project.totalContract}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('إجمالي المقبوض:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text('\$${project.paidAmount}', style: const TextStyle(color: Color(0xFF1DD1A1), fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('المتبقي على العميل:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text('\$${project.remainingAmount}', style: TextStyle(color: project.remainingAmount > 0 ? const Color(0xFFFF6B6B) : const Color(0xFF1DD1A1), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('سجل الدفعات المستلمة:', style: TextStyle(color: Color(0xFFFF9F43), fontSize: 13, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9F43),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          icon: const Icon(Icons.add, size: 16, color: Colors.black),
                          label: const Text('دفعة جديدة', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _showAddPaymentDialog(project);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (project.payments.isEmpty)
                      const Text('لا توجد دفعات مسجلة بعد.', style: TextStyle(color: Colors.grey, fontSize: 12))
                    else
                      ...project.payments.map((p) {
                        String formattedPaymentDate = DateFormat('yyyy-MM-dd').format(p.date);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121212),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${p.note.isNotEmpty ? p.note : 'دفعة'}: \$${p.amount}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              Text(formattedPaymentDate, style: const TextStyle(color: Color(0xFFFF9F43), fontSize: 11)),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 15),
                    const Text('تغيير حالة الورشة:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      dropdownColor: const Color(0xFF1E222B),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF9F43))),
                      ),
                      items: ['لم تبدأ', 'جاري العمل', 'انتهت'].map((status) {
                        return DropdownMenuItem(value: status, child: Text(status));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedStatus = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('حذف المشروع'),
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    if (project.id != null) {
                      await DatabaseHelper.instance.deleteProject(project.id!);
                      _loadProjects();
                    }
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFFF9F43), size: 18),
                  label: const Text('تصدير الفاتورة', style: TextStyle(color: Color(0xFFFF9F43))),
                  onPressed: () async {
                    final pdfBytes = await PdfService.generateProjectInvoice(project);
                    await PdfService.shareOrPrintPdf(
                      pdfBytes,
                      'invoice_project_${project.id}.pdf',
                    );
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9F43)),
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    if (project.id != null) {
                      await DatabaseHelper.instance.updateProjectStatus(project.id!, selectedStatus);
                      _loadProjects();
                    }
                  },
                  child: const Text('حفظ التعديل', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        title: const Text('إدارة المشاريع', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business, color: Color(0xFFFF9F43)),
            onPressed: _navigateToAddProject,
            tooltip: 'إضافة مشروع جديد',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9F43)))
          : _projects.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'لا توجد مشاريع مضافة بعد.\nاضغط على الزر بالأعلى لإضافة مشروع جديد.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9F43)),
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('إضافة مشروع جديد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              onPressed: _navigateToAddProject,
            )
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _projects.length,
        itemBuilder: (context, index) {
          final project = _projects[index];
          String formattedDate = DateFormat('yyyy-MM-dd').format(project.paymentDate);

          Color statusColor = project.projectStatus == 'انتهت'
              ? const Color(0xFF1DD1A1)
              : project.projectStatus == 'جاري العمل'
              ? const Color(0xFFFF9F43)
              : Colors.grey;

          return InkWell(
            onTap: () => _showProjectOptionsDialog(project),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E222B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        project.clientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          project.projectStatus,
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (project.clientPhone.isNotEmpty || project.clientAddress.isNotEmpty) ...[
                    Row(
                      children: [
                        if (project.clientPhone.isNotEmpty) ...[
                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(project.clientPhone, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(width: 15),
                        ],
                        if (project.clientAddress.isNotEmpty) ...[
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              project.clientAddress,
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  const Divider(color: Colors.white12),
                  const SizedBox(height: 4),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الاتفاق: \$${project.totalContract} | المدفوع: \$${project.paidAmount}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text('التاريخ: $formattedDate', style: const TextStyle(color: Color(0xFFFF9F43), fontSize: 12)),
                        ],
                      ),
                      Text(
                        'المتبقي: \$${project.remainingAmount}',
                        style: TextStyle(
                          color: project.remainingAmount > 0 ? const Color(0xFFFF6B6B) : const Color(0xFF1DD1A1),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}