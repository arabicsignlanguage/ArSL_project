import 'dart:async';
import 'package:flutter/material.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 🟢 الانتظار 3 ثواني ثم الانتقال للواجهة الرئيسية
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDark = Color(0xFF0D3146); // لون النصوص (أزرق داكن متناسق مع الشعار)

    return Scaffold(
      backgroundColor: const Color(0xFFEBE3D5), // 🟢 لون الخلفية البيج المطابق لصورتك
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🟢 1. صورة الشعار (اليدين فقط بدون نص) - تم تكبير العرض هنا
            Image.asset(
              'assets/images/splash_logo.jpg',
              width: 300, // 🟢 تم تكبير الصورة من 220 إلى 300
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(height: 300); // تكييف المساحة الفارغة عند الخطأ
              },
            ),

            const SizedBox(height: 25), // زيادة طفيفة في المسافة بين الصورة والنص

            // 🟢 2. العنوان الرئيسي
            const Text(
              "مترجم (ArSL)",
              style: TextStyle(
                fontFamily: 'Tajawal', // 🟢 يطبق الخط هنا فقط
                fontSize: 34,
                fontWeight: FontWeight.w900, // خط عريض جداً
                color: primaryDark,
              ),
            ),

            const SizedBox(height: 8),

            // 🟢 3. النص الإنجليزي
            const Text(
              "Arabic Sign Language Interpreter",
              style: TextStyle(
                fontFamily: 'Tajawal', // 🟢 يطبق الخط هنا فقط
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primaryDark,
              ),
            ),

            const SizedBox(height: 2), // 🟢 مسافة قصيرة جداً بين اللغتين

            // 🟢 4. النص العربي
            const Text(
              "مترجم لغة الإشارة العربية",
              style: TextStyle(
                fontFamily: 'Tajawal', // 🟢 يطبق الخط هنا فقط
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}