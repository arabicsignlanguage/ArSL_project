import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'test_discovery_screen.dart';
import 'test_selection_screen.dart';
import 'test_camera_screen.dart';

class TestResultScreen extends StatelessWidget {
  final int score;
  final List<dynamic> testData; // 🟢 جعلناها تقبل أي نوع لتفادي أخطاء التمرير
  final String testType; // 'discovery', 'selection', 'camera'
  final String categoryType; // 'letters', 'numbers', 'sentences'

  const TestResultScreen({
    super.key,
    required this.score,
    required this.testData,
    required this.testType,
    required this.categoryType
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;
    const Color primaryDark = Color(0xFF0D3146);

    String message = "";
    String stars = "";

    if (score >= 90) { message = "${provider.t('result_excellent')} 🎉"; stars = "⭐⭐⭐⭐"; }
    else if (score >= 80) { message = "${provider.t('result_vgood')} 🤗"; stars = "⭐⭐⭐"; }
    else if (score >= 70) { message = "${provider.t('result_good')} 😃"; stars = "⭐⭐"; }
    else if (score >= 60) { message = "${provider.t('result_acceptable')} 🙂"; stars = "⭐"; }
    else if (score >= 50) { message = "${provider.t('result_poor')} 👀"; stars = ""; }
    else { message = "🙁\n${provider.t('result_fail')} 💪🏻"; stars = ""; }

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.t('final_result')),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(provider.t('your_score'), style: TextStyle(fontSize: 24, color: isDark ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 20),

              SizedBox(
                width: 170, height: 170,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 16,
                      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.tealAccent : primaryDark),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text("$score%", style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: isDark ? Colors.white : primaryDark)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              if (stars.isNotEmpty) Text(stars, style: const TextStyle(fontSize: 35)),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: score >= 50 ? 28 : 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : primaryDark)),

              const SizedBox(height: 60),

              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: Text(provider.t('retry_test'), style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () {

                    // 🟢 تحويل البيانات بطريقة آمنة 100% ليقبلها أي اختبار
                    List<Map<String, String>> safeData = testData.map((e) => Map<String, String>.from(e as Map)).toList();

                    if (testType == 'selection') {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TestSelectionScreen(testData: safeData, categoryType: categoryType)));
                    } else if (testType == 'camera') {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TestCameraScreen(testData: safeData, mode: categoryType)));
                    } else {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TestDiscoveryScreen(testData: safeData, categoryType: categoryType)));
                    }
                  },
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(provider.t('back_to_browse'), style: TextStyle(fontSize: 16, color: isDark ? Colors.tealAccent : Colors.grey.shade600))
              )
            ],
          ),
        ),
      ),
    );
  }
}