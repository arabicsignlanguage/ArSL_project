import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import '../../providers/app_provider.dart';
import 'test_result_screen.dart';

class SelectionQuestionState {
  String status = 'unanswered';
  String selectedAnswer = '';
}

class TestSelectionScreen extends StatefulWidget {
  final List<Map<String, dynamic>> testData;
  final String categoryType;

  const TestSelectionScreen({super.key, required this.testData, required this.categoryType});

  @override
  State<TestSelectionScreen> createState() => _TestSelectionScreenState();
}

class _TestSelectionScreenState extends State<TestSelectionScreen> {
  int currentIndex = 0;
  late List<SelectionQuestionState> questionStates;
  late List<Map<String, dynamic>> shuffledData;
  late List<List<Map<String, dynamic>>> optionsList;
  int currentLimit = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;

  bool _isAnimating = false;
  Timer? _transitionTimer;

  @override
  void initState() {
    super.initState();
    _initializeTestData();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _generateAllOptions();
  }

  void _initializeTestData() {
    if (widget.categoryType == 'sentences') {
      currentLimit = 25;
      var allData = List<Map<String, dynamic>>.from(widget.testData);
      var words = allData.where((e) => e['type'] == 'word').toList();
      var names = allData.where((e) => e['type'] == 'name').toList();

      names.removeWhere((e) => e['label'].toString().startsWith('عبد '));

      var requiredWords = words.where((e) => ['أنا', 'اسمي', 'عمري', 'غاضب', 'سعيد', 'آسف', 'أحبك'].contains(e['label'])).toList();

      names.shuffle();

      var first25 = <Map<String, dynamic>>[];
      first25.addAll(requiredWords);

      int needed = 25 - first25.length;
      if (needed > names.length) needed = names.length;
      first25.addAll(names.take(needed));
      first25.shuffle();
      names.removeRange(0, needed);

      var extra10 = <Map<String, dynamic>>[];
      // أخذ 6 أسماء جديدة
      extra10.addAll(names.take(6));

      // أخذ 4 كلمات عشوائية للمراجعة من القائمة الأساسية
      var reviewWords = List<Map<String, dynamic>>.from(words)..shuffle();
      extra10.addAll(reviewWords.take(4));

      extra10.shuffle();
      shuffledData = [...first25, ...extra10];

    } else if (widget.categoryType == 'numbers') {
      currentLimit = 10;
      var base = List<Map<String, dynamic>>.from(widget.testData)..shuffle();
      var extra = List<Map<String, dynamic>>.from(base)..shuffle();
      shuffledData = [...base, ...extra.take(5)];
    } else {
      currentLimit = 32;
      var base = List<Map<String, dynamic>>.from(widget.testData)..shuffle();
      var extra = List<Map<String, dynamic>>.from(base)..shuffle();
      shuffledData = [...base, ...extra.take(5)];
    }
    questionStates = List.generate(shuffledData.length, (index) => SelectionQuestionState());
  }

  void _generateAllOptions() {
    optionsList = [];
    for (var item in shuffledData) {
      List<Map<String, dynamic>> options = [item];

      bool isName = item.containsKey('type') && item['type'] == 'name';
      bool isWord = item.containsKey('type') && item['type'] == 'word';

      List<Map<String, dynamic>> otherData = List.from(widget.testData)
        ..removeWhere((element) => element['label'].toString() == item['label'].toString());

      if (isName) {
        otherData.removeWhere((element) => element.containsKey('type') && element['type'] == 'word');
      } else if (isWord) {
        otherData.removeWhere((element) => element.containsKey('type') && element['type'] == 'name');
      }

      otherData.shuffle();
      options.addAll(otherData.take(3));
      options.shuffle();
      optionsList.add(options);
    }
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    _audioPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _checkAnswer(String selectedLabelOrImage) {
    if (_isAnimating || questionStates[currentIndex].status != 'unanswered') return;

    bool isSentence = widget.categoryType == 'sentences';
    String correctTarget = isSentence ? shuffledData[currentIndex]['label'].toString() : shuffledData[currentIndex]['image'].toString();

    SelectionQuestionState currentState = questionStates[currentIndex];
    bool isCorrect = (selectedLabelOrImage == correctTarget);

    final provider = Provider.of<AppProvider>(context, listen: false);
    currentState.selectedAnswer = selectedLabelOrImage;

    if (isCorrect) {
      setState(() {
        _isAnimating = true;
        currentState.status = 'correct';
      });

      // 🟢 تفريغ الزحمة للصوت والفرقعة
      _audioPlayer.stop().then((_) => _audioPlayer.play(AssetSource('sounds/success.mp3')));
      if (provider.enableConfetti) {
        _confettiController.stop();
        _confettiController.play();
      }

      if (provider.autoNextQuestion) {
        _transitionTimer = Timer(const Duration(seconds: 4), () { if (mounted) _goToNextQuestion(); });
      }
    } else {
      setState(() {
        _isAnimating = true;
        currentState.status = 'failed';
      });
      _audioPlayer.play(AssetSource('sounds/error.mp3'));
      if (provider.autoNextQuestion) {
        _transitionTimer = Timer(const Duration(seconds: 4), () { if (mounted) _goToNextQuestion(); });
      }
    }
  }

  void _goToNextQuestionManual() {
    if (_isAnimating) {
      _transitionTimer?.cancel();
      _audioPlayer.stop();
      _confettiController.stop();
    }
    _goToNextQuestion();
  }

  void _showFinishConfirmationDialog() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: provider.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 10),
            Text(provider.t('finish_test_q'), style: const TextStyle(color: Color(0xFF395B6F), fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(provider.t('finish_test_desc'), style: const TextStyle(fontSize: 16)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(provider.t('continue_test'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(ctx);
              _calculateAndFinish();
            },
            child: Text(provider.t('finish'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showExtendTestDialog() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    int bonusCount = shuffledData.length - currentLimit;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
            backgroundColor: provider.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            title: Text("${provider.t('you_completed')} $currentLimit ${provider.t('questions')}", textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF395B6F), fontWeight: FontWeight.bold)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            content: Text("${provider.t('extend_test_desc1')}\n($bonusCount ${provider.t('questions')}) ${provider.t('extend_test_desc2')}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              SizedBox(
                width: double.maxFinite,
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(provider.t('finish_test'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                          onPressed: () { Navigator.pop(ctx); _calculateAndFinish(); }
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D3146), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(provider.t('complete_challenge'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              currentLimit = shuffledData.length;
                              currentIndex++;
                              _isAnimating = false;
                            });
                          }
                      ),
                    ),
                  ],
                ),
              )
            ]
        )
    );
  }

  void _goToNextQuestion() {
    if (questionStates[currentIndex].status == 'unanswered') {
      questionStates[currentIndex].status = 'skipped';
    }

    if (currentIndex == currentLimit - 1 && currentLimit < shuffledData.length) {
      _showExtendTestDialog();
    } else if (currentIndex < currentLimit - 1) {
      setState(() {
        currentIndex++;
        _isAnimating = false;
      });
    } else {
      _calculateAndFinish();
    }
  }

  void _goToPrevQuestion() {
    if (currentIndex > 0) {
      setState(() {
        if (_isAnimating) {
          _transitionTimer?.cancel();
          _audioPlayer.stop();
          _confettiController.stop();
        }
        currentIndex--;
        _isAnimating = false;
      });
    }
  }

  void _calculateAndFinish() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 300));

    double scorePerQuestion = 100 / currentLimit;
    double finalScore = 0.0;

    for (int i = 0; i < currentLimit; i++) {
      if (questionStates[i].status == 'correct') {
        finalScore += scorePerQuestion;
      }
    }
    int roundedScore = finalScore.round();
    if (roundedScore > 100) roundedScore = 100;

    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => TestResultScreen(
          score: roundedScore,
          testData: widget.testData,
          testType: 'selection',
          categoryType: widget.categoryType,
        )
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;
    const Color primaryDark = Color(0xFF0D3146);
    final Color textColor = isDark ? Colors.white : primaryDark;

    SelectionQuestionState currentState = questionStates[currentIndex];
    List<Map<String, dynamic>> currentOptions = optionsList[currentIndex];

    bool isSentence = widget.categoryType == 'sentences';
    bool isName = isSentence && shuffledData[currentIndex].containsKey('type') && shuffledData[currentIndex]['type'] == 'name';

    String correctLabel = shuffledData[currentIndex]['label'].toString();

    Widget topWidget;
    if (isSentence) {
      Widget imageWidget;
      if (isName) {
        List<String> letters = shuffledData[currentIndex]['letters'].toString().split(',');
        imageWidget = Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: primaryDark, width: 3),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: letters.map((l) {
                if (l == ' ') return const SizedBox(width: 15);
                String imgName = l;
                if (l == 'أ') imgName = 'ا';
                if (l == 'هـ') imgName = 'ه';
                return Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                          'assets/images/learning/letters_cropped/$imgName.jpg',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: primaryDark.withOpacity(0.5))
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      } else {
        imageWidget = Container(
          decoration: BoxDecoration(border: Border.all(color: primaryDark, width: 3), borderRadius: BorderRadius.circular(15), color: Colors.white),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              // 🟢 التعديل هنا للصورة العلوية
              'assets/images/learning/${widget.categoryType}/${shuffledData[currentIndex]['image']}',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 50, color: primaryDark.withOpacity(0.5)),
            ),
          ),
        );
      }
      topWidget = Flexible(child: imageWidget);
    } else {
      topWidget = Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF122C3D) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: primaryDark, width: 2),
        ),
        child: Text(
          "${provider.t('where_is_sign')} ( $correctLabel ) ؟",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
      );
    }

    Widget topSection = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 26),
          color: currentIndex > 0 ? (isDark ? Colors.white : primaryDark) : Colors.grey,
          onPressed: currentIndex > 0 ? _goToPrevQuestion : null,
        ),
        Expanded(child: topWidget), // 🟢 الحل الخاص بتجنب خطأ Overflow هنا
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 26),
          color: isDark ? Colors.white : primaryDark,
          onPressed: _goToNextQuestionManual,
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("${provider.t('question')} ${currentIndex + 1}/$currentLimit", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _showFinishConfirmationDialog,
            child: Text(provider.t('finish'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Column(
              key: ValueKey<int>(currentIndex),
              children: [
                const SizedBox(height: 15),

                isSentence
                    ? Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: topSection))
                    : Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: topSection),

                if (isSentence) ...[
                  const SizedBox(height: 20),
                  Text(
                    provider.t('which_option_matches'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ] else ...[
                  const SizedBox(height: 40),
                ],

                if (isSentence) const SizedBox(height: 20),

                Expanded(
                  flex: isSentence ? 1 : 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: isSentence ? 2.2 : 0.85,
                        ),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          final option = currentOptions[index];

                          String optionIdentifier = isSentence ? option['label'].toString() : option['image'].toString();
                          bool isSelected = currentState.selectedAnswer == optionIdentifier;
                          bool isCorrectOption = optionIdentifier == (isSentence ? shuffledData[currentIndex]['label'].toString() : shuffledData[currentIndex]['image'].toString());

                          Color borderColor = isDark ? (isSentence ? const Color(0xFF395B6F) : Colors.transparent) : Colors.grey.shade300;
                          Color bgColor = isSentence ? (isDark ? const Color(0xFF122C3D) : Colors.white) : Colors.white;
                          Color textBtnColor = textColor;
                          Widget? statusIcon;
                          Color overlayColor = Colors.transparent;

                          if (currentState.status != 'unanswered') {
                            if (isCorrectOption) {
                              borderColor = Colors.green;
                              if (isSentence) bgColor = Colors.green.withOpacity(0.15);
                              else overlayColor = Colors.green.withOpacity(0.3);
                              textBtnColor = Colors.green;
                              statusIcon = const Icon(Icons.check_circle, color: Colors.green, size: 28);
                            } else if (isSelected || currentState.status == 'skipped') {
                              borderColor = Colors.red;
                              if (isSentence) bgColor = Colors.red.withOpacity(0.15);
                              else overlayColor = Colors.red.withOpacity(0.3);
                              textBtnColor = Colors.red;
                              statusIcon = const Icon(Icons.cancel, color: Colors.red, size: 28);
                            }
                          }

                          return GestureDetector(
                            onTap: () => _checkAnswer(optionIdentifier),
                            child: Container(
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: borderColor, width: (isSelected || isCorrectOption || currentState.status == 'skipped') ? (isSentence ? 3 : 4) : 2),
                              ),
                              child: isSentence
                                  ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (statusIcon != null) ...[statusIcon, const SizedBox(width: 8)],
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: FittedBox( // 🟢 الحل الخاص بتجنب خطأ Overflow هنا
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          option['label'].toString(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textBtnColor),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                                  : Stack(
                                fit: StackFit.expand,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Center(
                                        child: Image.asset(
                                          // 🟢 التعديل هنا لخيارات الصور السفلية
                                          'assets/images/learning/${widget.categoryType}/${option['image']}',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (overlayColor != Colors.transparent)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: overlayColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  if (statusIcon != null)
                                    Center(
                                      child: Container(
                                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                        child: statusIcon,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}