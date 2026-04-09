import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_provider.dart';

class UserGuideScreen extends StatelessWidget {
    const UserGuideScreen({super.key});

    @override
    Widget build(BuildContext context) {
      final provider = Provider.of<AppProvider>(context);
      final isDark = provider.isDarkMode;
      const Color primaryDark = Color(0xFF0D3146);

      return Scaffold(
        appBar: AppBar(
          title: Text(provider.t('user_guide')),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
          children: [
            _buildTipCard(
              isDark: isDark,
              icon: Icons.wifi_off_rounded,
              color: Colors.teal,
              title: provider.t('guide_offline_title'),
              desc: provider.t('guide_offline_desc'),
            ),
            const SizedBox(height: 20),

            _buildTipCard(
              isDark: isDark,
              icon: Icons.lightbulb_outline_rounded,
              color: Colors.amber,
              title: provider.t('guide_tip_title'),
              desc: provider.t('guide_tip_desc'),
            ),
            const SizedBox(height: 20),

            _buildSection(
                title: provider.t('guide_home_title'),
                icon: Icons.home_rounded,
                isDark: isDark,
                contentWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.t('guide_home_desc'), style: TextStyle(fontSize: 15.5, height: 1.8, color: isDark ? Colors.white70 : Colors.black87)),
                    const SizedBox(height: 10),
                    _buildBulletText(provider.t('recognize_sign'), provider.t('guide_home_rec_desc'), isDark),
                    _buildBulletText(provider.t('learn_sign'), provider.t('guide_home_learn_desc'), isDark),
                  ],
                )
            ),

            _buildSection(
                title: provider.t('guide_smart_trans_title'),
                icon: Icons.camera_alt_rounded,
                isDark: isDark,
                contentWidget: Column(
                  children: [
                    _buildBulletText(provider.t('guide_smart_start'), provider.t('guide_smart_start_desc'), isDark),
                    _buildBulletText(provider.t('guide_smart_privacy'), provider.t('guide_smart_privacy_desc'), isDark),
                    _buildBulletText(provider.t('guide_smart_age'), '${provider.t('guide_smart_age_desc')} ${provider.t('guide_smart_age_note')}', isDark),
                    _buildBulletText(provider.t('guide_smart_voice'), provider.t('guide_smart_voice_desc'), isDark),
                    _buildBulletText(provider.t('guide_smart_save'), provider.t('guide_smart_save_desc'), isDark),
                    _buildBulletText(provider.t('guide_smart_front'), provider.t('guide_smart_front_desc'), isDark),
                    _buildBulletText(provider.t('guide_smart_ain'), provider.t('guide_smart_ain_desc'), isDark),
                  ],
                )
            ),

            _buildSection(
                title: provider.t('guide_learn_title'),
                icon: Icons.school_rounded,
                isDark: isDark,
                contentWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.t('guide_learn_desc'), style: TextStyle(fontSize: 15.5, height: 1.8, color: isDark ? Colors.white70 : Colors.black87)),
                    const SizedBox(height: 10),
                    _buildBulletText(provider.t('guide_learn_browse'), provider.t('guide_learn_browse_desc'), isDark),
                    _buildBulletText(provider.t('guide_learn_attempts'), provider.t('guide_learn_attempts_desc'), isDark),
                    _buildBulletText(provider.t('guide_learn_auto'), provider.t('guide_learn_auto_desc'), isDark),
                    _buildBulletText(provider.t('guide_learn_cam'), provider.t('guide_learn_cam_desc'), isDark),
                    _buildBulletText(provider.t('guide_learn_score'), provider.t('guide_learn_score_desc'), isDark),
                    _buildSubBulletText(provider.t('guide_learn_score_letters'), isDark),
                    _buildSubBulletText(provider.t('guide_learn_score_numbers'), isDark),
                    _buildSubBulletText(provider.t('guide_learn_score_sentences'), isDark),
                  ],
                )
            ),

            _buildSection(
                title: provider.t('guide_settings_title'),
                icon: Icons.settings_rounded,
                isDark: isDark,
                contentWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.t('guide_settings_desc'), style: TextStyle(fontSize: 15.5, height: 1.8, color: isDark ? Colors.white70 : Colors.black87)),
                    const SizedBox(height: 10),
                    _buildBulletText(provider.t('guide_settings_theme'), provider.t('guide_settings_theme_desc'), isDark),
                    _buildSubBulletText(provider.t('guide_settings_theme_sub'), isDark),
                    const SizedBox(height: 5),
                    _buildBulletText(provider.t('guide_settings_text'), provider.t('guide_settings_text_desc'), isDark),
                    _buildBulletText(provider.t('guide_settings_test'), provider.t('guide_settings_test_desc'), isDark),
                    _buildBulletText(provider.t('alerts_settings'), provider.t('guide_settings_alert_desc'), isDark),
                  ],
                )
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF122C3D) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryDark.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.ondemand_video_rounded, color: Colors.redAccent, size: 28),
                      const SizedBox(width: 10),
                      Text(provider.t('guide_video_title'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : primaryDark)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildVideoLinkRow(isDark, provider.t('guide_video_ar'), "https://youtube.com/watch?v=oOwZCQgdCQg&si=vUnS6s8wOniyiU6D"),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    Widget _buildBulletText(String title, String text, bool isDark) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("• ", style: TextStyle(fontSize: 16, height: 1.8, color: isDark ? Colors.white : Colors.black87)),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 15.5, height: 1.8, color: isDark ? Colors.white70 : Colors.black87, fontFamily: 'Arial'),
                  children: [
                    TextSpan(text: "$title: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.tealAccent : const Color(0xFF0D3146))),
                    TextSpan(text: text),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildSubBulletText(String text, bool isDark) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("- ", style: TextStyle(fontSize: 14, height: 1.8, color: isDark ? Colors.white70 : Colors.black87)),
            Expanded(
              child: Text(text, style: TextStyle(fontSize: 14, height: 1.8, color: isDark ? Colors.white70 : Colors.black87)),
            ),
          ],
        ),
      );
    }

    Widget _buildVideoLinkRow(bool isDark, String title, String link) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final Uri url = Uri.parse(link);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(link, style: const TextStyle(fontSize: 15, color: Colors.blueAccent, decoration: TextDecoration.underline)),
            ),
          ),
        ],
      );
    }

    Widget _buildTipCard({required bool isDark, required IconData icon, required Color color, required String title, required String desc}) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2A33) : const Color(0xFFF1F8FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: isDark ? Colors.white : const Color(0xFF0D3146))),
                  const SizedBox(height: 8),
                  Text(desc, style: TextStyle(fontSize: 14, height: 1.8, color: isDark ? Colors.white70 : Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildSection({required String title, required IconData icon, required bool isDark, required Widget contentWidget}) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF122C3D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Theme(
          data: ThemeData().copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            iconColor: isDark ? Colors.tealAccent : const Color(0xFF395B6F),
            collapsedIconColor: isDark ? Colors.white54 : Colors.grey,
            title: Row(
              children: [
                Icon(icon, color: isDark ? Colors.tealAccent : const Color(0xFF395B6F), size: 24),
                const SizedBox(width: 14),
                Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: isDark ? Colors.white : const Color(0xFF0D3146)))),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 18, right: 18, bottom: 20),
                child: contentWidget,
              ),
            ],
          ),
        ),
      );
    }
}