import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:confetti/confetti.dart';
import '../../providers/app_provider.dart';
import 'test_result_screen.dart';

class QuestionState {
  int attempts = 0;
  String status = 'unanswered';
  String userAnswer = '';
  String hintText = "";
}

class TestDiscoveryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> testData;
  final String categoryType;
  const TestDiscoveryScreen({super.key, required this.testData, required this.categoryType});

  @override
  State<TestDiscoveryScreen> createState() => _TestDiscoveryScreenState();
}

class _TestDiscoveryScreenState extends State<TestDiscoveryScreen> {
  int currentIndex = 0;
  late List<QuestionState> questionStates;
  late List<Map<String, dynamic>> shuffledData;
  int currentLimit = 0;

  final TextEditingController _answerController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;
  final FocusNode _focusNode = FocusNode();

  bool _isAnimating = false;
  Timer? _transitionTimer;
  bool _showAttemptsEndedOverlay = false;

  @override
  void initState() {
    super.initState();
    _initializeTestData();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
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
    questionStates = List.generate(shuffledData.length, (index) => QuestionState());
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    _answerController.dispose();
    _audioPlayer.dispose();
    _confettiController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _normalizeText(String text) {
    return text.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا');
  }

  void _checkAnswer() async {
    if (_isAnimating || questionStates[currentIndex].status != 'unanswered') return;
    String userAnswer = _answerController.text.trim();
    if (userAnswer.isEmpty) return;

    String correctAnswer = shuffledData[currentIndex]['label'].toString();
    QuestionState currentState = questionStates[currentIndex];

    bool isCorrect = (_normalizeText(userAnswer) == _normalizeText(correctAnswer)) ||
        (correctAnswer == 'هـ' && userAnswer == 'ه') ||
        (correctAnswer == 'ه' && userAnswer == 'هـ');

    final provider = Provider.of<AppProvider>(context, listen: false);

    if (isCorrect) {
      _focusNode.unfocus();
      setState(() {
        _isAnimating = true;
        if (correctAnswer == 'الله') {
          currentState.userAnswer = 'اللَّه';
          _answerController.text = 'اللَّه';
        } else {
          currentState.userAnswer = userAnswer;
        }
        currentState.status = 'correct1';
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
        currentState.attempts++;
        if (currentState.attempts < 3) {
          _answerController.clear();
          currentState.hintText = provider.t('try_again');
          _audioPlayer.play(AssetSource('sounds/error.mp3'));
          _focusNode.requestFocus();
        } else {
          _focusNode.unfocus();
          _isAnimating = true;
          _showAttemptsEndedOverlay = true;
          currentState.status = 'failed';
          currentState.userAnswer = userAnswer;
          _audioPlayer.play(AssetSource('sounds/error.mp3'));
          Vibration.vibrate(duration: 300);

          if (provider.autoNextQuestion) {
            _transitionTimer = Timer(const Duration(seconds: 4), () { if (mounted) _goToNextQuestion(); });
          }
        }
      });
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
                              _answerController.clear();
                              _isAnimating = false;
                              _showAttemptsEndedOverlay = false;
                            });
                            _focusNode.requestFocus();
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
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (questionStates[currentIndex].status == 'unanswered') {
      if (_answerController.text.trim().isEmpty) {
        questionStates[currentIndex].status = 'skipped';
        questionStates[currentIndex].hintText = provider.t('not_answered');
      } else {
        questionStates[currentIndex].userAnswer = _answerController.text;
      }
    }

    if (currentIndex == currentLimit - 1 && currentLimit < shuffledData.length) {
      _showExtendTestDialog();
    } else if (currentIndex < currentLimit - 1) {
      setState(() {
        currentIndex++;
        _answerController.clear();
        _isAnimating = false;
        _showAttemptsEndedOverlay = false;

        if (questionStates[currentIndex].status != 'unanswered') {
          _answerController.text = questionStates[currentIndex].userAnswer;
        } else if (questionStates[currentIndex].userAnswer.isNotEmpty) {
          _answerController.text = questionStates[currentIndex].userAnswer;
        }
      });
      _focusNode.requestFocus();
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
        if (questionStates[currentIndex].status == 'unanswered') {
          questionStates[currentIndex].userAnswer = _answerController.text;
        }
        currentIndex--;
        _answerController.text = questionStates[currentIndex].userAnswer;
        _isAnimating = false;
        _showAttemptsEndedOverlay = false;
      });
      _focusNode.requestFocus();
    }
  }

  void _calculateAndFinish() async {
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 300));

    double scorePerQuestion = 100 / currentLimit;
    double finalScore = 0.0;

    for (int i = 0; i < currentLimit; i++) {
      if (questionStates[i].status.startsWith('correct')) {
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
          testType: 'discovery',
          categoryType: widget.categoryType,
        )
    ));
  }

  Color _getFieldBorderColor(QuestionState state, Color primaryDark) {
    if (state.status == 'unanswered' && state.attempts > 0) return Colors.red;
    if (state.status == 'failed' || state.status == 'skipped') return Colors.red;
    if (state.status.startsWith('correct')) return Colors.green;
    return primaryDark;
  }

  Widget? _getFeedbackIcon(QuestionState state) {
    if (state.status.startsWith('correct')) return _buildCircleIcon(Icons.check, Colors.green);
    if (state.status == 'failed' || (state.status == 'unanswered' && state.attempts == 3)) return _buildCircleIcon(Icons.close, Colors.red);
    return null;
  }

  Widget _buildCircleIcon(IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;
    const Color primaryDark = Color(0xFF0D3146);

    QuestionState currentState = questionStates[currentIndex];
    bool isReadOnly = currentState.status != 'unanswered' || _isAnimating;

    bool isName = shuffledData[currentIndex].containsKey('type') && shuffledData[currentIndex]['type'] == 'name';
    String displayQuestionText = isName ? provider.t('what_is_name') : provider.t('what_does_sign_mean');

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
            // 🟢 التعديل هنا: إرجاع المسار الطبيعي للصور العادية
            'assets/images/learning/${widget.categoryType}/${shuffledData[currentIndex]['image']}',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 50, color: primaryDark.withOpacity(0.5)),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey<int>(currentIndex),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                                "${provider.t('attempts')}: ${currentState.attempts} / 3",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: currentState.attempts == 3 ? Colors.red : (isDark ? Colors.tealAccent : const Color(0xFF395B6F))
                                )
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        key: ValueKey<int>(currentIndex),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(icon: const Icon(Icons.arrow_back_ios, size: 22), color: currentIndex > 0 ? (isDark ? Colors.white : primaryDark) : Colors.grey, onPressed: currentIndex > 0 ? _goToPrevQuestion : null),
                          Flexible(
                            child: imageWidget,
                          ),
                          IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 22), color: isDark ? Colors.white : primaryDark, onPressed: _goToNextQuestionManual),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey<int>(currentIndex),
                      children: [
                        if (_showAttemptsEndedOverlay)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(30)),
                            child: Text(provider.t('attempts_ended'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(displayQuestionText, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : primaryDark)),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _answerController,
                            focusNode: _focusNode,
                            autofocus: true,
                            readOnly: isReadOnly,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              counterText: "",
                              hintText: currentState.hintText,
                              hintStyle: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.bold),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF122C3D) : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 15),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: _getFieldBorderColor(currentState, primaryDark), width: 2)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: _getFieldBorderColor(currentState, primaryDark), width: 2)),
                            ),
                            onSubmitted: (_) { if(!isReadOnly) _checkAnswer(); else _focusNode.requestFocus(); },
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (!isReadOnly)
                          InkWell(
                            onTap: _checkAnswer,
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: primaryDark, borderRadius: BorderRadius.circular(15)),
                              child: const Icon(Icons.send, color: Colors.white, size: 28),
                            ),
                          )
                        else if (_getFeedbackIcon(currentState) != null)
                          _getFeedbackIcon(currentState)!,
                      ],
                    ),
                  ),
                ],
              ),
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