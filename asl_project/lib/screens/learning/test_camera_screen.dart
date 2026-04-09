import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:confetti/confetti.dart';
import 'package:screen_protector/screen_protector.dart'; // تمت إضافة استدعاء مكتبة حماية الشاشة
import '../../main.dart';
import '../../providers/app_provider.dart';
import 'test_result_screen.dart';

class CameraQuestionState {
  int attempts = 0;
  String status = 'unanswered';
  String detectedLabel = '';
  int nameProgress = 0;
}

class TestCameraScreen extends StatefulWidget {
  final List<Map<String, dynamic>> testData;
  final String mode;

  const TestCameraScreen({super.key, required this.testData, required this.mode});

  @override
  State<TestCameraScreen> createState() => _TestCameraScreenState();
}

class _TestCameraScreenState extends State<TestCameraScreen> with TickerProviderStateMixin {
  int currentIndex = 0;
  late List<CameraQuestionState> questionStates;
  late List<Map<String, dynamic>> shuffledData;
  int currentLimit = 0;

  CameraController? controller;
  bool cameraActive = false;
  late FlutterVision vision;
  bool isModelLoaded = false;
  bool isDetecting = false;
  bool isProcessing = false;
  List<Map<String, dynamic>> yoloResults = [];
  CameraImage? cameraImage;

  bool isFrontCamera = true;
  Timer? _noHandTimer;
  int _noHandSeconds = 0;
  String _guidanceMessageKey = "";

  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;
  Timer? _transitionTimer;
  Timer? _gracePeriodTimer;
  bool _isAnimating = false;
  bool _showWrongFeedback = false;
  bool _showAttemptsEndedOverlay = false;
  bool _isGracePeriod = false;
  bool _isDialogShowing = false;

  int _lastProcessTime = 0;
  String potentialLabel = "";
  int frameStabilityCounter = 0;
  bool isCoolingDown = false;

  bool _showFlipPhoneMessage = false;
  late AnimationController _flipAnimationController;
  Timer? _loadingTimer;
  int _dotCount = 0;

  // متغيرات الزوم
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _baseZoomLevel = 1.0;

  final Color gracePeriodColor = const Color(0xFFD4AC0D);
  final Color camIconColor = const Color(0xFF958979);

  final Map<String, String> arabicLettersMap = {
    'ain': 'ع', 'al': 'ال', 'aleff': 'أ', 'bb': 'ب', 'dal': 'د', 'dha': 'ظ',
    'dhad': 'ض', 'fa': 'ف', 'gaaf': 'ق', 'ghain': 'غ', 'ha': 'هـ', 'haa': 'ح',
    'jeem': 'ج', 'kaaf': 'ك', 'khaa': 'خ', 'la': 'لا', 'laam': 'ل', 'meem': 'م',
    'nun': 'ن', 'ra': 'ر', 'saad': 'ص', 'seen': 'س', 'sheen': 'ش', 'ta': 'ت',
    'taa': 'ط', 'thaa': 'ث', 'thal': 'ذ', 'toot': 'ة', 'waw': 'و', 'ya': 'ي',
    'yaa': 'ي',
    'zay': 'ز'
  };

  final Map<String, String> arabicNumbersMap = {
    '0': '٠', '1': '١', '2': '٢', '3': '٣', '4': '٤',
    '5': '٥', '6': '٦', '7': '٧', '8': '٨', '9': '٩'
  };

  final Map<String, String> arabicSentencesMap = {
    '0': 'ع', '1': 'ال', '10': 'ج', '11': 'ك', '12': 'خ',
    '13': 'لا', '14': 'ل', '15': 'م', '16': 'ن', '17': 'ق',
    '18': 'ر', '19': 'ص', '2': 'أ', '20': 'س', '21': 'ش',
    '22': 'ط', '23': 'ت', '24': 'ة', '25': 'ذ', '26': 'ث',
    '27': 'و', '28': 'ى', '29': 'ظ', '3': 'ب', '30': 'ز',
    '4': 'ض', '5': 'د', '6': 'ف', '7': 'غ', '8': 'ح',
    '9': 'ه', 'Anger': 'غاضب', 'Happy': 'سعيد', 'I': 'أنا',
    'Sorry': 'آسف', 'love you': 'أحبك', 'my age': 'عمري',
    'my name': 'اسمي', 'ya': 'ي'
  };

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark));
    _initializeTestData();
    vision = FlutterVision();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _flipAnimationController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _initCamera();
    _startGracePeriod();
  }

  void _initializeTestData() {
    if (widget.mode == 'sentences') {
      currentLimit = 25;
      var allData = List<Map<String, dynamic>>.from(widget.testData);
      var words = allData.where((e) => e['type'] == 'word').toList();
      var names = allData.where((e) => e['type'] == 'name').toList();

      // تحديد الأسماء المركبة لتظهر هنا فقط
      var compound1 = names.firstWhere((e) => e['label'] == 'عبد الرحمن', orElse: () => names.first);
      var compound2 = names.firstWhere((e) => e['label'] == 'عبد اللَّه', orElse: () => names.first);
      var compound3 = names.firstWhere((e) => e['label'] == 'عبد الملك', orElse: () => names.first);

      var requiredWords = words.where((e) => ['أنا', 'اسمي', 'عمري', 'غاضب', 'سعيد', 'آسف', 'أحبك'].contains(e['label'])).toList();

      names.remove(compound1);
      names.remove(compound2);
      names.remove(compound3);
      names.shuffle();

// المرحلة الأولى (25 سؤال): كلمات أساسية + اسم مركب واحد فقط + أسماء عشوائية
      var first25 = <Map<String, dynamic>>[];
      first25.addAll(requiredWords);
      first25.add(compound1); // عبد الرحمن فقط

      int needed = 25 - first25.length;
      if (needed > names.length) needed = names.length;
      first25.addAll(names.take(needed));
      first25.shuffle();
      names.removeRange(0, needed);

      // الزيادة (10 أسئلة): الاسم المركب الثاني + أسماء جديدة تماماً + كلمات مراجعة
      var extra10 = <Map<String, dynamic>>[];
      extra10.add(compound2); // مركب 1
      extra10.add(compound3); // مركب 2

      // أخذ 4 أسماء جديدة
      extra10.addAll(names.take(4));

      // أخذ 4 كلمات عشوائية للمراجعة
      var reviewWords = List<Map<String, dynamic>>.from(words)..shuffle();
      extra10.addAll(reviewWords.take(4));

      extra10.shuffle();
      shuffledData = [...first25, ...extra10];

    } else if (widget.mode == 'numbers') {
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
    questionStates = List.generate(shuffledData.length, (index) => CameraQuestionState());
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff(); // تمت الإضافة لإلغاء منع التقاط الشاشة عند الخروج

    _transitionTimer?.cancel();
    _gracePeriodTimer?.cancel();
    _noHandTimer?.cancel();
    _loadingTimer?.cancel();
    _audioPlayer.dispose();
    _confettiController.dispose();
    _flipAnimationController.dispose();

    if (controller != null && controller!.value.isStreamingImages) {
      try { controller!.stopImageStream(); } catch (_) {}
    }
    controller?.dispose();
    vision.closeYoloModel();
    super.dispose();
  }

  void _startGracePeriod() {
    setState(() {
      _isGracePeriod = true;
      yoloResults.clear();
      frameStabilityCounter = 0;
      potentialLabel = "";
    });

    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _isGracePeriod = false;
        });
      }
    });
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) return;

    if (!isModelLoaded) {
      String modelPath = 'assets/models/letters_model.tflite';
      String labelPath = 'assets/models/letters_labels.txt';
      String yoloVersion = "yolov8";

      if (widget.mode == 'numbers') {
        modelPath = 'assets/models/numbers_model.tflite';
        labelPath = 'assets/models/numbers_labels.txt';
      } else if (widget.mode == 'sentences') {
        modelPath = 'assets/models/sentences_model.tflite';
        labelPath = 'assets/models/sentences_labels.txt';
      }

      try {
        await vision.loadYoloModel(
            modelPath: modelPath,
            labels: labelPath,
            modelVersion: yoloVersion,
            numThreads: 4,
            useGpu: true
        );
        isModelLoaded = true;
      } catch (e) {
        debugPrint("❌ النموذج غير موجود: $e");
      }
    }

    final camDirection = isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back;
    final selectedCamera = cameras.firstWhere((c) => c.lensDirection == camDirection, orElse: () => cameras.first);

    controller = CameraController(
      selectedCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await controller!.initialize();

    try {
      if (isFrontCamera) { await controller!.lockCaptureOrientation(DeviceOrientation.portraitDown); }
      else { await controller!.lockCaptureOrientation(DeviceOrientation.portraitUp); }
    } catch (_) {}

    try {
      _maxAvailableZoom = await controller!.getMaxZoomLevel();
      _minAvailableZoom = await controller!.getMinZoomLevel();
      _currentZoomLevel = _minAvailableZoom;
    } catch (_) {}

    if (mounted) {
      setState(() {
        cameraActive = true;
        if (isFrontCamera) {
          _showFlipPhoneMessage = true;
          Timer(const Duration(seconds: 7), () { if (mounted) setState(() => _showFlipPhoneMessage = false); });
        }
      });
      await ScreenProtector.preventScreenshotOn(); // تمت الإضافة لمنع التقاط الشاشة عند اشتغال الكاميرا
      _loadingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (mounted) setState(() => _dotCount = (_dotCount + 1) % 4);
      });
      startDetection();
    }
  }

  void _flipCamera() async {
    if (cameras.length < 2) return;

    _loadingTimer?.cancel();
    _noHandTimer?.cancel();

    CameraController? oldController = controller;
    controller = null;

    setState(() {
      cameraActive = false;
      isDetecting = false;
    });

    if (oldController != null) {
      try {
        if (oldController.value.isStreamingImages) {
          await oldController.stopImageStream();
        }
      } catch (_) {}
      await oldController.dispose();
    }

    setState(() {
      isFrontCamera = !isFrontCamera;
      if (isFrontCamera) {
        _showFlipPhoneMessage = true;
        Timer(const Duration(seconds: 7), () { if (mounted) setState(() => _showFlipPhoneMessage = false); });
      } else {
        _showFlipPhoneMessage = false;
      }
    });

    _initCamera();
  }

  void _stopCamera() async {
    _loadingTimer?.cancel();
    _noHandTimer?.cancel();

    CameraController? oldController = controller;
    controller = null;

    setState(() {
      cameraActive = false;
      isDetecting = false;
    });

    await ScreenProtector.preventScreenshotOff(); // تمت الإضافة لإلغاء المنع عند توقف الكاميرا

    if (oldController != null) {
      try {
        if (oldController.value.isStreamingImages) {
          await oldController.stopImageStream();
        }
      } catch (_) {}
      await oldController.dispose();
    }
  }

  void _startNoHandTimer() {
    _noHandTimer?.cancel(); _noHandSeconds = 0; _guidanceMessageKey = "";
    _noHandTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !isDetecting || !cameraActive || isCoolingDown || _showWrongFeedback || _isAnimating || _isGracePeriod || _isDialogShowing) return;
      if (!isModelLoaded) return;

      if (yoloResults.isEmpty) {
        _noHandSeconds++;
        if (_noHandSeconds >= 10) { setState(() => _guidanceMessageKey = 'show_hand'); }
        else if (_noHandSeconds >= 5) { setState(() => _guidanceMessageKey = 'move_phone'); }
      }
    });
  }

  void startDetection() async {
    if (!isModelLoaded || isDetecting || controller == null) return;
    setState(() => isDetecting = true);
    _startNoHandTimer();

    try {
      await controller!.startImageStream((image) {
        if (isProcessing || isCoolingDown || _isAnimating || _showWrongFeedback || _isGracePeriod || _isDialogShowing) return;

        int currentTime = DateTime.now().millisecondsSinceEpoch;
        if (currentTime - _lastProcessTime > 250) {
          isProcessing = true;
          _lastProcessTime = currentTime;
          cameraImage = image;
          yoloOnFrame(image);
        }
      });
    } catch (_) {}
  }

  Future<void> yoloOnFrame(CameraImage image) async {
    if (!mounted || !isModelLoaded || isCoolingDown || _isAnimating || _showWrongFeedback || _isGracePeriod || _isDialogShowing) { isProcessing = false; return; }
    try {
      double currentConf = widget.mode == 'sentences' ? 0.05 : 0.01;
      double currentIou = widget.mode == 'sentences' ? 0.95 : 0.50;

      final result = await vision.yoloOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height, imageWidth: image.width,
        iouThreshold: currentIou,
        confThreshold: currentConf,
        classThreshold: currentConf,
      );

      if (mounted) {
        if (result.isNotEmpty) {
          _noHandSeconds = 0;
          if (_guidanceMessageKey.isNotEmpty) setState(() => _guidanceMessageKey = "");

          bool foundValid = false;
          Map<String, dynamic>? bestDetection;
          double bestConfidence = -1.0;

          bool isName = shuffledData[currentIndex].containsKey('type') && shuffledData[currentIndex]['type'] == 'name';

          for (var res in result) {
            final String label = res['tag'];
            final double confidence = res['box'][4];
            bool isHallucination = true;

            if (widget.mode == 'sentences') {
              if (!arabicSentencesMap.containsKey(label)) continue;

              if (isName && ['Anger', 'Happy', 'Sorry', 'my age', 'my name', 'I', 'love you'].contains(label)) {
                continue;
              }

              if (label == 'Anger') isHallucination = confidence < 0.62;
              else if (label == 'Happy') isHallucination = confidence < 0.21;
              else if (label == 'Sorry') isHallucination = confidence < 0.23;
              else if (label == 'my age') isHallucination = confidence < 0.83;
              else if (label == 'love you') isHallucination = confidence < 0.84;
              else if (label == 'my name') isHallucination = confidence < 0.75;
              else if (label == 'I') isHallucination = confidence < 0.71;
              else if (['0', '1', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '2', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '3', '30', '4', '5', '6', '7', '8', '9', 'ya'].contains(label)) {
                if (label == 'ya') isHallucination = isFrontCamera ? confidence < 0.89 : confidence < 0.89;
                else if (label == '12') isHallucination = confidence < 0.85;
                else if (label == '0') isHallucination = confidence < 0.77;
                else if (label == '4' || label == '11') isHallucination = confidence < 0.70;
                else if (label == '27') isHallucination = confidence < 0.78;
                else if (label == '10' || label == '19' || label == '28') isHallucination = confidence < 0.65;
                else if (label == '8') isHallucination = confidence < 0.82;
                else if (label == '14') isHallucination = confidence < 0.05;
                else if (label == '16') isHallucination = confidence < 0.45;
                else if (label == '22') isHallucination = confidence < 0.37;
                else if (label == '13' || label == '17' || label == '20' || label == '21' || label == '23' || label == '24' || label == '29' || label == '30') isHallucination = confidence < 0.35;
                else if (label == '9') isHallucination = confidence < 0.30;
                else if (label == '15') isHallucination = confidence < 0.25;
                else if (label == '5' ) isHallucination = confidence < 0.5;
                else if (label == '25') isHallucination = confidence < 0.12;
                else if (label == '7') isHallucination = confidence < 0.40;
                else if (label == '6') isHallucination = confidence < 0.55;
                else if (label == '2') isHallucination = confidence < 0.05;
                else if (label == '3' || label == '26' || label == '18' || label == '1') isHallucination = confidence < 0.10;
                else isHallucination = confidence < 0.35;
              } else {
                isHallucination = confidence < 0.60;
              }
            }
            else if (widget.mode == 'numbers' || widget.mode == 'letters') {
              if (widget.mode == 'letters') {
                if (!arabicLettersMap.containsKey(label)) continue;
                if (isFrontCamera) {
                  if (label == 'dhad' || label == 'laam' || label == 'khaa') isHallucination = confidence < 0.85;
                  else if (label == 'kaaf') isHallucination = confidence < 0.82;
                  else if (label == 'yaa') isHallucination = confidence < 0.74;
                  else if (label == 'ain' || label == 'haa') isHallucination = confidence < 0.65;
                  else if (label == 'waw') isHallucination = confidence < 0.50;
                  else if (label == 'meem') isHallucination = confidence < 0.20;
                  else if (label == 'aleff') isHallucination = confidence < 0.05;
                  else if (label == 'bb' || label == 'dal' || label == 'thaa' || label == 'ra' || label == 'ha' || label == 'al' || label == 'ya') isHallucination = confidence < 0.10;
                  else isHallucination = confidence < 0.35;
                } else {
                  if (label == 'dhad' || label == 'laam' || label == 'khaa') isHallucination = confidence < 0.85;
                  else if (label == 'kaaf') isHallucination = confidence < 0.82;
                  else if (label == 'yaa' || label == 'ain' || label == 'haa') isHallucination = confidence < 0.65;
                  else if (label == 'waw') isHallucination = confidence < 0.50;
                  else if (label == 'meem') isHallucination = confidence < 0.25;
                  else if (label == 'ghain') isHallucination = confidence < 0.20;
                  else if (label == 'bb' || label == 'dal' || label == 'thaa' || label == 'aleff' || label == 'ra' || label == 'ha' || label == 'al' || label == 'ya') isHallucination = confidence < 0.10;
                  else isHallucination = confidence < 0.35;
                }
              } else if (widget.mode == 'numbers') {
                if (!arabicNumbersMap.containsKey(label)) continue;

                if (label == '0') isHallucination = confidence < 0.59;
                else if (label == '2') isHallucination = confidence < 0.75;
                else if (label == '9') isHallucination = confidence < 0.26;
                else if (label == '5') isHallucination = confidence < 0.20;
                else if (label == '4') isHallucination = confidence < 0.18;
                else if (label == '1') isHallucination = confidence < 0.25;
                else if (label == '3') isHallucination = confidence < 0.11;
                else if (label == '8') isHallucination = confidence < 0.03;
                else isHallucination = confidence < 0.15;
              }
            }

            if (!isHallucination && confidence > bestConfidence) {
              bestConfidence = confidence;
              bestDetection = res;
            }
          }

          if (bestDetection != null) {
            foundValid = true;
            processDetectionLogic([bestDetection!]);
            setState(() => yoloResults = [bestDetection!]);
          } else {
            processDetectionLogic([]);
            if (yoloResults.isNotEmpty) setState(() => yoloResults.clear());
          }
        } else {
          processDetectionLogic([]);
          if (yoloResults.isNotEmpty) setState(() => yoloResults.clear());
        }
      }
    } catch (e) {
      debugPrint("⚠️ Frame Error: $e");
    } finally {
      isProcessing = false;
    }
  }

  void processDetectionLogic(List<Map<String, dynamic>> detections) {
    if (detections.isEmpty) { frameStabilityCounter = 0; potentialLabel = ""; return; }
    final topResult = detections.first;
    final String currentLabel = topResult['tag'];

    if (currentLabel == potentialLabel) { frameStabilityCounter++; }
    else { potentialLabel = currentLabel; frameStabilityCounter = 1; }

    int framesNeeded = 3;

    if (widget.mode == 'letters') {
      if (['bb', 'dal', 'thaa', 'ra', 'ha', 'al', 'aleff', 'kaaf'].contains(currentLabel)) {
        framesNeeded = 2;
      } else if (currentLabel == 'khaa') {
        framesNeeded = 5;
      } else if (['dhad', 'laam'].contains(currentLabel)) {
        framesNeeded = 4;
      } else {
        framesNeeded = 3;
      }

    } else if (widget.mode == 'numbers') {
      if (currentLabel == '8') {
        framesNeeded = 1;
      } else if (['4', '5'].contains(currentLabel)) {
        framesNeeded = 3;
      } else {
        framesNeeded = 2;
      }
    } else if (widget.mode == 'sentences') {
      if (currentLabel == '5' || currentLabel == '14') {
        framesNeeded = 1;
      } else if (['11', '12', '16'].contains(currentLabel)) {
        framesNeeded = 3;
      } else if (['love you', '6', '7'].contains(currentLabel)) {
        framesNeeded = 3;
      } else if (currentLabel == '4') {
        framesNeeded = 2;
      } else {
        framesNeeded = 2;
      }
    }

    if (frameStabilityCounter >= framesNeeded) {
      _checkAnswer(currentLabel);
      frameStabilityCounter = 0;
    }
  }

  void _checkAnswer(String detectedTag) {
    if (_isAnimating || _showWrongFeedback || isCoolingDown || _isGracePeriod) return;

    String expectedLabel = shuffledData[currentIndex]['label'].toString();
    bool isName = shuffledData[currentIndex].containsKey('type') && shuffledData[currentIndex]['type'] == 'name';

    String detectedArabicText = "";
    if (widget.mode == 'letters') {
      detectedArabicText = arabicLettersMap[detectedTag] ?? detectedTag;
    } else if (widget.mode == 'numbers') {
      detectedArabicText = arabicNumbersMap[detectedTag] ?? detectedTag;
    } else if (widget.mode == 'sentences') {
      detectedArabicText = arabicSentencesMap[detectedTag] ?? detectedTag;
    }

    CameraQuestionState currentState = questionStates[currentIndex];

    if (isName) {
      List<String> targetLetters = shuffledData[currentIndex]['letters'].toString().split(',');

      // تجاوز المسافات إن وجدت تلقائياً
      while (currentState.nameProgress < targetLetters.length && targetLetters[currentState.nameProgress] == ' ') {
        currentState.detectedLabel += ' ';
        currentState.nameProgress++;
      }

      if (currentState.nameProgress >= targetLetters.length) {
        setState(() {
          currentState.detectedLabel = expectedLabel;
        });
        _markCorrectAndProceed(currentState);
        return;
      }

      String currentTargetLetter = targetLetters[currentState.nameProgress];

      if (detectedArabicText == 'أ' && currentTargetLetter == 'ا') detectedArabicText = 'ا';
      if (detectedArabicText == 'ا' && currentTargetLetter == 'أ') detectedArabicText = 'أ';
      if (detectedArabicText == 'ى' && currentTargetLetter == 'ي') detectedArabicText = 'ي';
      if (detectedArabicText == 'ي' && currentTargetLetter == 'ى') detectedArabicText = 'ى';

      if (detectedArabicText == currentTargetLetter ||
          (currentTargetLetter == 'هـ' && detectedArabicText == 'ه') ||
          (currentTargetLetter == 'ه' && detectedArabicText == 'هـ')) {

        setState(() {
          currentState.detectedLabel += detectedArabicText;
          currentState.nameProgress++;
          yoloResults.clear();
          isCoolingDown = true;

          // تجاوز المسافات اللاحقة فوراً للظهور في الشاشة
          while (currentState.nameProgress < targetLetters.length && targetLetters[currentState.nameProgress] == ' ') {
            currentState.detectedLabel += ' ';
            currentState.nameProgress++;
          }
        });

        _audioPlayer.play(AssetSource('sounds/one_drop.mp3'));

        if (currentState.nameProgress == targetLetters.length) {
          setState(() {
            currentState.detectedLabel = expectedLabel;
          });
          _markCorrectAndProceed(currentState);
        } else {
          Timer(const Duration(milliseconds: 1500), () {
            if(mounted) setState(() => isCoolingDown = false);
          });
        }
      } else {
        _handleWrongAttempt(currentState, detectedArabicText, isName: true);
      }
    }
    else {
      setState(() {
        currentState.detectedLabel = detectedArabicText.replaceAll('الله', 'اللَّه');
      });

      bool isCorrect = (detectedArabicText == expectedLabel) ||
          (expectedLabel == 'هـ' && detectedArabicText == 'ه') ||
          (expectedLabel == 'ه' && detectedArabicText == 'هـ');

      if (isCorrect) {
        _markCorrectAndProceed(currentState);
      } else {
        _handleWrongAttempt(currentState, detectedArabicText, isName: false);
      }
    }
  }

  void _markCorrectAndProceed(CameraQuestionState currentState) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    setState(() {
      _isAnimating = true;
      yoloResults.clear();
      if (currentState.attempts == 0) {
        currentState.status = 'correct1';
        // 🟢 الفرقعة للمحاولة الأولى فقط مع حل التعليق
        if (provider.enableConfetti) {
          _confettiController.stop();
          _confettiController.play();
        }
      } else if (currentState.attempts == 1) {
        currentState.status = 'correct2';
      } else {
        currentState.status = 'correct3';
      }
    });

    // 🟢 حل تعليق الصوت ليعمل دائماً عند الإجابة الصحيحة
    _audioPlayer.stop().then((_) => _audioPlayer.play(AssetSource('sounds/success.mp3')));

    if (provider.autoNextQuestion) {
      _transitionTimer = Timer(const Duration(seconds: 4), () { if (mounted) _goToNextQuestion(); });
    }
  }

  void _handleWrongAttempt(CameraQuestionState currentState, String detectedArabicText, {required bool isName}) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    setState(() {
      currentState.attempts++;
      yoloResults.clear();
    });

    if (currentState.attempts < 3) {
      setState(() {
        _showWrongFeedback = true;
        isCoolingDown = true;
        if (!isName || (isName && currentState.nameProgress == 0)) {
          currentState.detectedLabel = detectedArabicText;
        }
      });
      _audioPlayer.play(AssetSource('sounds/error.mp3'));
      Vibration.vibrate(duration: 150);

      Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showWrongFeedback = false;
            isCoolingDown = false;
            if (!isName || (isName && currentState.nameProgress == 0)) {
              currentState.detectedLabel = '';
            }
          });
        }
      });
    } else {
      setState(() {
        currentState.status = 'failed';
        _isAnimating = true;
        _showAttemptsEndedOverlay = true;
        if (!isName || (isName && currentState.nameProgress == 0)) {
          currentState.detectedLabel = detectedArabicText;
        }
      });
      _audioPlayer.play(AssetSource('sounds/error.mp3'));
      Vibration.vibrate(duration: 400);

      if (provider.autoNextQuestion) {
        _transitionTimer = Timer(const Duration(seconds: 4), () { if (mounted) _goToNextQuestion(); });
      }
    }
  }

  void _goToNextQuestionManual() {
    if (_isAnimating || _showWrongFeedback) {
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
      builder: (ctx) => RotatedBox(
        quarterTurns: isFrontCamera ? 2 : 0,
        child: AlertDialog(
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
      ),
    );
  }

  void _showExtendTestDialog() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    setState(() => _isDialogShowing = true);
    int bonusCount = shuffledData.length - currentLimit;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => RotatedBox(
          quarterTurns: isFrontCamera ? 2 : 0,
          child: AlertDialog(
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
                            onPressed: () { Navigator.pop(ctx); setState(() => _isDialogShowing = false); _calculateAndFinish(); }
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
                                _showAttemptsEndedOverlay = false;
                                _isDialogShowing = false;
                              });
                              _startGracePeriod();
                            }
                        ),
                      ),
                    ],
                  ),
                )
              ]
          ),
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
        _showWrongFeedback = false;
        _showAttemptsEndedOverlay = false;
        isCoolingDown = false;
        yoloResults.clear();
      });
      _startGracePeriod();
    } else {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (provider.autoNextQuestion || _isAnimating == false) {
        _calculateAndFinish();
      }
    }
  }

  void _calculateAndFinish() async {
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
        builder: (_) => TestResultScreen(score: roundedScore, testData: widget.testData, testType: 'camera', categoryType: widget.mode)
    ));
  }

  Widget? _getFeedbackIcon(CameraQuestionState state) {
    if (_showWrongFeedback) return const Center(child: Icon(Icons.cancel, size: 100, color: Colors.red));
    if (state.status.startsWith('correct')) return const Center(child: Icon(Icons.check_circle, size: 100, color: Colors.green));
    if (state.status == 'failed') return const Center(child: Icon(Icons.cancel, size: 100, color: Colors.red));
    return null;
  }

  Color _getFieldBorderColor(CameraQuestionState state, bool isDark, Color defaultColor) {
    if (state.status.startsWith('correct')) return Colors.green;
    if (_showWrongFeedback || state.status == 'failed') return Colors.red;
    if (_isGracePeriod) return gracePeriodColor;
    return isDark ? Colors.tealAccent : defaultColor;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryDark = const Color(0xFF0D3146);
    final Color textColor = isDark ? Colors.white : primaryDark;

    CameraQuestionState currentState = questionStates[currentIndex];
    String correctLabel = shuffledData[currentIndex]['label'].toString();
    bool isName = shuffledData[currentIndex].containsKey('type') && shuffledData[currentIndex]['type'] == 'name';

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    Widget screenContent = SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedRotation(
                  turns: isFrontCamera ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: IconButton(
                    icon: Icon(Icons.cameraswitch, color: camIconColor, size: 32),
                    onPressed: _flipCamera,
                    tooltip: provider.t('switch_camera'),
                  ),
                ),
                Text(
                    "${provider.t('attempts')}: ${currentState.attempts} / 3",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: currentState.attempts == 3 ? Colors.red : (isDark ? Colors.tealAccent : const Color(0xFF395B6F))
                    )
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),

          if (_showAttemptsEndedOverlay)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(30)),
              child: Text(provider.t('attempts_ended'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Column(
                    children: [
                      Text(correctLabel == 'الله' ? "${provider.t('make_sign')} ( اللَّه )" : "${provider.t('make_sign')} ( $correctLabel )", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      if (isName) ...[
                        const SizedBox(height: 8),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Wrap(
                            spacing: 4,
                            children: List.generate(
                              shuffledData[currentIndex]['letters'].toString().split(',').length,
                                  (idx) {
                                String letter = shuffledData[currentIndex]['letters'].toString().split(',')[idx];
                                if (letter == ' ') return const SizedBox(width: 15);
                                bool isDone = idx < currentState.nameProgress;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDone ? Colors.green : Colors.transparent,
                                    border: Border.all(color: isDone ? Colors.green : Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(letter, style: TextStyle(color: isDone ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                                );
                              },
                            ),
                          ),
                        )
                      ]
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, size: 22, color: isDark ? Colors.white70 : primaryDark),
                  onPressed: _goToNextQuestionManual,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Expanded(flex: 85, child: _buildCameraArea(isDark, provider)),

          Expanded(
            flex: 15,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: provider.t('detected'),
                  labelStyle: TextStyle(color: _getFieldBorderColor(currentState, isDark, primaryDark), fontWeight: FontWeight.bold),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _getFieldBorderColor(currentState, isDark, primaryDark), width: 2)),
                ),
                child: Center(
                  child: currentState.detectedLabel.isEmpty
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          _isGracePeriod
                              ? provider.t('get_ready')
                              : (currentState.attempts > 0
                              ? provider.t('try_again_recognizing')
                              : provider.t('recognizing')),
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey,
                              fontWeight: FontWeight.normal
                          )
                      ),
                      if (!isCoolingDown || _isGracePeriod)
                        SizedBox(width: 20, child: Text(List.filled(_dotCount, '.').join(), style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey, fontWeight: FontWeight.normal))),
                    ],
                  )
                      : Text(
                    currentState.detectedLabel,
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        // التعديل هنا: لعدم فصل مسافات الكلمة بعد أن يكتمل الاسم ويصبح بالتّشكيل المطلوب
                        letterSpacing: isName && !currentState.detectedLabel.contains('اللَّه') ? 4.0 : 0.0
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          if (isFrontCamera) const SizedBox(height: 35),
        ],
      ),
    );

    return RotatedBox(
      quarterTurns: isFrontCamera ? 2 : 0,
      child: Scaffold(
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
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey<int>(currentIndex),
                child: screenContent,
              ),
            ),
            if (isCoolingDown && !_showWrongFeedback && currentState.status == 'unanswered')
              const Center(child: Icon(Icons.timer, size: 60, color: Colors.white54)),
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
      ),
    );
  }

  Widget _buildCameraArea(bool isDark, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          border: Border.all(
              color: _isGracePeriod ? gracePeriodColor : const Color(0xFF395B6F),
              width: _isGracePeriod ? 3 : 2
          ),
          borderRadius: BorderRadius.circular(15)
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: cameraActive
            ? (controller != null && controller!.value.isInitialized
            ? _buildLiveCameraStack(provider, currentState: questionStates[currentIndex])
            : Center(child: CircularProgressIndicator(color: const Color(0xFF395B6F))))
            : Center(child: CircularProgressIndicator(color: const Color(0xFF395B6F))),
      ),
    );
  }

  Widget _buildLiveCameraStack(AppProvider provider, {required CameraQuestionState currentState}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // إضافة حساس التقريب للكاميرا
        GestureDetector(
          onScaleStart: (details) {
            _baseZoomLevel = _currentZoomLevel;
          },
          onScaleUpdate: (details) async {
            if (controller == null || !controller!.value.isInitialized) return;
            double newZoom = (_baseZoomLevel * details.scale).clamp(_minAvailableZoom, _maxAvailableZoom);
            if (_currentZoomLevel != newZoom) {
              setState(() {
                _currentZoomLevel = newZoom;
              });
              try { await controller!.setZoomLevel(_currentZoomLevel); } catch (_) {}
            }
          },
          child: CameraPreview(controller!),
        ),

        if (!isCoolingDown && isModelLoaded && !_isAnimating && !_showWrongFeedback && !_isGracePeriod) ...displayBoxesAroundRecognizedObjects(MediaQuery.of(context).size),

        if (_showFlipPhoneMessage)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: AnimatedOpacity(
                opacity: _showFlipPhoneMessage ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(provider.t('flip_phone'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _flipAnimationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _flipAnimationController.value * math.pi,
                            child: const Icon(Icons.screen_rotation, color: Colors.white, size: 20),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        if (_guidanceMessageKey.isNotEmpty && !isCoolingDown && !_showFlipPhoneMessage && !_isAnimating && !_showWrongFeedback && !_isGracePeriod)
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
              child: Text(provider.t(_guidanceMessageKey), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
          ),

        if (_isAnimating || _showWrongFeedback)
          _getFeedbackIcon(currentState)!,
      ],
    );
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty || cameraImage == null) return [];
    double factorX = screen.width / (cameraImage!.height);
    double factorY = screen.height / (cameraImage!.width);

    return yoloResults.map((result) {
      double left = result["box"][0] * factorX; double top = result["box"][1] * factorY;
      double width = (result["box"][2] - result["box"][0]) * factorX; double height = (result["box"][3] - result["box"][1]) * factorY;

      return Positioned(
        left: left, top: top, width: width, height: height,
        child: Container(
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10.0)),
              border: Border.all(color: Colors.green, width: 3.0)
          ),
        ),
      );
    }).toList();
  }
}