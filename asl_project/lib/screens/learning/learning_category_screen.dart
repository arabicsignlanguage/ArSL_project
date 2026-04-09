import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../../providers/app_provider.dart';
import 'test_discovery_screen.dart';
import 'test_selection_screen.dart';
import 'test_camera_screen.dart';

class LearningCategoryScreen extends StatelessWidget {
  final String categoryTitle;
  final String categoryType;

  const LearningCategoryScreen({super.key, required this.categoryTitle, required this.categoryType});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;

    const Color primaryDark = Color(0xFF0D3146);
    const Color activeBlueColor = Color(0xFF395B6F);
    final Color textColor = isDark ? Colors.white : primaryDark;

    final List<Map<String, dynamic>> lettersData = [
      {'label': 'أ', 'image': 'ا.jpg'},
      {'label': 'ب', 'image': 'ب.jpg'}, {'label': 'ت', 'image': 'ت.jpg'},
      {'label': 'ث', 'image': 'ث.jpg'}, {'label': 'ج', 'image': 'ج.jpg'}, {'label': 'ح', 'image': 'ح.jpg'},
      {'label': 'خ', 'image': 'خ.jpg'}, {'label': 'د', 'image': 'د.jpg'}, {'label': 'ذ', 'image': 'ذ.jpg'},
      {'label': 'ر', 'image': 'ر.jpg'}, {'label': 'ز', 'image': 'ز.jpg'}, {'label': 'س', 'image': 'س.jpg'},
      {'label': 'ش', 'image': 'ش.jpg'}, {'label': 'ص', 'image': 'ص.jpg'}, {'label': 'ض', 'image': 'ض.jpg'},
      {'label': 'ط', 'image': 'ط.jpg'}, {'label': 'ظ', 'image': 'ظ.jpg'}, {'label': 'ع', 'image': 'ع.jpg'},
      {'label': 'غ', 'image': 'غ.jpg'}, {'label': 'ف', 'image': 'ف.jpg'}, {'label': 'ق', 'image': 'ق.jpg'},
      {'label': 'ك', 'image': 'ك.jpg'}, {'label': 'ل', 'image': 'ل.jpg'}, {'label': 'م', 'image': 'م.jpg'},
      {'label': 'ن', 'image': 'ن.jpg'}, {'label': 'هـ', 'image': 'ه.jpg'}, {'label': 'و', 'image': 'و.jpg'},
      {'label': 'ي', 'image': 'ي.jpg'}, {'label': 'ى', 'image': 'ى.jpg'}, {'label': 'ال', 'image': 'ال.jpg'},
      {'label': 'لا', 'image': 'لا.jpg'}, {'label': 'ة', 'image': 'ة.jpg'},
    ];

    final List<Map<String, dynamic>> numbersData = [
      {'label': '٠', 'image': '0.jpg'}, {'label': '١', 'image': '1.jpg'},
      {'label': '٢', 'image': '2.jpg'}, {'label': '٣', 'image': '3.jpg'},
      {'label': '٤', 'image': '4.jpg'}, {'label': '٥', 'image': '5.jpg'},
      {'label': '٦', 'image': '6.jpg'}, {'label': '٧', 'image': '7.jpg'},
      {'label': '٨', 'image': '8.jpg'}, {'label': '٩', 'image': '9.jpg'},
    ];

    final List<Map<String, dynamic>> sentencesData = [
      {'label': 'أنا', 'image': 'I.jpg', 'type': 'word'},
      {'label': 'اسمي', 'image': 'my name.jpg', 'type': 'word'},
      {'label': 'عمري', 'image': 'my age.jpg', 'type': 'word'},
      {'label': 'غاضب', 'image': 'Anger.jpg', 'type': 'word'},
      {'label': 'سعيد', 'image': 'Happy.jpg', 'type': 'word'},
      {'label': 'آسف', 'image': 'Sorry.jpg', 'type': 'word'},
      {'label': 'أحبك', 'image': 'love you.jpg', 'type': 'word'},
      {'label': 'و', 'image': 'و.jpg', 'type': 'word'},
    ];

    List<Map<String, dynamic>> displayData = [];
    if (categoryType == 'letters') {
      displayData = lettersData;
    } else if (categoryType == 'numbers') {
      displayData = numbersData;
    } else if (categoryType == 'sentences') {
      displayData = sentencesData;
    }

    List<Map<String, dynamic>> discoveryTestData = List.from(displayData)..removeWhere((e) => e['label'] == 'و' && e['type'] == 'word');
    List<Map<String, dynamic>> selectionTestData = List.from(displayData)..removeWhere((e) => e['label'] == 'و' && e['type'] == 'word');
    List<Map<String, dynamic>> cameraTestData = List.from(displayData)..removeWhere((e) => e['label'] == 'و' && e['type'] == 'word');

    if (categoryType == 'sentences') {
      List<Map<String, dynamic>> simpleNames = [
        {'label': 'ملاك', 'letters': 'م,لا,ك', 'type': 'name'},
        {'label': 'الحسن', 'letters': 'ال,ح,س,ن', 'type': 'name'},
        {'label': 'حمزة', 'letters': 'ح,م,ز,ة', 'type': 'name'},
        {'label': 'أشرف', 'letters': 'أ,ش,ر,ف', 'type': 'name'},
        {'label': 'أحمد', 'letters': 'أ,ح,م,د', 'type': 'name'},
        {'label': 'فرح', 'letters': 'ف,ر,ح', 'type': 'name'},
        {'label': 'نور', 'letters': 'ن,و,ر', 'type': 'name'},
        {'label': 'عمر', 'letters': 'ع,م,ر', 'type': 'name'},
        {'label': 'فهد', 'letters': 'ف,هـ,د', 'type': 'name'},
        {'label': 'ريم', 'letters': 'ر,ي,م', 'type': 'name'},
        {'label': 'هند', 'letters': 'هـ,ن,د', 'type': 'name'},
        {'label': 'سمر', 'letters': 'س,م,ر', 'type': 'name'},
        {'label': 'علي', 'letters': 'ع,ل,ي', 'type': 'name'},
        {'label': 'سعد', 'letters': 'س,ع,د', 'type': 'name'},
        {'label': 'بدر', 'letters': 'ب,د,ر', 'type': 'name'},
        {'label': 'عوض', 'letters': 'ع,و,ض', 'type': 'name'},
        {'label': 'قصي', 'letters': 'ق,ص,ي', 'type': 'name'},
        {'label': 'ليث', 'letters': 'ل,ي,ث', 'type': 'name'},
        {'label': 'نهى', 'letters': 'ن,هـ,ى', 'type': 'name'},
        {'label': 'ندى', 'letters': 'ن,د,ى', 'type': 'name'},
        {'label': 'منى', 'letters': 'م,ن,ى', 'type': 'name'},
        {'label': 'هدى', 'letters': 'هـ,د,ى', 'type': 'name'},
        {'label': 'سيف', 'letters': 'س,ي,ف', 'type': 'name'},
        {'label': 'وليد', 'letters': 'و,ل,ي,د', 'type': 'name'},
        {'label': 'ماجد', 'letters': 'م,ا,ج,د', 'type': 'name'},
        {'label': 'رعد', 'letters': 'ر,ع,د', 'type': 'name'},
        {'label': 'مازن', 'letters': 'م,ا,ز,ن', 'type': 'name'},
        {'label': 'كريم', 'letters': 'ك,ر,ي,م', 'type': 'name'},
        {'label': 'زيد', 'letters': 'ز,ي,د', 'type': 'name'},
        {'label': 'طارق', 'letters': 'ط,ا,ر,ق', 'type': 'name'},
        {'label': 'سامي', 'letters': 'س,ا,م,ي', 'type': 'name'},
        {'label': 'رامي', 'letters': 'ر,ا,م,ي', 'type': 'name'},
        {'label': 'يوسف', 'letters': 'ي,و,س,ف', 'type': 'name'},
        {'label': 'مريم', 'letters': 'م,ر,ي,م', 'type': 'name'},
        {'label': 'محمد', 'letters': 'م,ح,م,د', 'type': 'name'},
        {'label': 'زينب', 'letters': 'ز,ي,ن,ب', 'type': 'name'},
        {'label': 'يحيى', 'letters': 'ي,ح,ي,ى', 'type': 'name'},
        {'label': 'جميل', 'letters': 'ج,م,ي,ل', 'type': 'name'},
        {'label': 'البتول', 'letters': 'ال,ب,ت,و,ل', 'type': 'name'},
        {'label': 'سعيد', 'letters': 'س,ع,ي,د', 'type': 'name'},
        {'label': 'خالد', 'letters': 'خ,ا,ل,د', 'type': 'name'},
        {'label': 'خليل', 'letters': 'خ,ل,ي,ل', 'type': 'name'},
        {'label': 'طلال', 'letters': 'ط,لا,ل', 'type': 'name'}, // تم تصحيح التقسيم لـ 3 صور
      ];

      List<Map<String, dynamic>> cameraNames = [
        {'label': 'أكرم', 'letters': 'أ,ك,ر,م', 'type': 'name'},
        {'label': 'أمير', 'letters': 'أ,م,ي,ر', 'type': 'name'},
        {'label': 'حسين', 'letters': 'ح,س,ي,ن', 'type': 'name'},
        {'label': 'زين', 'letters': 'ز,ي,ن', 'type': 'name'},
        {'label': 'شهد', 'letters': 'ش,هـ,د', 'type': 'name'},
        {'label': 'منار', 'letters': 'م,ن,ا,ر', 'type': 'name'},
        {'label': 'حمزة', 'letters': 'ح,م,ز,ة', 'type': 'name'},
        {'label': 'غزل', 'letters': 'غ,ز,ل', 'type': 'name'},
        {'label': 'نور', 'letters': 'ن,و,ر', 'type': 'name'},
        {'label': 'قيس', 'letters': 'ق,ي,س', 'type': 'name'},
        {'label': 'صقر', 'letters': 'ص,ق,ر', 'type': 'name'},
        {'label': 'محمد', 'letters': 'م,ح,م,د', 'type': 'name'},
        {'label': 'عدنان', 'letters': 'ع,د,ن,ا,ن', 'type': 'name'},
        {'label': 'شمس', 'letters': 'ش,م,س', 'type': 'name'},
        {'label': 'عمار', 'letters': 'ع,م,ا,ر', 'type': 'name'},
        {'label': 'نجيب', 'letters': 'ن,ج,ي,ب', 'type': 'name'},
        {'label': 'رنا', 'letters': 'ر,ن,ا', 'type': 'name'},
        {'label': 'سيف', 'letters': 'س,ي,ف', 'type': 'name'},
        {'label': 'عمر', 'letters': 'ع,م,ر', 'type': 'name'},
        {'label': 'علي', 'letters': 'ع,ل,ي', 'type': 'name'},
        {'label': 'خلود', 'letters': 'خ,ل,و,د', 'type': 'name'},
        {'label': 'سعد', 'letters': 'س,ع,د', 'type': 'name'},
        {'label': 'عوض', 'letters': 'ع,و,ض', 'type': 'name'},
        {'label': 'فضل', 'letters': 'ف,ض,ل', 'type': 'name'},
        {'label': 'كريم', 'letters': 'ك,ر,ي,م', 'type': 'name'},
        {'label': 'مازن', 'letters': 'م,ا,ز,ن', 'type': 'name'},
        {'label': 'ماجد', 'letters': 'م,ا,ج,د', 'type': 'name'},
        {'label': 'نهى', 'letters': 'ن,هـ,ى', 'type': 'name'},
        {'label': 'عبد اللَّه', 'letters': 'ع,ب,د, ,ال,ل,هـ', 'type': 'name'},
        {'label': 'بتول', 'letters': 'ب,ت,و,ل', 'type': 'name'},
        {'label': 'عبد الرحمن', 'letters': 'ع,ب,د, ,ال,ر,ح,م,ن', 'type': 'name'},
        {'label': 'عبد الملك', 'letters': 'ع,ب,د, ,ال,م,ل,ك', 'type': 'name'},
        {'label': 'غسان', 'letters': 'غ,س,ا,ن', 'type': 'name'},
        {'label': 'سلا', 'letters': 'س,لا', 'type': 'name'},
        {'label': 'أروى', 'letters': 'أ,ر,و,ى', 'type': 'name'},
        {'label': 'وفية', 'letters': 'و,ف,ي,ة', 'type': 'name'},
        {'label': 'أحلام', 'letters': 'أ,ح,لا,م', 'type': 'name'},
      ];

      discoveryTestData.addAll(simpleNames);
      selectionTestData.addAll(simpleNames);
      cameraTestData.addAll(cameraNames);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(provider.t('browse_images'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor), textAlign: TextAlign.center),
          ),

          Expanded(
            child: displayData.isEmpty
                ? Center(child: Text(provider.t('no_images'), style: TextStyle(color: textColor, fontSize: 16)))
                : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.65,
              ),
              itemCount: displayData.length,
              itemBuilder: (context, index) {
                final item = displayData[index];
                // 🟢 التعديل هنا: المسار يعتمد على اسم القسم مباشرة للصور العادية
                final folder = categoryType;
                final imagePath = 'assets/images/learning/$folder/${item['image']}';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImagePage(
                          imagePath: imagePath,
                          label: item['label'].toString(),
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(color: activeBlueColor, width: 2)
                    ),
                    color: isDark ? const Color(0xFF122C3D) : Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 50, color: activeBlueColor.withOpacity(0.5)),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: const BoxDecoration(
                            color: activeBlueColor,
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)),
                          ),
                          child: Text(
                            item['label'].toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A1922) : const Color(0xFFEBE3D5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.quiz, color: Colors.white),
              label: Text(provider.t('test_yourself'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              onPressed: () {
                if (displayData.isEmpty) return;
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    title: Text(provider.t('choose_test_type'), textAlign: TextAlign.center, style: const TextStyle(color: activeBlueColor, fontWeight: FontWeight.bold)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildInteractiveTestOption(
                          icon: Icons.search,
                          iconColor: Colors.teal,
                          title: provider.t('test_discovery'),
                          isDark: isDark,
                          onTap: () {
                            Future.delayed(const Duration(milliseconds: 150), () {
                              Navigator.pop(ctx);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => TestDiscoveryScreen(testData: discoveryTestData, categoryType: categoryType)));
                            });
                          },
                        ),
                        Divider(color: Colors.grey.withOpacity(0.3), height: 1),
                        _buildInteractiveTestOption(
                          icon: Icons.touch_app,
                          iconColor: Colors.orange,
                          title: categoryType == 'sentences' ? provider.t('test_selection_sent') : provider.t('test_selection'),
                          isDark: isDark,
                          onTap: () {
                            Future.delayed(const Duration(milliseconds: 150), () {
                              Navigator.pop(ctx);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => TestSelectionScreen(testData: selectionTestData, categoryType: categoryType)));
                            });
                          },
                        ),
                        Divider(color: Colors.grey.withOpacity(0.3), height: 1),
                        _buildInteractiveTestOption(
                          icon: Icons.camera_alt,
                          iconColor: Colors.blue,
                          title: provider.t('test_camera'),
                          isDark: isDark,
                          onTap: () {
                            Future.delayed(const Duration(milliseconds: 150), () {
                              Navigator.pop(ctx);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => TestCameraScreen(testData: cameraTestData, mode: categoryType)));
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInteractiveTestOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isDark,
    required VoidCallback onTap
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: iconColor.withOpacity(0.2),
        highlightColor: iconColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 15),
              Expanded(
                  child: Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)
                  )
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class FullScreenImagePage extends StatefulWidget {
  final String imagePath;
  final String label;

  const FullScreenImagePage({super.key, required this.imagePath, required this.label});

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  bool _hasSavedOnce = false;

  Future<void> _saveImage(BuildContext context) async {
    try {
      final ByteData byteData = await rootBundle.load(widget.imagePath);
      final Uint8List bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);

      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: "ArSL_${widget.label}",
      );

      if (context.mounted) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        if (result != null && result['isSuccess'] == true) {

          String successMsg = _hasSavedOnce ? provider.t('saved_to_gallery_again') : provider.t('saved_to_gallery');

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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF395B6F),
                        borderRadius: BorderRadius.circular(30)
                    ),
                    child: Text(successMsg, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 1500),
            ),
          );

          setState(() {
            _hasSavedOnce = true;
          });

        } else {
          throw Exception('Failed');
        }
      }
    } catch (e) {
      if (context.mounted) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.t('save_error'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt, color: Colors.white, size: 28),
            onPressed: () => _saveImage(context),
            tooltip: provider.t('save_image'),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.asset(widget.imagePath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}