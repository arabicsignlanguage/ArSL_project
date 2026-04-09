import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class CameraAlertsScreen extends StatelessWidget {
  const CameraAlertsScreen({super.key});

  void _showCustomSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(30)),
              child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  void _showCameraSelectionDialog(BuildContext context, AppProvider provider, bool isSound, Color activeSwitchColor) {
    bool tempFront = isSound ? provider.soundFrontCam : provider.vibFrontCam;
    bool tempBack = isSound ? provider.soundBackCam : provider.vibBackCam;
    bool showError = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: provider.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
              title: Text(provider.t('cam_selection'), style: const TextStyle(color: Color(0xFF395B6F), fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: Text(provider.t('back_cam'), style: const TextStyle(fontSize: 16)),
                    value: tempBack,
                    activeColor: activeSwitchColor,
                    checkColor: provider.isDarkMode ? Colors.black : Colors.white,
                    onChanged: (val) {
                      setState(() {
                        tempBack = val ?? false;
                        if (!tempBack && !tempFront) {
                          showError = true;
                          tempBack = true;
                        } else { showError = false; }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text(provider.t('front_cam'), style: const TextStyle(fontSize: 16)),
                    value: tempFront,
                    activeColor: activeSwitchColor,
                    checkColor: provider.isDarkMode ? Colors.black : Colors.white,
                    onChanged: (val) {
                      setState(() {
                        tempFront = val ?? false;
                        if (!tempBack && !tempFront) {
                          showError = true;
                          tempFront = true;
                        } else { showError = false; }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  if (showError)
                    Text(provider.t('err_min_cam'), style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.isDarkMode ? Colors.tealAccent : const Color(0xFF0D3146),
                    foregroundColor: provider.isDarkMode ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                  onPressed: () {
                    if (isSound) { provider.setSoundCams(tempFront, tempBack); }
                    else { provider.setVibCams(tempFront, tempBack); }
                    Navigator.pop(dialogContext);
                  },
                  child: Text(provider.t('btn_ok'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getActiveCamerasText(AppProvider provider, bool isFront, bool isBack) {
    List<String> active = [];
    if (isBack) active.add(provider.t('back_cam'));
    if (isFront) active.add(provider.t('front_cam'));
    return active.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;
    final Color primaryDark = const Color(0xFF0D3146);
    final Color textColor = isDark ? Colors.white : primaryDark;

    final Color activeSwitchColor = isDark ? Colors.tealAccent : const Color(0xFF395B6F);

    return Scaffold(
      appBar: AppBar(title: Text(provider.t('alerts_settings')), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        children: [
          Card(
            elevation: 2, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              title: Text(provider.t('enable_alerts'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
              value: provider.enableAlerts,
              activeColor: activeSwitchColor,
              onChanged: (val) {
                provider.toggleAlerts(val);
                if (val && !provider.enableSound && !provider.enableVib) {
                  provider.toggleSound(true);
                }
              },
            ),
          ),

          if (provider.enableAlerts) ...[
            const SizedBox(height: 25),

            Card(
              elevation: 2, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: Text(provider.t('sound_alert'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(provider.t('sound_desc'), style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                    value: provider.enableSound,
                    activeColor: activeSwitchColor,
                    checkColor: isDark ? Colors.black : Colors.white,
                    onChanged: (val) {
                      if (val == false && !provider.enableVib) {
                        provider.toggleSound(true);
                        _showCustomSnackbar(context, provider.t('err_min_alert'));
                      } else {
                        provider.toggleSound(val ?? false);
                      }
                    },
                  ),
                  if (provider.enableSound)
                    InkWell(
                      onTap: () => _showCameraSelectionDialog(context, provider, true, activeSwitchColor),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(provider.t('active_cams'), style: TextStyle(fontSize: 15, color: textColor, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            Text(_getActiveCamerasText(provider, provider.soundFrontCam, provider.soundBackCam), style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 2, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: Text(provider.t('vib_alert'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(provider.t('vib_desc'), style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                    value: provider.enableVib,
                    activeColor: activeSwitchColor,
                    checkColor: isDark ? Colors.black : Colors.white,
                    onChanged: (val) {
                      if (val == false && !provider.enableSound) {
                        provider.toggleVib(true);
                        _showCustomSnackbar(context, provider.t('err_min_alert'));
                      } else {
                        provider.toggleVib(val ?? false);
                        if (val == true) {
                          provider.setVibCams(true, false);
                        }
                      }
                    },
                  ),
                  if (provider.enableVib)
                    InkWell(
                      onTap: () => _showCameraSelectionDialog(context, provider, false, activeSwitchColor),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(provider.t('active_cams'), style: TextStyle(fontSize: 15, color: textColor, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            Text(_getActiveCamerasText(provider, provider.vibFrontCam, provider.vibBackCam), style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}