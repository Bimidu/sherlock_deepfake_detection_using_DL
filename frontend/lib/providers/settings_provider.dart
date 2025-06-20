/**
 * Sherlock - AI-Powered Deepfake Video Detection App
 * 
 * Settings Provider for managing app settings, preferences,
 * and configuration options.
 */

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  
  // Settings state
  ThemeMode _themeMode = ThemeMode.system;
  String _apiUrl = AppConstants.baseUrl;
  bool _enableNotifications = true;
  bool _enableAnalytics = false;
  bool _saveHistory = true;
  String _preferredModel = 'xception';
  double _maxFileSize = AppConstants.maxFileSize.toDouble();
  int _maxVideoDuration = AppConstants.maxVideoDuration;

  // Getters
  ThemeMode get themeMode => _themeMode;
  String get apiUrl => _apiUrl;
  bool get enableNotifications => _enableNotifications;
  bool get enableAnalytics => _enableAnalytics;
  bool get saveHistory => _saveHistory;
  String get preferredModel => _preferredModel;
  double get maxFileSize => _maxFileSize;
  int get maxVideoDuration => _maxVideoDuration;

  /// Initialize settings from shared preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  /// Load settings from shared preferences
  Future<void> _loadSettings() async {
    // Theme mode
    final themeIndex = _prefs.getInt(AppConstants.themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];

    // API URL
    _apiUrl = _prefs.getString(AppConstants.apiUrlKey) ?? AppConstants.baseUrl;

    // Boolean settings
    _enableNotifications = _prefs.getBool('enable_notifications') ?? true;
    _enableAnalytics = _prefs.getBool('enable_analytics') ?? false;
    _saveHistory = _prefs.getBool('save_history') ?? true;

    // Preferred model
    _preferredModel = _prefs.getString('preferred_model') ?? 'xception';

    // File constraints
    _maxFileSize = _prefs.getDouble('max_file_size') ?? AppConstants.maxFileSize.toDouble();
    _maxVideoDuration = _prefs.getInt('max_video_duration') ?? AppConstants.maxVideoDuration;

    notifyListeners();
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt(AppConstants.themeKey, mode.index);
    notifyListeners();
  }

  /// Set API URL
  Future<void> setApiUrl(String url) async {
    _apiUrl = url;
    await _prefs.setString(AppConstants.apiUrlKey, url);
    notifyListeners();
  }

  /// Set notifications enabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    _enableNotifications = enabled;
    await _prefs.setBool('enable_notifications', enabled);
    notifyListeners();
  }

  /// Set analytics enabled
  Future<void> setAnalyticsEnabled(bool enabled) async {
    _enableAnalytics = enabled;
    await _prefs.setBool('enable_analytics', enabled);
    notifyListeners();
  }

  /// Set save history enabled
  Future<void> setSaveHistoryEnabled(bool enabled) async {
    _saveHistory = enabled;
    await _prefs.setBool('save_history', enabled);
    notifyListeners();
  }

  /// Set preferred model
  Future<void> setPreferredModel(String model) async {
    _preferredModel = model;
    await _prefs.setString('preferred_model', model);
    notifyListeners();
  }

  /// Set max file size
  Future<void> setMaxFileSize(double size) async {
    _maxFileSize = size;
    await _prefs.setDouble('max_file_size', size);
    notifyListeners();
  }

  /// Set max video duration
  Future<void> setMaxVideoDuration(int duration) async {
    _maxVideoDuration = duration;
    await _prefs.setInt('max_video_duration', duration);
    notifyListeners();
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.system;
    _apiUrl = AppConstants.baseUrl;
    _enableNotifications = true;
    _enableAnalytics = false;
    _saveHistory = true;
    _preferredModel = 'xception';
    _maxFileSize = AppConstants.maxFileSize.toDouble();
    _maxVideoDuration = AppConstants.maxVideoDuration;

    // Save to preferences
    await _prefs.setInt(AppConstants.themeKey, _themeMode.index);
    await _prefs.setString(AppConstants.apiUrlKey, _apiUrl);
    await _prefs.setBool('enable_notifications', _enableNotifications);
    await _prefs.setBool('enable_analytics', _enableAnalytics);
    await _prefs.setBool('save_history', _saveHistory);
    await _prefs.setString('preferred_model', _preferredModel);
    await _prefs.setDouble('max_file_size', _maxFileSize);
    await _prefs.setInt('max_video_duration', _maxVideoDuration);

    notifyListeners();
  }

  /// Export settings as JSON
  Map<String, dynamic> exportSettings() {
    return {
      'theme_mode': _themeMode.index,
      'api_url': _apiUrl,
      'enable_notifications': _enableNotifications,
      'enable_analytics': _enableAnalytics,
      'save_history': _saveHistory,
      'preferred_model': _preferredModel,
      'max_file_size': _maxFileSize,
      'max_video_duration': _maxVideoDuration,
    };
  }

  /// Import settings from JSON
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      if (settings.containsKey('theme_mode')) {
        await setThemeMode(ThemeMode.values[settings['theme_mode']]);
      }
      if (settings.containsKey('api_url')) {
        await setApiUrl(settings['api_url']);
      }
      if (settings.containsKey('enable_notifications')) {
        await setNotificationsEnabled(settings['enable_notifications']);
      }
      if (settings.containsKey('enable_analytics')) {
        await setAnalyticsEnabled(settings['enable_analytics']);
      }
      if (settings.containsKey('save_history')) {
        await setSaveHistoryEnabled(settings['save_history']);
      }
      if (settings.containsKey('preferred_model')) {
        await setPreferredModel(settings['preferred_model']);
      }
      if (settings.containsKey('max_file_size')) {
        await setMaxFileSize(settings['max_file_size']);
      }
      if (settings.containsKey('max_video_duration')) {
        await setMaxVideoDuration(settings['max_video_duration']);
      }
    } catch (e) {
      debugPrint('Error importing settings: $e');
      rethrow;
    }
  }

  /// Get theme mode display name
  String getThemeModeDisplayName() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Get model display name
  String getModelDisplayName(String model) {
    return AppConstants.models[model]?.name ?? model.toUpperCase();
  }

  /// Validate API URL
  bool isValidApiUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
} 