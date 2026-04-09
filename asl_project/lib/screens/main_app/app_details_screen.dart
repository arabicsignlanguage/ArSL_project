import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class AppDetailsScreen extends StatelessWidget {
  const AppDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;
    const Color primaryDark = Color(0xFF0D3146);
    final Color textColor = isDark ? Colors.white : primaryDark;
    final TextStyle unifiedSubTextStyle = TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.grey.shade600, height: 1.6);

    return Scaffold(
      appBar: AppBar(title: Text(provider.t('app_details_title')), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),

            // 🟢 تم تكبير الشعار قليلاً (إلى 140x140)
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.asset(
                'assets/images/app_logo.jpg', // تأكد من وضع الصورة بهذا الاسم
                width: 200, // 🟢 تم التكبير هنا
                height: 200, // 🟢 تم التكبير هنا
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.sign_language, size: 90, color: isDark ? Colors.tealAccent : primaryDark),
              ),
            ),

            const SizedBox(height: 15),
            Text(provider.t('app_name'), style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 5),
            Text(provider.t('app_version'), style: TextStyle(fontSize: 16, color: isDark ? Colors.white54 : Colors.grey)),
            const SizedBox(height: 40),

            _buildCustomDetailRow(
                icon: Icons.group,
                title: provider.t('developers'),
                isDark: isDark,
                primaryDark: primaryDark,
                contentWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.t('dev_names_1'), style: unifiedSubTextStyle),
                    Text(provider.t('dev_names_2'), style: unifiedSubTextStyle),
                  ],
                )
            ),
            const Divider(height: 40),

            _buildCustomDetailRow(
              icon: Icons.description,
              title: provider.t('about_app'),
              isDark: isDark,
              primaryDark: primaryDark,
              contentWidget: Text(provider.t('app_desc_full'), style: unifiedSubTextStyle),
            ),
            const Divider(height: 40),

            _buildCustomDetailRow(
              icon: Icons.copyright,
              title: provider.t('copyright'),
              isDark: isDark,
              primaryDark: primaryDark,
              contentWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.t('copyright_year'), textDirection: TextDirection.ltr, style: unifiedSubTextStyle.copyWith(fontWeight: FontWeight.bold)),
                  Text(provider.t('all_rights_reserved'), style: unifiedSubTextStyle),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDetailRow({required IconData icon, required String title, required bool isDark, required Color primaryDark, required Widget contentWidget}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: isDark ? Colors.tealAccent : primaryDark, size: 28),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
              const SizedBox(height: 6),
              contentWidget,
            ],
          ),
        ),
      ],
    );
  }
}