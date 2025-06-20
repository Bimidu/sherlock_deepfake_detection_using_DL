/**
 * Sherlock - AI-Powered Deepfake Video Detection App
 * 
 * Results Provider for managing detection results state,
 * polling for updates, and handling result data.
 */

import 'package:flutter/material.dart';
import 'dart:async';

import '../models/upload_result.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class ResultsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Current state
  TaskResult? _currentResult;
  bool _isLoading = false;
  String? _error;
  Timer? _pollingTimer;
  int _pollingAttempts = 0;

  // Getters
  TaskResult? get currentResult => _currentResult;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPolling => _pollingTimer?.isActive ?? false;
  double get pollingProgress => _pollingAttempts / AppConstants.maxPollingAttempts;

  /// Start polling for task results
  Future<void> startPolling(String taskId) async {
    debugPrint('Starting polling for task: $taskId');
    
    _error = null;
    _pollingAttempts = 0;
    notifyListeners();

    // Start immediate first check
    await _checkTaskStatus(taskId);
    
    // Start periodic polling if task is still processing
    if (_currentResult?.status == TaskStatus.processing ||
        _currentResult?.status == TaskStatus.uploaded) {
      _startPollingTimer(taskId);
    }
  }

  /// Stop polling
  void stopPolling() {
    debugPrint('Stopping polling');
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _pollingAttempts = 0;
    notifyListeners();
  }

  /// Get result by task ID
  Future<void> getResult(String taskId) async {
    _setLoading(true);
    _error = null;
    
    try {
      final result = await _apiService.getTaskResult(taskId);
      _currentResult = result;
      
      // If still processing, start polling
      if (result.status == TaskStatus.processing ||
          result.status == TaskStatus.uploaded) {
        _startPollingTimer(taskId);
      }
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error getting result: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Start the polling timer
  void _startPollingTimer(String taskId) {
    _pollingTimer?.cancel();
    
    _pollingTimer = Timer.periodic(AppConstants.pollingInterval, (timer) async {
      _pollingAttempts++;
      
      // Check if we've exceeded max attempts
      if (_pollingAttempts >= AppConstants.maxPollingAttempts) {
        timer.cancel();
        _error = 'Polling timeout: Analysis is taking longer than expected';
        notifyListeners();
        return;
      }
      
      await _checkTaskStatus(taskId);
      
      // Stop polling if task is complete or failed
      if (_currentResult?.status == TaskStatus.completed ||
          _currentResult?.status == TaskStatus.failed) {
        timer.cancel();
      }
      
      notifyListeners();
    });
  }

  /// Check task status
  Future<void> _checkTaskStatus(String taskId) async {
    try {
      final result = await _apiService.getTaskResult(taskId);
      _currentResult = result;
    } catch (e) {
      debugPrint('Error checking task status: $e');
      // Don't set error during polling, just log it
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException') ||
        error.toString().contains('HttpException')) {
      return AppConstants.networkError;
    } else if (error.toString().contains('TimeoutException')) {
      return 'Request timeout. Please try again.';
    } else if (error.toString().contains('404')) {
      return 'Task not found. It may have expired.';
    } else if (error.toString().contains('500')) {
      return AppConstants.serverError;
    } else {
      return AppConstants.unknownError;
    }
  }

  /// Clear current result
  void clearResult() {
    stopPolling();
    _currentResult = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Retry getting result
  Future<void> retry(String taskId) async {
    clearResult();
    await startPolling(taskId);
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
} 