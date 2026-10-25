import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة ورشة الدهان',
      debugShowCheckedModeBanner: false,

      // ✅ حل مشكلة اختلاف قياسات الخطوط والودجت بين الأجهزة المختلفة
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // تقييد مقياس الخط بحيث لا يتجاوز الحدود التي تسبب انهيار الواجهة
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child!,
        );
      },

      // تطبيق الثيم الداكن الاحترافي والمريح للعين
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // خلفية داكنة عميقة
        primaryColor: const Color(0xFFFF9F43),           // برتقالي نحاسي مهني
        cardColor: const Color(0xFF1E222B),              // لون الكروت الداكن
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF181A20),
          elevation: 0,
          centerTitle: true,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF9F43),
          secondary: Color(0xFF1DD1A1), // أخضر للدفعات
          error: Color(0xFFFF6B6B),     // أحمر للمصروفات
          surface: Color(0xFF1E222B),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFF1F2F6)),
          bodyMedium: TextStyle(color: Color(0xFFF1F2F6)),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}