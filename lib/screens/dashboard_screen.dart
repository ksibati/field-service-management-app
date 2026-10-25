import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../models/worker_model.dart';
import '../services/database_helper.dart';
import 'projects_screen.dart';
import 'workers_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double exchangeRate = 15000.0;
  List<ProjectModel> _projects = [];
  List<WorkerModel> _workers = [];
  bool _isLoading = true;

  // 📌 بيانات المبرمج ورقم الإصدار
  final String _developerName = "Aura Solutions"; // اسم المبرمج
  final String _developerEmail = "mohammad.ksibati@hotmail.com"; // الإيميل
  final String _developerPhone = "+963 991 688 649"; // رقم الهاتف
  final String _appVersion = "v1.0.0"; // رقم الإصدار

  @override
  void initState() {
    super.initState();
    _loadDataFromDatabase();
  }

  Future<void> _loadDataFromDatabase() async {
    setState(() => _isLoading = true);
    final projects = await DatabaseHelper.instance.fetchProjects();
    final workers = await DatabaseHelper.instance.fetchWorkers();
    if (!mounted) return;
    setState(() {
      _projects = projects;
      _workers = workers;
      _isLoading = false;
    });
  }

  double get _totalIncome => _projects.fold(0.0, (sum, p) => sum + p.paidAmount);
  double get _totalRemaining => _projects.fold(0.0, (sum, p) => sum + p.remainingAmount);
  double get _totalWorkersAdvances => _workers.fold(0.0, (sum, w) => sum + w.totalAdvances);

  // ✅ تم تصحيح خطأ حساب صافي الربح (إضافة علامة الطرح وتنسيق السطر)
  double get _netProfit => _totalIncome - _totalWorkersAdvances;

  void _showEditExchangeRateDialog() {
    TextEditingController controller = TextEditingController(text: exchangeRate.toString());

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E222B),
          title: const Text('تعديل سعر صرف الدولار', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'السعر بالليرة السورية مقابل 1 \$',
              labelStyle: TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9F43)),
              onPressed: () {
                setState(() {
                  exchangeRate = double.tryParse(controller.text) ?? exchangeRate;
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToProjects() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProjectsScreen()),
    );
    _loadDataFromDatabase();
  }

  void _navigateToWorkers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkersScreen(currentExchangeRate: exchangeRate),
      ),
    );
    _loadDataFromDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شركة الوسيم للخدمات', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9F43)))
          : RefreshIndicator(
        onRefresh: _loadDataFromDatabase,
        color: const Color(0xFFFF9F43),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. شريط سعر الصرف
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E222B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF9F43).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.currency_exchange, color: Color(0xFFFF9F43)),
                        const SizedBox(width: 10),
                        Text(
                          '1 USD = ${exchangeRate.toStringAsFixed(0)} SYP',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFFFF9F43), size: 20),
                      onPressed: _showEditExchangeRateDialog,
                      tooltip: 'تعديل سعر الصرف',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. كروت التنقل الرئيسي
              const Text('الأقسام الرئيسية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _navigateToProjects,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E222B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFF9F43).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.assignment, color: Color(0xFFFF9F43), size: 30),
                            const SizedBox(height: 10),
                            const Text('إدارة المشاريع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('${_projects.length} مشروع مسجل', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _navigateToWorkers,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E222B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1DD1A1).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.engineering, color: Color(0xFF1DD1A1), size: 30),
                            const SizedBox(height: 10),
                            const Text('إدارة العمال', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('${_workers.length} عامل مسجل', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // 3. الملخص المالي العام
              const Text('الملخص المالي العام (\$)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildFinancialCard('المقبوضات', '\$ ${_totalIncome.toStringAsFixed(2)}', const Color(0xFF1DD1A1))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildFinancialCard('المتبقي للعملاء', '\$ ${_totalRemaining.toStringAsFixed(2)}', const Color(0xFFFF6B6B))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildFinancialCard('سلف العمال', '\$ ${_totalWorkersAdvances.toStringAsFixed(2)}', const Color(0xFFFF6B6B))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildFinancialCard('صافي الربح', '\$ ${_netProfit.toStringAsFixed(2)}', const Color(0xFFFF9F43))),
                ],
              ),
              const SizedBox(height: 40),

              // 4. 🚀 بصمة حقوق المبرمج ومعلومات التواصل (Footer محسّن ومتجاوب)
              const Divider(color: Colors.white12, thickness: 1),
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF12141A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.code, color: Color(0xFFFF9F43), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _developerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ✅ استخدام Wrap بدلاً من Row لتجنب مشاكل Overflow على الشاشات الصغيرة
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.email_outlined, color: Colors.grey, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              _developerEmail,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone_outlined, color: Colors.grey, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              _developerPhone,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'إصدار التطبيق: $_appVersion',
                        style: const TextStyle(color: Color(0xFFFF9F43), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Text(amount, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}