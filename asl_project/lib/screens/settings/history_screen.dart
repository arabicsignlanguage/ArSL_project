import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFF958979);

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final Color textValueColor = isDark ? Colors.white : Colors.black87;
        final Color titleColor = isDark ? accentColor : const Color(0xFF395B6F);
        final Color transTextColor = isDark ? Colors.tealAccent : Colors.blue;
        const Color transIconColor = Colors.blue;

        return Scaffold(
          appBar: AppBar(
            title: Text(provider.t('saved_history')),
            centerTitle: true,
            automaticallyImplyLeading: false, // 🟢 إلغاء سهم الرجوع
            actions: [
              IconButton(icon: const Icon(Icons.delete_forever, color: Colors.white), onPressed: () => provider.clearHistory()),
            ],
          ),
          body: provider.history.isEmpty
              ? Center(child: Text(provider.t('no_history'), style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold)))
              : ListView.builder(
            padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 100), // مساحة للشريط السفلي
            itemCount: provider.history.length,
            itemBuilder: (context, index) {
              final item = provider.history[index];
              bool hasCamText = item['camText'] != null && item['camText']!.trim().isNotEmpty;
              bool hasCamTrans = item['camTrans'] != null && item['camTrans']!.trim().isNotEmpty && item['camTrans'] != provider.t('conn_error');
              bool hasReply = item['replyText'] != null && item['replyText']!.trim().isNotEmpty;
              bool hasReplyTrans = item['replyTrans'] != null && item['replyTrans']!.trim().isNotEmpty && item['replyTrans'] != provider.t('conn_error');

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(text: TextSpan(children: [
                        TextSpan(text: "${provider.t('detected')}: ", style: TextStyle(fontWeight: FontWeight.bold, color: titleColor, fontSize: 16)),
                        TextSpan(text: hasCamText ? item['camText'] : provider.t('not_recognized'), style: TextStyle(fontWeight: FontWeight.w600, color: hasCamText ? textValueColor : Colors.grey, fontSize: 16)),
                      ])),
                      if (hasCamTrans)
                        Padding(padding: const EdgeInsets.only(top: 6.0), child: Row(children: [
                          const Icon(Icons.g_translate, size: 16, color: transIconColor), const SizedBox(width: 6),
                          Text(item['camTrans']!, style: TextStyle(color: transTextColor, fontSize: 14, fontStyle: FontStyle.italic)),
                        ])),
                      const SizedBox(height: 10),
                      if (hasReply)
                        RichText(text: TextSpan(children: [
                          TextSpan(text: "${provider.t('reply')}: ", style: TextStyle(fontWeight: FontWeight.bold, color: titleColor, fontSize: 16)),
                          TextSpan(text: item['replyText'], style: TextStyle(fontWeight: FontWeight.w600, color: textValueColor, fontSize: 16)),
                        ])),
                      if (hasReplyTrans)
                        Padding(padding: const EdgeInsets.only(top: 6.0), child: Row(children: [
                          const Icon(Icons.g_translate, size: 16, color: transIconColor), const SizedBox(width: 6),
                          Text(item['replyTrans']!, style: TextStyle(color: transTextColor, fontSize: 14, fontStyle: FontStyle.italic)),
                        ])),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () => provider.deleteHistoryItem(index),
                          child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 26)),
                        ),
                      ),
                      Divider(color: accentColor.withOpacity(0.3), thickness: 1, height: 10),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.access_time, size: 14, color: accentColor), const SizedBox(width: 4),
                            Text(item['date'] ?? "", style: const TextStyle(fontSize: 13, color: accentColor, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}