import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../recognition/recognition_home_screen.dart';
import '../learning/learning_home_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/history_screen.dart';
import 'user_guide_screen.dart';
import 'app_details_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _HomeContent(),
    const UserGuideScreen(),
    const SettingsScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          _pages[_selectedIndex],

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 25, left: 15, right: 15),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF122C3D) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(icon: Icons.home, label: provider.t('home_nav'), index: 0, isDark: isDark),
                  _buildNavItem(icon: Icons.menu_book, label: provider.t('guide_nav'), index: 1, isDark: isDark),
                  _buildNavItem(icon: Icons.settings, label: provider.t('settings'), index: 2, isDark: isDark),
                  _buildNavItem(icon: Icons.history, label: provider.t('history'), index: 3, isDark: isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index, required bool isDark}) {
    const Color activeColor = Color(0xFF395B6F);
    final bool isActive = _selectedIndex == index;
    final Color color = isActive ? (isDark ? Colors.tealAccent : activeColor) : Colors.grey;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;

    const Color primaryDark = Color(0xFF0D3146);
    const Color primaryLight = Color(0xFF395B6F);

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.t('splash_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (val) {
            if (val == 'details') Navigator.push(context, MaterialPageRoute(builder: (_) => const AppDetailsScreen()));
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'details',
              child: Row(children: [Icon(Icons.info_outline, color: isDark ? Colors.tealAccent : primaryLight), const SizedBox(width: 10), Text(provider.t('app_details'))]),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMainButton(
                context: context,
                title: provider.t('recognize_sign'),
                // 🟢 تداخل الأيقونات مع إطار يخفف الاحتكاك
                iconWidget: SizedBox(
                  width: 48, height: 48,
                  child: Stack(
                    children: [
                      const Align(alignment: Alignment.topLeft, child: Icon(Icons.sign_language, color: Colors.white, size: 36)),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          padding: const EdgeInsets.all(4), // هذا يخلق مسافة العزل
                          decoration: const BoxDecoration(color: primaryDark, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                color: primaryDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecognitionHomeScreen())),
              ),
              const SizedBox(height: 20),

              _buildMainButton(
                context: context,
                title: provider.t('learn_sign'),
                iconWidget: SizedBox(
                  width: 48, height: 48,
                  child: Stack(
                    children: [
                      const Align(alignment: Alignment.topLeft, child: Icon(Icons.sign_language, color: Colors.white, size: 36)),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: primaryLight, shape: BoxShape.circle),
                          child: const Icon(Icons.school, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                color: primaryLight,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningHomeScreen())),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton({required BuildContext context, required String title, required Widget iconWidget, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity, height: 70,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 4),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 15),
            // هنا الحل السحري: Flexible و FittedBox لمنع خروج النص عن الزر في أي لغة
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                    title,
                    style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}