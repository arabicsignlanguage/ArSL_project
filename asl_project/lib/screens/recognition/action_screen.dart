import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:screen_protector/screen_protector.dart'; // إضافة: مكتبة حماية الشاشة
import '../../main.dart';
import '../../providers/app_provider.dart';

class ActionScreen extends StatefulWidget {
  final String mode;
  const ActionScreen({super.key, required this.mode});

  @override
  State<ActionScreen> createState() => _ActionScreenState();
}

class _ActionScreenState extends State<ActionScreen> with SingleTickerProviderStateMixin {
  CameraController? controller;
  bool cameraActive = false;

  late FlutterVision vision;
  bool isModelLoaded = false;
  bool isDetecting = false;
  bool isProcessing = false;

  bool isSwitchingModel = false;

  List<Map<String, dynamic>> yoloResults = [];
  CameraImage? cameraImage;

  String potentialLabel = "";
  int frameStabilityCounter = 0;
  bool isCoolingDown = false;
  Timer? _cooldownTimer;

  int _lastProcessTime = 0;

  bool isFrontCamera = false;
  Timer? _noHandTimer;
  int _noHandSeconds = 0;
  String _guidanceMessageKey = "";
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _showSavedMessageOverlay = false;
  bool _showFlipPhoneMessage = false;
  late AnimationController _animationController;

  String currentActiveModel = "";
  bool isWaitingForAge = false;
  String? firstAgeDigit;
  Timer? _ageTimer;
  double _ageProgress = 1.0;

  // متغيرات الزوم
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _baseZoomLevel = 1.0;

  final Map<String, String> arabicLettersMap = {
    'ain': 'ع', 'al': 'ال', 'aleff': 'أ', 'bb': 'ب', 'dal': 'د', 'dha': 'ظ',
    'dhad': 'ض', 'fa': 'ف', 'gaaf': 'ق', 'ghain': 'غ', 'ha': 'هـ', 'haa': 'ح',
    'jeem': 'ج', 'kaaf': 'ك', 'khaa': 'خ', 'la': 'لا', 'laam': 'ل', 'meem': 'م',
    'nun': 'ن', 'ra': 'ر', 'saad': 'ص', 'seen': 'س', 'sheen': 'ش', 'ta': 'ت',
    'taa': 'ط', 'thaa': 'ث', 'thal': 'ذ', 'toot': 'ة', 'waw': 'و', 'ya': 'ي',
    'yaa': 'ى', 'zay': 'ز'
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

  final List<String> wholeWords = ['أنا', 'اسمي', 'عمري', 'أحبك', 'غاضب', 'سعيد', 'آسف'];

  String recognizedText = "";
  String recognizedTrans = "";
  final TextEditingController replyController = TextEditingController();
  String replyTrans = "";

  final Color primaryDark = const Color(0xFF0D3146);
  final Color primaryLight = const Color(0xFF395B6F);
  final Color accentColor = const Color(0xFF958979);

  Timer? _loadingTimer;
  int _dotCount = 0;

  String _lastSavedCamText = "";
  String _lastSavedCamTrans = "";
  String _lastSavedReplyText = "";
  String _lastSavedReplyTrans = "";
  bool _isCameraTapped = false;
  bool _isCameraLoading = false;

  @override
  void initState() {
    super.initState();
    currentActiveModel = widget.mode;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark));
    vision = FlutterVision();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff(); // إضافة: السماح بالتقاط الشاشة عند الخروج من الصفحة
    _animationController.dispose();
    _loadingTimer?.cancel();
    _noHandTimer?.cancel();
    _ageTimer?.cancel();
    _cooldownTimer?.cancel();
    _audioPlayer.dispose();

    if (controller != null && controller!.value.isStreamingImages) {
      try { controller!.stopImageStream(); } catch (_) {}
    }
    controller?.dispose();

    vision.closeYoloModel();
    replyController.dispose();
    super.dispose();
  }

  String _getYearsWord(String ageStr) {
    String engNumStr = ageStr
        .replaceAll('٠', '0').replaceAll('١', '1').replaceAll('٢', '2')
        .replaceAll('٣', '3').replaceAll('٤', '4').replaceAll('٥', '5')
        .replaceAll('٦', '6').replaceAll('٧', '7').replaceAll('٨', '8')
        .replaceAll('٩', '9');

    int age = int.tryParse(engNumStr) ?? 0;

    if (age == 0) return "";
    if (age == 1) return "سنة";
    if (age == 2) return "سنتين";
    if (age >= 3 && age <= 10) return "سنوات";
    return "سنة";
  }

  Future<void> _switchModelDynamically(String newModelTarget) async {
    if (isSwitchingModel) return;

    setState(() {
      isSwitchingModel = true;
      isModelLoaded = false;
      yoloResults.clear();
      potentialLabel = "";
      frameStabilityCounter = 0;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      await vision.closeYoloModel();

      String modelPath = newModelTarget == 'numbers' ? 'assets/models/numbers_model.tflite' : 'assets/models/sentences_model.tflite';
      String labelPath = newModelTarget == 'numbers' ? 'assets/models/numbers_labels.txt' : 'assets/models/sentences_labels.txt';

      await vision.loadYoloModel(
          modelPath: modelPath,
          labels: labelPath,
          modelVersion: "yolov8",
          numThreads: 4,
          useGpu: true
      );

      if (mounted) {
        setState(() {
          currentActiveModel = newModelTarget;
          isModelLoaded = true;
          isSwitchingModel = false;
        });
      }
    } catch (e) {
      debugPrint("⚠️ خطأ في تبديل النموذج: $e");
      if (mounted) setState(() => isSwitchingModel = false);
    }
  }

  void _startAgeTimer() {
    int totalMs = 20000;
    int tick = 50;
    int elapsed = 0;

    _ageTimer?.cancel();
    _ageTimer = Timer.periodic(Duration(milliseconds: tick), (timer) {
      if (!mounted) { timer.cancel(); return; }

      elapsed += tick;
      setState(() {
        _ageProgress = 1.0 - (elapsed / totalMs);
      });

      if (elapsed >= totalMs) {
        timer.cancel();
        setState(() {
          String yearsWord = _getYearsWord(firstAgeDigit!);
          recognizedText += " $yearsWord ";
          isWaitingForAge = false;
          firstAgeDigit = null;
        });
        startCoolDown(durationMs: 2000);
        _switchModelDynamically('sentences');
      }
    });
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) return;

    if (!isModelLoaded) {
      String modelPath = 'assets/models/letters_model.tflite';
      String labelPath = 'assets/models/letters_labels.txt';
      String yoloVersion = "yolov8";

      if (currentActiveModel == 'numbers') {
        modelPath = 'assets/models/numbers_model.tflite';
        labelPath = 'assets/models/numbers_labels.txt';
      } else if (currentActiveModel == 'sentences') {
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
        _isCameraLoading = false;
      });
      ScreenProtector.preventScreenshotOn(); // إضافة: منع التقاط الشاشة لأن الكاميرا فتحت
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
    _ageTimer?.cancel();

    CameraController? oldController = controller;
    controller = null;

    setState(() {
      cameraActive = false;
      isDetecting = false;
      _isCameraLoading = false;
    });
    ScreenProtector.preventScreenshotOff(); // إضافة: السماح بالتقاط الشاشة لأن الكاميرا انغلقت

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
      if (!mounted || !isDetecting || !cameraActive || isCoolingDown) return;
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

        if (isSwitchingModel) return;

        int currentTime = DateTime.now().millisecondsSinceEpoch;

        if (isProcessing && currentTime - _lastProcessTime > 1500) {
          isProcessing = false;
        }

        if (!isProcessing) {
          if (currentTime - _lastProcessTime > 250) {
            isProcessing = true;
            _lastProcessTime = currentTime;
            cameraImage = image;
            yoloOnFrame(image);
          }
        }
      });
    } catch (_) {}
  }

  Future<void> yoloOnFrame(CameraImage image) async {
    if (!mounted || !isModelLoaded || isCoolingDown || isSwitchingModel) {
      isProcessing = false;
      return;
    }
    try {
      double currentConf = currentActiveModel == 'sentences' ? 0.05 : 0.01;
      double currentIou = currentActiveModel == 'sentences' ? 0.95 : 0.50;

      final result = await vision.yoloOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height, imageWidth: image.width,
        iouThreshold: currentIou,
        confThreshold: currentConf,
        classThreshold: currentConf,
      );

      if (mounted && !isSwitchingModel) {
        if (result.isNotEmpty) {
          _noHandSeconds = 0;
          if (_guidanceMessageKey.isNotEmpty) setState(() => _guidanceMessageKey = "");

          bool foundValid = false;
          Map<String, dynamic>? bestDetection;
          double bestConfidence = -1.0;

          for (var res in result) {
            final String label = res['tag'];
            final double confidence = res['box'][4];

            // =======================================================🟢 بداية الفلترة (Filtering)
            bool isHallucination = true;

            if (currentActiveModel == 'sentences') {
              if (!arabicSentencesMap.containsKey(label)) continue;
              if (label == 'Anger') isHallucination = confidence < 0.62; // كلمة: غاضب
              else if (label == 'Happy') isHallucination = confidence < 0.21; // كلمة: سعيد
              else if (label == 'Sorry') isHallucination = confidence < 0.23; // كلمة: آسف
              else if (label == 'my age') isHallucination = confidence < 0.83; // كلمة: عمري
              else if (label == 'love you') isHallucination = confidence < 0.84; // كلمة: أحبك
              else if (label == 'my name') isHallucination = confidence < 0.75; // كلمة: اسمي
              else if (label == 'I') isHallucination = confidence < 0.71; // كلمة: أنا
              else if (['0', '1', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '2', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '3', '30', '4', '5', '6', '7', '8', '9', 'ya'].contains(label)) {

                                                                         //الخلفيه                    الاماميه
                if (label == 'ya') isHallucination = isFrontCamera ? confidence < 0.89 : confidence < 0.89; // حرف ي (توحيد الدقة 0.89)

                else if (label == '12') isHallucination = confidence < 0.85; // حرف خ
                else if (label == '0') isHallucination = confidence < 0.77; // حرف ع
                else if (label == '4' || label == '11') isHallucination = confidence < 0.70; // 4: حرف ض ، 11: حرف ك
                else if (label == '27') isHallucination = confidence < 0.78; // حرف و
                else if (label == '10' || label == '19' || label == '28') isHallucination = confidence < 0.65; // 10: حرف ج ، 19: حرف ص ، 28: حرف ى (الألف المقصورة)
                else if (label == '8') isHallucination = confidence < 0.82; // حرف ح

                else if (label == '14') isHallucination = confidence < 0.05; // حرف ل

                else if (label == '16') isHallucination = confidence < 0.45; // حرف ن

                else if (label == '22') isHallucination = confidence < 0.37; // حرف ط

                else if (label == '13' || label == '17' || label == '20' || label == '21' || label == '23' || label == '24' || label == '29' || label == '30') isHallucination = confidence < 0.35; // 13: لا ، 17: ق ، 20: س ، 21: ش ، 23: ت ، 24: ة ، 29: ظ ، 30: ز
                else if (label == '9') isHallucination = confidence < 0.30; // حرف هـ
                else if (label == '15') isHallucination = confidence < 0.25; // حرف م
                else if (label == '5' ) isHallucination = confidence < 0.5; // حرف د
                else if (label == '25') isHallucination = confidence < 0.12; // حرف ذ
                else if (label == '7') isHallucination = confidence < 0.40; // حرف غ
                else if (label == '6') isHallucination = confidence < 0.55; // حرف ف
                else if (label == '2') isHallucination = confidence < 0.05; // حرف أ
                else if (label == '3' || label == '26' || label == '18' || label == '1') isHallucination = confidence < 0.10; // 3: حرف ب ، 26: حرف ث ، 18: حرف ر ، 1: ال
                else isHallucination = confidence < 0.35;
              } else {
                isHallucination = confidence < 0.60;

              }
            }
            else if (currentActiveModel == 'numbers' || currentActiveModel == 'letters') {
              if (currentActiveModel == 'letters') {
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
              } else if (currentActiveModel == 'numbers') {
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
            // 🟢 نهاية الفلترة (Filtering)======================================
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

    if (currentActiveModel == 'letters') {
      if (['bb', 'dal', 'thaa', 'ra', 'ha', 'al', 'aleff', 'kaaf'].contains(currentLabel)) {
        framesNeeded = 2;
      } else if (currentLabel == 'khaa') {
        framesNeeded = 5;
      } else if (['dhad', 'laam'].contains(currentLabel)) {
        framesNeeded = 4;
      } else {
        framesNeeded = 3;
      }

    } else if (currentActiveModel == 'numbers') {
      if (currentLabel == '8') {
        framesNeeded = 1;
      } else if (['4', '5'].contains(currentLabel)) {
        framesNeeded = 3;
      } else {
        framesNeeded = 2;
      }
    } else if (currentActiveModel == 'sentences') {
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
      bool ageJustFinished = (currentActiveModel == 'numbers' && isWaitingForAge && firstAgeDigit != null);
      addConfirmedResult(currentLabel);
      startCoolDown(durationMs: ageJustFinished ? 2000 : 1500);
    }
  }

  Future<void> _playDetectionFeedback() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (!provider.enableAlerts) return;

    if (provider.enableSound) {
      bool shouldPlaySound = isFrontCamera ? provider.soundFrontCam : provider.soundBackCam;
      if (shouldPlaySound) { try { await _audioPlayer.play(AssetSource('sounds/one_drop.mp3')); } catch (_) {} }
    }

    if (provider.enableVib) {
      bool shouldVibrate = isFrontCamera ? provider.vibFrontCam : provider.vibBackCam;
      if (shouldVibrate) {
        try { bool? hasVib = await Vibration.hasVibrator(); if (hasVib == true) Vibration.vibrate(duration: 80); } catch (_) {}
      }
    }
  }

  void startCoolDown({int durationMs = 1500}) {
    if (mounted) {
      _playDetectionFeedback();
      setState(() { isCoolingDown = true; yoloResults.clear(); frameStabilityCounter = 0; potentialLabel = ""; });
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer(Duration(milliseconds: durationMs), () {
        if (mounted) setState(() => isCoolingDown = false);
      });
    }
  }

  void addConfirmedResult(String label) {
    if (!mounted) return;
    setState(() {

      if (currentActiveModel == 'numbers' && isWaitingForAge) {
        String arabicNumber = arabicNumbersMap[label] ?? label;

        if (firstAgeDigit == null) {
          firstAgeDigit = arabicNumber;
          recognizedText = "$recognizedText $arabicNumber";
          _startAgeTimer();
        } else {
          _ageTimer?.cancel();
          recognizedText = recognizedText.substring(0, recognizedText.length - (firstAgeDigit!.length + 1));
          String combinedAge = "$arabicNumber$firstAgeDigit";

          String yearsWord = _getYearsWord(combinedAge);
          recognizedText += " $combinedAge $yearsWord ";

          isWaitingForAge = false;
          firstAgeDigit = null;
          startCoolDown(durationMs: 2000);
          _switchModelDynamically('sentences');
        }
        recognizedTrans = "";
        return;
      }

      if (currentActiveModel == 'letters') {
        String arabicLetter = arabicLettersMap[label] ?? label;
        if (recognizedText.isEmpty) { recognizedText = arabicLetter; } else { recognizedText = "$recognizedText ، $arabicLetter"; }
      }
      else if (currentActiveModel == 'numbers') {
        String arabicNumber = arabicNumbersMap[label] ?? label;
        if (recognizedText.isEmpty) { recognizedText = arabicNumber; } else { recognizedText = "$recognizedText ، $arabicNumber"; }
      }
      else if (currentActiveModel == 'sentences') {
        String arabicSentenceText = arabicSentencesMap[label] ?? label;

        if (label == '2') {
          if (recognizedText.isEmpty || recognizedText.endsWith(" ")) arabicSentenceText = 'أ';
          else arabicSentenceText = 'ا';
        }

        if (label == 'my age') {
          if (recognizedText.isNotEmpty && !recognizedText.endsWith(" ")) { recognizedText += " "; }
          recognizedText += arabicSentenceText;

          isWaitingForAge = true;
          firstAgeDigit = null;
          _ageProgress = 1.0;
          _switchModelDynamically('numbers');
          recognizedTrans = "";
          return;
        }

        if (wholeWords.contains(arabicSentenceText)) {
          if (recognizedText.isNotEmpty && !recognizedText.endsWith(" ")) {
            recognizedText += " ";
          }
          recognizedText += "$arabicSentenceText ";
        } else {
          recognizedText += arabicSentenceText;
        }
      }

      // -----------------------------------------------------------------
      // التعديل المطلوب: تشكيل اسم اللَّه وإضافة مسافة دائماً بعد كلمة عبد
      // -----------------------------------------------------------------
      recognizedText = recognizedText.replaceAll('الله', 'اللَّه');
      recognizedText = recognizedText.replaceAll(RegExp(r'عبد(?!\s)'), 'عبد ');

      recognizedTrans = "";
    });
  }

  void _saveData(AppProvider provider) {
    if (recognizedText.trim().isEmpty && replyController.text.trim().isEmpty) return;
    String safeCamTrans = recognizedTrans == provider.t('conn_error') ? "" : recognizedTrans;
    String safeReplyTrans = replyTrans == provider.t('conn_error') ? "" : replyTrans;
    if (recognizedText == _lastSavedCamText && safeCamTrans == _lastSavedCamTrans && replyController.text == _lastSavedReplyText && safeReplyTrans == _lastSavedReplyTrans) return;

    provider.addToHistory(camText: recognizedText, camTrans: safeCamTrans, replyText: replyController.text, replyTrans: safeReplyTrans);
    _lastSavedCamText = recognizedText; _lastSavedCamTrans = safeCamTrans; _lastSavedReplyText = replyController.text; _lastSavedReplyTrans = safeReplyTrans;

    setState(() { _showSavedMessageOverlay = true; });
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() { _showSavedMessageOverlay = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fieldLabelColor = isDark ? Colors.tealAccent : primaryDark;
    final Color fieldTextColor = isDark ? Colors.white : primaryDark;
    final Color fieldBorderColor = isDark ? primaryLight : Colors.grey.shade300;

    Widget screenContent = SafeArea(
      child: Column(
        children: [
          Expanded(flex: isFrontCamera ? 90 : 80, child: _buildCameraArea(isDark, provider)),
          Expanded(flex: isFrontCamera ? 10 : 20, child: _buildTextFieldsArea(provider, isDark, fieldLabelColor, fieldTextColor, fieldBorderColor)),
          if (isFrontCamera) const SizedBox(height: 35),
        ],
      ),
    );

    if (isFrontCamera) {
      return RotatedBox(
        quarterTurns: 2,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: Text(_getModeTitle(provider)),
            actions: [IconButton(icon: const Icon(Icons.save), onPressed: () => _saveData(provider))],
          ),
          body: screenContent,
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_getModeTitle(provider)),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: () => _saveData(provider))],
      ),
      body: screenContent,
    );
  }

  Widget _buildCameraArea(bool isDark, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: primaryLight, width: 2), borderRadius: BorderRadius.circular(15)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: cameraActive && controller != null && controller!.value.isInitialized
                ? _buildLiveCameraStack(provider)
                : (cameraActive
                ? Center(child: CircularProgressIndicator(color: primaryLight))
                : _buildStartCameraPlaceholder(isDark, provider)),
          ),
          if (_showSavedMessageOverlay)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: AnimatedOpacity(
                  opacity: _showSavedMessageOverlay ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(30)),
                    child: Text(provider.t('saved'), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveCameraStack(AppProvider provider) {
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

        if (!isCoolingDown && isModelLoaded) ...displayBoxesAroundRecognizedObjects(MediaQuery.of(context).size),

        if (isWaitingForAge)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: AnimatedOpacity(
                opacity: isWaitingForAge ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber, width: 1.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cake, color: Colors.amber, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            // 🟢 بداية ترجمة الإطارات (Frames/Widgets)
                            firstAgeDigit == null ? (provider.t('enter_age') == 'enter_age' ? "أدخل العمر..." : provider.t('enter_age')) : (provider.t('age_wait') == 'age_wait' ? "العمر ($firstAgeDigit) .. انتظر للإنهاء أو أضف رقماً" : "${provider.t('age')} ($firstAgeDigit) .. ${provider.t('wait_to_finish')}"),
                            // 🟢 نهاية ترجمة الإطارات (Frames/Widgets)
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (firstAgeDigit != null) ...[
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 100,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: _ageProgress,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                              minHeight: 2,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),

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
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _animationController.value * math.pi,
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

        if (_guidanceMessageKey.isNotEmpty && !isCoolingDown && !_showFlipPhoneMessage && !isWaitingForAge)
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
              child: Text(provider.t(_guidanceMessageKey), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
          ),

        if (isCoolingDown && !isWaitingForAge) const Center(child: Icon(Icons.timer, size: 50, color: Colors.white54)),

        Positioned(
          top: 10, left: 10,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _flipCamera,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                child: AnimatedRotation(
                  turns: isFrontCamera ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.cameraswitch, color: Colors.black87, size: 18),
                ),
              ),
            ),
          ),
        ),

        Positioned(
          top: 10, right: 10,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _stopCamera, borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                child: const Icon(Icons.close, color: Colors.black87, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartCameraPlaceholder(bool isDark, AppProvider provider) {
    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isCameraTapped = true),
        onTapUp: (_) {
          setState(() {
            _isCameraTapped = false;
            _isCameraLoading = true;
          });
          _initCamera();
        },
        onTapCancel: () => setState(() => _isCameraTapped = false),
        child: AnimatedScale(
          scale: _isCameraTapped ? 0.85 : 1.0, duration: const Duration(milliseconds: 150),
          child: AnimatedOpacity(
            opacity: (_isCameraTapped || _isCameraLoading) ? 0.6 : 1.0, duration: const Duration(milliseconds: 150),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // تعديل: الأيقونة رمادية، وتصبح كحلي غامق عند الضغط
                Icon(Icons.camera_alt, size: 60, color: (_isCameraTapped || _isCameraLoading) ? primaryDark : Colors.grey),
                const SizedBox(height: 10),
                Text(provider.t('tap_start'), style: TextStyle(color: isDark ? Colors.white70 : primaryDark, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldsArea(AppProvider provider, bool isDark, Color fieldLabelColor, Color fieldTextColor, Color fieldBorderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        children: [
          _buildCompactPremiumField(
            title: provider.t('detected'),
            isReadOnly: true,
            textValue: recognizedText,
            translationValue: recognizedTrans,
            isActive: cameraActive,
            idPrefix: 'recog',
            provider: provider,
            fieldLabelColor: fieldLabelColor,
            fieldTextColor: fieldTextColor,
            fieldBorderColor: fieldBorderColor,
            isDark: isDark,
            onDelete: () => setState(() {
              recognizedText = "";
              recognizedTrans = "";
              if (isWaitingForAge || currentActiveModel == 'numbers') {
                isWaitingForAge = false;
                firstAgeDigit = null;
                _ageTimer?.cancel();
                if (widget.mode == 'sentences') {
                  _switchModelDynamically('sentences');
                }
              }
            }),
            onTranslate: () async { if (recognizedTrans.isNotEmpty) { setState(() => recognizedTrans = ""); } else if (recognizedText.isNotEmpty) { final trans = await provider.translateText(recognizedText); setState(() => recognizedTrans = trans); } },
          ),

          if (!isFrontCamera) ...[
            const SizedBox(height: 10),
            _buildCompactPremiumField(
              title: provider.t('reply'), isReadOnly: false, controller: replyController, translationValue: replyTrans, isActive: true, idPrefix: 'reply', provider: provider, fieldLabelColor: fieldLabelColor, fieldTextColor: fieldTextColor, fieldBorderColor: fieldBorderColor, isDark: isDark,
              onDelete: () => setState(() { replyController.clear(); replyTrans = ""; }),
              onTranslate: () async { if (replyTrans.isNotEmpty) { setState(() => replyTrans = ""); } else if (replyController.text.isNotEmpty) { final trans = await provider.translateText(replyController.text); setState(() => replyTrans = trans); } },
              onChanged: (val) { setState(() {}); },
            ),
          ]
        ],
      ),
    );
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    // 🟢 بداية الإطارات (Frames / Bounding Boxes)==========================================
    if (yoloResults.isEmpty || cameraImage == null) return [];
    double factorX = screen.width / (cameraImage!.height);
    double factorY = screen.height / (cameraImage!.width);

    var validResults = yoloResults.where((result) {
      String tag = result['tag'];
      if (currentActiveModel == 'sentences' && !arabicSentencesMap.containsKey(tag)) return false;
      if (currentActiveModel == 'numbers' && !arabicNumbersMap.containsKey(tag)) return false;
      if (currentActiveModel == 'letters' && !arabicLettersMap.containsKey(tag)) return false;
      return true;
    }).toList();

    List<Widget> frames = validResults.map((result) {
      String tag = result['tag'];
      String displayedTag = tag;

      if (currentActiveModel == 'letters') {
        displayedTag = arabicLettersMap[tag] ?? tag;
      } else if (currentActiveModel == 'numbers') {
        displayedTag = arabicNumbersMap[tag] ?? tag;
      } else if (currentActiveModel == 'sentences') {
        displayedTag = arabicSentencesMap[tag] ?? tag;
      }

      double left = result["box"][0] * factorX; double top = result["box"][1] * factorY;
      double width = (result["box"][2] - result["box"][0]) * factorX; double height = (result["box"][3] - result["box"][1]) * factorY;

      return Positioned(
        left: left, top: top, width: width, height: height,
        child: Container(
          decoration: BoxDecoration(borderRadius: const BorderRadius.all(Radius.circular(10.0)), border: Border.all(color: Colors.green, width: 2.0)),
        ),
      );
    }).toList();

    return frames;
    // 🟢 نهاية الإطارات (Frames / Bounding Boxes)================================
  }

  Widget _buildCompactPremiumField({
    required String title, required bool isReadOnly, required String translationValue, required bool isActive, required String idPrefix, required AppProvider provider, required Color fieldLabelColor, required Color fieldTextColor, required Color fieldBorderColor, required bool isDark, required VoidCallback onDelete, required VoidCallback onTranslate, String textValue = "", TextEditingController? controller, Function(String)? onChanged,
  }) {
    bool isTextArabic(String text) => RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    String getAudioLang(String text) { return text.trim().isEmpty ? 'en' : (isTextArabic(text) ? 'ar' : (provider.currentLang == 'ar' ? 'en' : provider.currentLang)); }

    TextStyle hintStyle = TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey, fontSize: 11, fontWeight: FontWeight.normal);

    Widget textWidget;
    if (isReadOnly) {
      if (textValue.isNotEmpty) {
        textWidget = Text(textValue, style: TextStyle(fontSize: provider.translatedTextSize, color: fieldTextColor, fontWeight: FontWeight.w600));
      } else if (!isActive) {
        // 🟢 بداية ترجمة الإطارات (Frames/Widgets)
        textWidget = Text(provider.t('waiting'), style: hintStyle);
        // 🟢 نهاية ترجمة الإطارات (Frames/Widgets)
      } else {
        textWidget = Row(
          children: [
            // 🟢 بداية ترجمة الإطارات (Frames/Widgets)
            Text(provider.t('recognizing'), style: hintStyle),
            // 🟢 نهاية ترجمة الإطارات (Frames/Widgets)
            SizedBox(width: 20, child: Text(List.filled(_dotCount, '.').join(), style: hintStyle)),
          ],
        );
      }
    } else {
      textWidget = TextField(controller: controller, enabled: isActive, onChanged: onChanged, minLines: 1, maxLines: 2, style: TextStyle(fontSize: provider.translatedTextSize, color: fieldTextColor), decoration: InputDecoration(hintText: provider.t('type_reply'), hintStyle: hintStyle, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: title, labelStyle: TextStyle(color: isActive ? fieldLabelColor : Colors.grey, fontWeight: FontWeight.bold, fontSize: 14), floatingLabelBehavior: FloatingLabelBehavior.always, contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isActive ? fieldLabelColor : fieldBorderColor, width: isActive ? 1.5 : 1.2)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: fieldLabelColor, width: 1.5)), filled: true, fillColor: Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.volume_up, size: 24), color: provider.currentPlayingId == '${idPrefix}_orig' ? Colors.blue : ((isReadOnly ? textValue : controller?.text ?? "").isNotEmpty ? fieldLabelColor : Colors.grey), onPressed: (isReadOnly ? textValue : controller?.text ?? "").isNotEmpty ? () => provider.speak(isReadOnly ? textValue : controller?.text ?? "", '${idPrefix}_orig', lang: getAudioLang(isReadOnly ? textValue : controller?.text ?? "")) : null),
                      const SizedBox(width: 8),
                      Expanded(child: textWidget),
                      IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.g_translate, size: 22), color: translationValue.isNotEmpty ? Colors.blue : Colors.grey, onPressed: (isReadOnly ? textValue : controller?.text ?? "").isNotEmpty ? onTranslate : null),
                    ],
                  ),
                  if (translationValue.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.record_voice_over, size: 17), color: provider.currentPlayingId == '${idPrefix}_trans' ? Colors.blue : accentColor, onPressed: () => provider.speak(translationValue, '${idPrefix}_trans', lang: getAudioLang(translationValue))),
                        const SizedBox(width: 8),
                        Expanded(child: Text(translationValue, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey, fontStyle: FontStyle.italic, height: 1.0))),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.only(top: 10.0, right: 4.0), child: InkWell(onTap: onDelete, borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.all(4.0), child: Icon(Icons.delete_outline, color: Colors.red[400], size: 22)))),
      ],
    );
  }

  String _getModeTitle(AppProvider provider) {
    switch (widget.mode) {
      case 'letters': return provider.t('trans_letters');
      case 'numbers': return provider.t('trans_numbers');
      default: return provider.t('trans_sentences');
    }
  }
}