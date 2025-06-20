/**
 * Sherlock - AI-Powered Deepfake Video Detection App
 * 
 * Application constants including API endpoints, file constraints,
 * error messages, and configuration values.
 */

class AppConstants {
  // App Information
  static const String appName = 'Sherlock';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-Powered Deepfake Video Detection';

  // API Configuration
  // IMPORTANT: For mobile simulators/emulators, you need to use your machine's IP address
  // To find your IP address:
  // - Mac/Linux: Run "ifconfig | grep 'inet ' | grep -v 127.0.0.1 | head -1"
  // - Windows: Run "ipconfig" and look for IPv4 Address
  // 
  // Platform-specific URLs:
  // - iOS Simulator: Use your machine's IP address (e.g., http://192.168.1.61:8000)
  // - Android Emulator: Use http://10.0.2.2:8000 (maps to host machine)
  // - Physical device: Use your machine's IP address on same network
  // - Web browser: Use http://localhost:8000
  static const String baseUrl = 'http://localhost:8000';
  static const String apiVersion = '/api/v1';
  
  // API Endpoints
  static const String uploadEndpoint = '/api/v1/upload';
  static const String resultsEndpoint = '/api/v1/results';
  static const String healthEndpoint = '/api/v1/health';
  static const String modelsEndpoint = '/api/v1/models';
  static const String taskEndpoint = '/api/v1/tasks';

  // File Constraints
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB
  static const int maxVideoDuration = 300; // 5 minutes in seconds
  static const List<String> supportedVideoFormats = [
    'mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv', '3gp'
  ];

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 800);

  // Confidence Thresholds
  static const double highConfidenceThreshold = 0.8;
  static const double mediumConfidenceThreshold = 0.6;
  static const double lowConfidenceThreshold = 0.4;

  // Error Messages
  static const String networkError = 'Network connection failed. Please check your internet connection.';
  static const String serverError = 'Server error occurred. Please try again later.';
  static const String fileNotFoundError = 'File not found or has been moved.';
  static const String invalidFileFormatError = 'Invalid file format. Please select a supported video file.';
  static const String fileTooLargeError = 'File size exceeds the maximum limit of 100MB.';
  static const String videoDurationError = 'Video duration exceeds the maximum limit of 5 minutes.';
  static const String unknownError = 'An unexpected error occurred. Please try again.';
  static const String uploadFailedError = 'Upload failed. Please check your file and try again.';
  static const String processingFailedError = 'Video processing failed. Please try again with a different file.';

  // Success Messages
  static const String uploadSuccessMessage = 'Video uploaded successfully!';
  static const String processingCompleteMessage = 'Analysis complete!';

  // Model Information
  static const Map<String, ModelInfo> models = {
    'xception': ModelInfo(
      name: 'XceptionNet',
      description: 'High accuracy model for general deepfake detection',
      accuracy: 0.94,
      inferenceTime: 'Medium',
    ),
    'mesonet': ModelInfo(
      name: 'MesoNet',
      description: 'Lightweight model for real-time inference',
      accuracy: 0.89,
      inferenceTime: 'Fast',
    ),
  };

  // Storage Keys
  static const String themeKey = 'theme_mode';
  static const String uploadHistoryKey = 'upload_history';
  static const String settingsKey = 'app_settings';
  static const String apiUrlKey = 'api_url';

  // Request Timeouts
  static const Duration uploadTimeout = Duration(minutes: 10);
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration downloadTimeout = Duration(minutes: 5);

  // Polling Configuration
  static const Duration pollingInterval = Duration(seconds: 2);
  static const int maxPollingAttempts = 150; // 5 minutes max
}

class ModelInfo {
  final String name;
  final String description;
  final double accuracy;
  final String inferenceTime;

  const ModelInfo({
    required this.name,
    required this.description,
    required this.accuracy,
    required this.inferenceTime,
  });
}

/// Result status enumeration
enum ResultStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

/// Detection result enumeration
enum DetectionResult {
  real,
  fake,
  uncertain,
}

/// Theme mode enumeration
enum AppThemeMode {
  light,
  dark,
  system,
}



/// Processing status enumeration
enum ProcessingStatus {
  pending,
  extractingFrames,
  analyzingFrames,
  aggregatingResults,
  completed,
  failed,
}

/// Environment-specific configuration
class EnvironmentConfig {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: AppConstants.baseUrl,
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isTesting => environment == 'testing';

  /// Get the appropriate API URL based on environment
  static String get effectiveApiUrl {
    if (isDevelopment) {
      return AppConstants.baseUrl;
    } else if (isProduction) {
      return apiUrl; // Use environment variable in production
    } else {
      return 'http://192.168.1.61:8000'; // Testing - use machine IP
    }
  }
}

/// Platform-aware API configuration
class ApiConfig {
  static List<String> _possibleUrls = [
    'http://localhost:8000',     // Mac/Windows Desktop - FIRST PRIORITY
    'http://127.0.0.1:8000',     // Alternative localhost
    'http://192.168.1.61:8000',  // iOS Simulator / Physical device  
    'http://10.0.2.2:8000',      // Android Emulator
  ];

  /// Get the appropriate base URL based on the platform and environment
  static String getBaseUrl() {
    // For Mac desktop, return localhost first
    // The API service will test multiple URLs if this fails
    return _possibleUrls[0];
  }
  
  /// Get all possible URLs for testing
  static List<String> getAllPossibleUrls() {
    return _possibleUrls;
  }
  
  /// Update the URL order based on what works
  static void setWorkingUrl(String workingUrl) {
    if (_possibleUrls.contains(workingUrl)) {
      _possibleUrls.remove(workingUrl);
      _possibleUrls.insert(0, workingUrl);
    }
  }
}
