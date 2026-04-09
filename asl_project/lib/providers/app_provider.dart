import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_translations.dart';

class AppProvider extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  final GoogleTranslator _translator = GoogleTranslator();

  String _currentPlayingId = '';
  String get currentPlayingId => _currentPlayingId;

  final Map<String, String> supportedLanguages = {
    'ar': 'العربية (Arabic)',
    'en': 'English (الإنجليزية)',
    'ja': '日本語 (اليابانية)',
    'zh': '中文 (الصينية)',
    'de': 'Deutsch (الألمانية)',
    'tr': 'Türkçe (التركية)',
    'ko': '한국어 (الكورية)',
    'fr': 'Français (الفرنسية)',
    'es': 'Español (الإسبانية)',
    'ru': 'Русский (الروسية)',
  };

  String _currentLang = 'ar';
  String get currentLang => _currentLang;

  double _speechRate = 0.5;
  double _translatedTextSize = 15.0;
  bool _enableConfetti = true;
  bool _autoNextQuestion = true; // 🟢 الافتراضي مفعل

  double get speechRate => _speechRate;
  double get translatedTextSize => _translatedTextSize;
  bool get enableConfetti => _enableConfetti;
  bool get autoNextQuestion => _autoNextQuestion;

  AppProvider() {
    _initTts();
    _loadHistory();
    _loadSettings();
  }

  String t(String key) {
    return AppTranslations.translations[_currentLang]?[key] ?? AppTranslations.translations['ar']?[key] ?? key;
  }

  void _initTts() {
    _flutterTts.setPitch(1.0);
    _flutterTts.setSpeechRate(_speechRate);
    _flutterTts.setCompletionHandler(() {
      _currentPlayingId = '';
      notifyListeners();
    });
  }

  void changeLanguage(String langCode) {
    _currentLang = langCode;
    _saveSettingsLocally();
    notifyListeners();
  }

  void setSpeechRate(double rate) {
    _speechRate = rate;
    _flutterTts.setSpeechRate(rate);
    _saveSettingsLocally();
    notifyListeners();
  }

  void setTranslatedTextSize(double size) {
    _translatedTextSize = size;
    _saveSettingsLocally();
    notifyListeners();
  }

  void toggleConfetti(bool val) {
    _enableConfetti = val;
    _saveSettingsLocally();
    notifyListeners();
  }

  void toggleAutoNextQuestion(bool val) {
    _autoNextQuestion = val;
    _saveSettingsLocally();
    notifyListeners();
  }

  Future<void> speak(String text, String id, {String? lang}) async {
    if (text.trim().isEmpty) return;

    if (_currentPlayingId == id) {
      await _flutterTts.stop();
      _currentPlayingId = '';
      notifyListeners();
      return;
    }

    await _flutterTts.stop();
    _currentPlayingId = id;
    notifyListeners();
    await _flutterTts.setLanguage(lang ?? _currentLang);
    await _flutterTts.speak(text);
  }

  Future<String> translateText(String text) async {
    if (text.trim().isEmpty) return "";
    try {
      bool isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
      String targetLang = isArabic ? (_currentLang == 'ar' ? 'en' : _currentLang) : 'ar';
      var translation = await _translator.translate(text, to: targetLang);
      return translation.text;
    } catch (e) {
      return t('conn_error');
    }
  }

  final List<Map<String, String>> _history = [];
  List<Map<String, String>> get history => _history;

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString('saved_history');
    if (historyString != null) {
      final List<dynamic> decodedData = jsonDecode(historyString);
      _history.clear();
      for (var item in decodedData) {
        _history.add(Map<String, String>.from(item));
      }
      notifyListeners();
    }
  }

  Future<void> _saveHistoryLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_history);
    await prefs.setString('saved_history', encodedData);
  }

  void addToHistory({required String camText, required String camTrans, required String replyText, required String replyTrans}) {
    if (camText.isEmpty && replyText.isEmpty) return;
    final record = {
      'camText': camText, 'camTrans': camTrans, 'replyText': replyText, 'replyTrans': replyTrans,
      'date': DateFormat('yyyy/MM/dd  |  hh:mm a').format(DateTime.now()),
    };
    _history.insert(0, record);
    _saveHistoryLocally();
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    _saveHistoryLocally();
    notifyListeners();
  }

  void deleteHistoryItem(int index) {
    _history.removeAt(index);
    _saveHistoryLocally();
    notifyListeners();
  }

  bool _isDarkMode = false;
  bool _enableAlerts = true;
  bool _enableSound = true;
  bool _soundFrontCam = false;
  bool _soundBackCam = true;
  bool _enableVib = false;
  bool _vibFrontCam = true;
  bool _vibBackCam = false;

  bool get isDarkMode => _isDarkMode;
  bool get enableAlerts => _enableAlerts;
  bool get enableSound => _enableSound;
  bool get soundFrontCam => _soundFrontCam;
  bool get soundBackCam => _soundBackCam;
  bool get enableVib => _enableVib;
  bool get vibFrontCam => _vibFrontCam;
  bool get vibBackCam => _vibBackCam;

  void toggleTheme(bool val) { _isDarkMode = val; _saveSettingsLocally(); notifyListeners(); }
  void toggleAlerts(bool val) { _enableAlerts = val; _saveSettingsLocally(); notifyListeners(); }
  void toggleSound(bool val) { _enableSound = val; _saveSettingsLocally(); notifyListeners(); }
  void setSoundCams(bool front, bool back) { _soundFrontCam = front; _soundBackCam = back; _saveSettingsLocally(); notifyListeners(); }
  void toggleVib(bool val) { _enableVib = val; _saveSettingsLocally(); notifyListeners(); }
  void setVibCams(bool front, bool back) { _vibFrontCam = front; _vibBackCam = back; _saveSettingsLocally(); notifyListeners(); }

  Future<void> _saveSettingsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark', _isDarkMode);
    await prefs.setString('app_lang', _currentLang);
    await prefs.setBool('enable_alerts', _enableAlerts);
    await prefs.setBool('enable_sound', _enableSound);
    await prefs.setBool('sound_front', _soundFrontCam);
    await prefs.setBool('sound_back', _soundBackCam);
    await prefs.setBool('enable_vib', _enableVib);
    await prefs.setBool('vib_front', _vibFrontCam);
    await prefs.setBool('vib_back', _vibBackCam);
    await prefs.setDouble('speech_rate', _speechRate);
    await prefs.setDouble('text_size', _translatedTextSize);
    await prefs.setBool('enable_confetti', _enableConfetti);
    await prefs.setBool('auto_next_question', _autoNextQuestion);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark') ?? false;
    _currentLang = prefs.getString('app_lang') ?? 'ar';
    _enableAlerts = prefs.getBool('enable_alerts') ?? true;
    _enableSound = prefs.getBool('enable_sound') ?? true;
    _soundFrontCam = prefs.getBool('sound_front') ?? false;
    _soundBackCam = prefs.getBool('sound_back') ?? true;
    _enableVib = prefs.getBool('enable_vib') ?? false;
    _vibFrontCam = prefs.getBool('vib_front') ?? true;
    _vibBackCam = prefs.getBool('vib_back') ?? false;

    _speechRate = prefs.getDouble('speech_rate') ?? 0.5;
    _translatedTextSize = prefs.getDouble('text_size') ?? 15.0;
    _enableConfetti = prefs.getBool('enable_confetti') ?? true;
    _autoNextQuestion = prefs.getBool('auto_next_question') ?? true;

    _flutterTts.setSpeechRate(_speechRate);
    notifyListeners();
  }
}
