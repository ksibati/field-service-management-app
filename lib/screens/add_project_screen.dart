import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/project_model.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _clientAddressController = TextEditingController();
  final TextEditingController _totalContractController = TextEditingController();
  final TextEditingController _initialPaymentController = TextEditingController();

  String _selectedStatus = 'جاري العمل';
  DateTime _selectedDate = DateTime.now();

  void _saveProject() {
    if (_formKey.currentState!.validate()) {
      double totalContract = double.tryParse(_totalContractController.text) ?? 0.0;
      double initialPayment = double.tryParse(_initialPaymentController.text) ?? 0.0;

      final newProject = ProjectModel(
        clientName: _clientNameController.text.trim(),
        clientPhone: _clientPhoneController.text.trim(),
        clientAddress: _clientAddressController.text.trim(),
        projectStatus: _selectedStatus,
        totalContract: totalContract,
        paymentDate: _selectedDate,
      );

      // إرجاع خريطة تحتوي على المشروع والدفعة الأولى
      Navigator.pop(context, {
        'project': newProject,
        'initialPayment': initialPayment,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة مشروع جديد', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _clientNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'اسم العميل *',
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.person, color: Color(0xFFFF9F43)),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'يرجى إدخال اسم العميل' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _clientPhoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.phone, color: Color(0xFFFF9F43)),
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _clientAddressController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'عنوان موقع الورشة',
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.location_on, color: Color(0xFFFF9F43)),
                ),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalContractController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'إجمالي العقد (\$) *',
                        labelStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.attach_money, color: Color(0xFFFF9F43)),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'يرجى إدخال المبلغ' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _initialPaymentController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'الدفعة الأولى (\$) (اختياري)',
                        labelStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.payments, color: Color(0xFF1DD1A1)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _selectedStatus,
                dropdownColor: const Color(0xFF1E222B),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'حالة الورشة',
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.work, color: Color(0xFFFF9F43)),
                ),
                items: ['لم تبدأ', 'جاري العمل', 'انتهت'].map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedStatus = value);
                },
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تاريخ البدء: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, color: Color(0xFFFF9F43), size: 18),
                    label: const Text('تغيير التاريخ', style: TextStyle(color: Color(0xFFFF9F43))),
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9F43),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _saveProject,
                  child: const Text('حفظ المشروع', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}