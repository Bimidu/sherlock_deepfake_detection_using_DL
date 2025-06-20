/**
 * Video Upload Provider
 * 
 * Manages the state for video upload functionality including
 * file selection, upload progress, and communication with the backend API.
 * 
 * Uses Provider pattern for state management and provides reactive
 * updates to the UI components.
 */

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:logger/logger.dart';

import '../models/upload_result.dart';
import '../utils/logger_widget.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

/// States for video upload process
enum UploadState {
  initial,
  selecting,
  selected,
  uploading,
  completed,
  error,
}

enum UploadStatus {
  idle,
  selecting,
  selected,
  uploading,
  uploaded,
  failed,
}

class VideoUploadProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Logger _logger = UILogger();

  // Current state
  UploadState _state = UploadState.initial;
  
  // File and video information
  File? _selectedFile;
  String? _selectedFileName;
  int? _selectedFileSize;
  VideoPlayerController? _videoController;
  Duration? _videoDuration;
  
  // Upload progress
  double _uploadProgress = 0.0;
  String? _statusMessage;
  
  // Results
  UploadResponse? _uploadResponse;
  String? _errorMessage;
  
  // Selected model
  String _selectedModel = AppConstants.models.keys.first;

  // Getters
  UploadState get state => _state;
  File? get selectedFile => _selectedFile;
  String? get selectedFileName => _selectedFileName;
  int? get selectedFileSize => _selectedFileSize;
  VideoPlayerController? get videoController => _videoController;
  Duration? get videoDuration => _videoDuration;
  double get uploadProgress => _uploadProgress;
  String? get statusMessage => _statusMessage;
  UploadResponse? get uploadResponse => _uploadResponse;
  String? get errorMessage => _errorMessage;
  String get selectedModel => _selectedModel;

  // Computed properties
  bool get hasSelectedFile => _selectedFile != null;
  bool get canUpload => hasSelectedFile && _state != UploadState.uploading;
  bool get isUploading => _state == UploadState.uploading;
  bool get hasError => _state == UploadState.error;
  bool get isCompleted => _state == UploadState.completed;
  
  UploadStatus get status {
    switch (_state) {
      case UploadState.initial:
        return UploadStatus.idle;
      case UploadState.selecting:
        return UploadStatus.selecting;
      case UploadState.selected:
        return UploadStatus.selected;
      case UploadState.uploading:
        return UploadStatus.uploading;
      case UploadState.completed:
        return UploadStatus.uploaded;
      case UploadState.error:
        return UploadStatus.failed;
      default:
        return UploadStatus.idle;
    }
  }
  
  String? get taskId => _uploadResponse?.taskId;
  String? get error => _errorMessage;
  
  String get fileSizeFormatted {
    if (_selectedFileSize == null) return '';
    final mb = _selectedFileSize! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Select a video file from device storage
  Future<bool> selectVideo() async {
    try {
      _setState(UploadState.selecting);
      _setStatusMessage('Selecting video file...');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final fileName = result.files.first.name;
        final fileSize = result.files.first.size;

        // Validate file size
        if (fileSize > AppConstants.maxFileSize) {
          _setError('File too large. Maximum size is ${AppConstants.maxFileSize ~/ (1024 * 1024)} MB.');
          return false;
        }

        // Validate file exists and is accessible
        if (!await file.exists()) {
          _setError('Selected file is not accessible.');
          return false;
        }

        await _setSelectedFile(file, fileName, fileSize);
        _setStatusMessage('Video file selected successfully');
        return true;
      } else {
        _setState(UploadState.initial);
        _setStatusMessage(null);
        return false;
      }
    } catch (e) {
      _logger.e(e.toString());
      _setError('Failed to select video file: ${e.toString()}');
      return false;
    }
  }

  /// Set the selected file and initialize video player
  Future<void> _setSelectedFile(File file, String fileName, int fileSize) async {
    try {
      // Dispose previous video controller
      await _disposeVideoController();

      _selectedFile = file;
      _selectedFileName = fileName;
      _selectedFileSize = fileSize;

      // Initialize video player for preview
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      _videoDuration = _videoController!.value.duration;

      _setState(UploadState.selected);
      notifyListeners();
    } catch (e) {
      _logger.e(e.toString());
      _setError('Failed to process selected video file');
    }
  }

  /// Upload the selected video file
  Future<bool> uploadVideo() async {
    if (!canUpload) return false;

    try {
      _setState(UploadState.uploading);
      _uploadProgress = 0.0;
      _setStatusMessage('Preparing upload...');

      final response = await _apiService.uploadVideo(
        _selectedFile!,
        model: _selectedModel,
      );

      _uploadResponse = response;
      _setState(UploadState.completed);
      _setStatusMessage('Upload completed successfully!');
      _logger.i('Video uploaded successfully: ${response.taskId}');
      
      return true;
    } catch (e) {
      _logger.e(e.toString());
      _setError('Upload failed: ${e.toString()}');
      return false;
    }
  }

  /// Set the selected model for analysis
  void setSelectedModel(String modelName) {
    if (AppConstants.models.containsKey(modelName)) {
      _selectedModel = modelName;
      notifyListeners();
      _logger.d('Selected model changed to: $modelName');
    }
  }
  
  /// Reset the upload state
  void reset() {
    _setState(UploadState.initial);
    _uploadProgress = 0.0;
    _uploadResponse = null;
    _errorMessage = null;
    _setStatusMessage(null);
  }

  /// Clear the selected file and reset state
  Future<void> clearSelection() async {
    await _disposeVideoController();
    _selectedFile = null;
    _selectedFileName = null;
    _selectedFileSize = null;
    _videoDuration = null;
    _uploadProgress = 0.0;
    _uploadResponse = null;
    _errorMessage = null;
    _setState(UploadState.initial);
    _setStatusMessage(null);
  }

  /// Reset upload state to allow retry
  void resetUpload() {
    if (_state == UploadState.error || _state == UploadState.completed) {
      _uploadProgress = 0.0;
      _uploadResponse = null;
      _errorMessage = null;
      _setState(hasSelectedFile ? UploadState.selected : UploadState.initial);
      _setStatusMessage(hasSelectedFile ? 'Ready to upload' : null);
    }
  }

  /// Set error state with message
  void _setError(String message) {
    _errorMessage = message;
    _setState(UploadState.error);
    _setStatusMessage(message);
  }

  /// Set status message
  void _setStatusMessage(String? message) {
    _statusMessage = message;
    notifyListeners();
  }

  /// Set upload state
  void _setState(UploadState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Dispose video controller
  Future<void> _disposeVideoController() async {
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }
  }

  /// Get video thumbnail as bytes
  Future<List<int>?> getVideoThumbnail() async {
    if (_selectedFile == null) return null;
    
    try {
      // This would require video_thumbnail package implementation
      // For now, return null and handle in UI
      return null;
    } catch (e) {
      _logger.e(e.toString());
      return null;
    }
  }

  /// Validate selected file before upload
  bool validateSelectedFile() {
    if (_selectedFile == null) {
      _setError('No file selected');
      return false;
    }

    if (_selectedFileSize != null && _selectedFileSize! > AppConstants.maxFileSize) {
      _setError(AppConstants.fileTooLargeError);
      return false;
    }

    final extension = _selectedFileName?.split('.').last.toLowerCase();
    if (extension == null || !AppConstants.supportedVideoFormats.contains(extension)) {
      _setError(AppConstants.invalidFileFormatError);
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    _disposeVideoController();
    super.dispose();
  }
} 