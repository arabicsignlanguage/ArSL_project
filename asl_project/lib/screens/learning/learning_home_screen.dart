import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'learning_category_screen.dart';

class LearningHomeScreen extends StatelessWidget {
  const LearningHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryDark = Color(0xFF0D3146);
    const Color primaryLight = Color(0xFF395B6F);
    const Color accentColor = Color(0xFF958979);

    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;
    final Color textColor = isDark ? Colors.white : primaryDark;

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.t('learn_sign'), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(provider.t('choose_learning_mode'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 40),

              _buildLearningBtn(
                context: context, title: provider.t('letters'),
                iconWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  child: const Text("أب", style: TextStyle(fontSize: 16, letterSpacing: -1.5, fontWeight: FontWeight.bold, color: primaryDark, height: 1.1)),
                ),
                color: primaryDark, categoryType: "letters",
              ),
              const SizedBox(height: 15),

              // 🟢 تم استبدال الأيقونة هنا بمربع "٢١"
              _buildLearningBtn(
                context: context, title: provider.t('numbers'),
                iconWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  child: const Text("٢١", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryLight, height: 1.1)),
                ),
                color: primaryLight, categoryType: "numbers",
              ),
              const SizedBox(height: 15),

              _buildLearningBtn(context: context, title: provider.t('sentences'), iconWidget: const Icon(Icons.question_answer, color: Colors.white, size: 28), color: accentColor, categoryType: "sentences"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLearningBtn({required BuildContext context, required String title, required Widget iconWidget, required Color color, required String categoryType}) {
    return SizedBox(
      width: double.infinity, height: 65,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 4, padding: EdgeInsets.zero),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LearningCategoryScreen(categoryTitle: title, categoryType: categoryType))),
        child: Row(
          children: [
            const SizedBox(width: 70),
            SizedBox(width: 40, child: Align(alignment: Alignment.center, child: iconWidget)),
            const SizedBox(width: 20),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.start)),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}