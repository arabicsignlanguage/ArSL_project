import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'camera_alerts_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;

    final Color textColor = isDark ? Colors.white : const Color(0xFF0D3146);
    final Color activeColor = isDark ? Colors.tealAccent : const Color(0xFF395B6F);
    final Color iconColor = isDark ? Colors.tealAccent : const Color(0xFF958979);
    final TextStyle unifiedSubTextStyle = TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600);

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.t('settings')),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 18, right: 18, top: 14, bottom: 100),
        children: [
          Text(provider.t('appearance_lang'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          Card(
            elevation: 2, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(isDark ? provider.t('night_mode') : provider.t('day_mode'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text(isDark ? provider.t('night_desc') : provider.t('day_desc'), style: unifiedSubTextStyle),
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.wb_sunny, color: isDark ? Colors.amber : Colors.orangeAccent, size: 28),
                  value: provider.isDarkMode,
                  activeColor: activeColor,
                  onChanged: (val) { provider.toggleTheme(val); },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.blue, size: 28),
                  title: Text(provider.t('app_lang'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text((provider.supportedLanguages[provider.currentLang] ?? "العربية").split(' (').first, style: unifiedSubTextStyle),
                      const SizedBox(width: 8), const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () => _showLanguageDialog(context, provider, activeColor),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          Text(provider.t('app_customization'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          Card(
            elevation: 2, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.text_fields, color: iconColor, size: 28),
                  title: Text(provider.t('recognized_text_size'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Slider(
                    value: provider.translatedTextSize,
                    min: 10.0, max: 25.0, divisions: 15,
                    activeColor: activeColor,
                    label: provider.translatedTextSize.toInt().toString(),
                    onChanged: (val) => provider.setTranslatedTextSize(val),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.speed, color: iconColor, size: 28),
                  title: Text(provider.t('voice_speech_rate'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Slider(
                    value: provider.speechRate,
                    min: 0.1, max: 1.0, divisions: 9,
                    activeColor: activeColor,
                    label: provider.speechRate.toStringAsFixed(1),
                    onChanged: (val) => provider.setSpeechRate(val),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          Text(provider.t('test_settings'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          Card(
            elevation: 2, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(provider.t('auto_next_question'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text(provider.t('auto_next_question_desc'), style: unifiedSubTextStyle),
                  secondary: Icon(Icons.auto_mode, color: iconColor, size: 28),
                  value: provider.autoNextQuestion,
                  activeColor: activeColor,
                  onChanged: (val) { provider.toggleAutoNextQuestion(val); },
                ),
                Divider(height: 1, color: isDark ? Colors.white24 : Colors.grey.shade300),
                SwitchListTile(
                  title: Text(provider.t('test_confetti_effects'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text(provider.t('test_confetti_desc'), style: unifiedSubTextStyle),
                  secondary: Icon(Icons.celebration, color: isDark ? Colors.amber : Colors.orange, size: 28),
                  value: provider.enableConfetti,
                  activeColor: activeColor,
                  onChanged: (val) { provider.toggleConfetti(val); },
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          Text(provider.t('alerts_section'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          Card(
            elevation: 2, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.notifications_active, color: iconColor, size: 28),
              title: Text(provider.t('alerts_settings'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraAlertsScreen())),
            ),
          ),

          const SizedBox(height: 25),

          Text(provider.t('about_and_support'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          Card(
            elevation: 2, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.email, color: iconColor, size: 28),
                  title: Text(provider.t('contact_us'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.t('contact_email_desc')),
                          action: SnackBarAction(
                            label: provider.t('copy'),
                            textColor: Colors.blueAccent,
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: 'arabic.sign.language.5@gmail.com'));
                            },
                          ),
                        )
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.privacy_tip, color: iconColor, size: 28),
                  title: Text(provider.t('privacy_policy'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showPrivacyDialog(context, provider, isDark, textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context, AppProvider provider, bool isDark, Color textColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text(provider.t('privacy_policy'), style: const TextStyle(color: Color(0xFF395B6F), fontWeight: FontWeight.bold)),
        content: Text(
            provider.t('privacy_policy_desc_full'),
            style: const TextStyle(height: 1.5)
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(provider.t('btn_ok'), style: const TextStyle(fontWeight: FontWeight.bold)))],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, AppProvider provider, Color activeColor) {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
          title: Text(provider.t('choose_lang'), style: const TextStyle(color: Color(0xFF395B6F), fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.supportedLanguages.length,
                  itemBuilder: (context, index) {
                    String key = provider.supportedLanguages.keys.elementAt(index);
                    String name = provider.supportedLanguages[key]!;
                    return RadioListTile<String>(
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        value: key,
                        groupValue: provider.currentLang,
                        activeColor: activeColor,
                        onChanged: (val) {
                          if (val != null) { provider.changeLanguage(val); Navigator.pop(context); }
                        }
                    );
                  }
              )
          )
      );
    });
  }
}