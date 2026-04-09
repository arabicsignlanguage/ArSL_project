import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'action_screen.dart';

class RecognitionHomeScreen extends StatelessWidget {
  const RecognitionHomeScreen({super.key});

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
        title: Text(provider.t('recognize_sign'), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back, textDirection: TextDirection.ltr),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(provider.t('choose_mode'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 40),

              _buildBtn(
                context: context, title: provider.t('letters'),
                leadingWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  child: Text(provider.t('ab_icon'), style: const TextStyle(fontSize: 16, letterSpacing: -1.5, fontWeight: FontWeight.bold, color: primaryDark, height: 1.1)),
                ),
                color: primaryDark, mode: "letters",
              ),
              const SizedBox(height: 15),

              // 🟢 تم استبدال الأيقونة بمربع "٢١" عربي
              _buildBtn(
                context: context, title: provider.t('numbers'),
                leadingWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  child: Text(provider.t('num_21_icon'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryLight, height: 1.1)),
                ),
                color: primaryLight, mode: "numbers",
              ),
              const SizedBox(height: 15),

              _buildBtn(
                context: context, title: provider.t('sentences'),
                leadingWidget: const Icon(Icons.question_answer, color: Colors.white, size: 28),
                color: accentColor, mode: "sentences",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBtn({required BuildContext context, required String title, required Widget leadingWidget, required Color color, required String mode}) {
    return SizedBox(
      width: double.infinity, height: 65,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 4, padding: EdgeInsets.zero),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActionScreen(mode: mode))),
        child: Row(
          children: [
            const SizedBox(width: 70),
            SizedBox(width: 40, child: Align(alignment: Alignment.center, child: leadingWidget)),
            const SizedBox(width: 20),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.start)),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}