/**
 * Sherlock - AI-Powered Deepfake Video Detection App
 * 
 * History Provider for managing stored analysis results,
 * loading past results, and handling deletion.
 */

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/upload_result.dart';

class HistoryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<StoredResult> _results = [];
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  int _currentOffset = 0;
  static const int _pageSize = 20;

  // Getters
  List<StoredResult> get results => _results;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get isEmpty => _results.isEmpty && !_isLoading;

  /// Load stored results
  Future<void> loadResults({bool refresh = false}) async {
    if (_isLoading) return;
    
    if (refresh) {
      _results.clear();
      _currentOffset = 0;
      _hasMore = true;
      _error = null;
    }
    
    _setLoading(true);
    
    try {
      final response = await _apiService.getStoredResults(
        limit: _pageSize,
        offset: _currentOffset,
      );
      
      final List<dynamic> resultsData = response['results'] ?? [];
      final newResults = resultsData
          .map((data) => StoredResult.fromJson(data))
          .toList();
      
      if (refresh) {
        _results = newResults;
      } else {
        _results.addAll(newResults);
      }
      
      // Update pagination info
      final pagination = response['pagination'] ?? {};
      _hasMore = pagination['has_more'] ?? false;
      _currentOffset += newResults.length;
      
      _error = null;
      
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error loading stored results: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a stored result
  Future<void> deleteResult(String taskId) async {
    try {
      await _apiService.deleteStoredResult(taskId);
      
      // Remove from local list
      _results.removeWhere((result) => result.taskId == taskId);
      notifyListeners();
      
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error deleting result: $e');
      notifyListeners();
    }
  }

  /// Clear all results (UI only, doesn't delete from storage)
  void clearResults() {
    _results.clear();
    _currentOffset = 0;
    _hasMore = true;
    _error = null;
    notifyListeners();
  }

  /// Retry loading results
  Future<void> retry() async {
    _error = null;
    await loadResults(refresh: true);
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
      return 'Network error. Please check your connection.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Request timeout. Please try again.';
    } else if (error.toString().contains('404')) {
      return 'Results not found.';
    } else if (error.toString().contains('500')) {
      return 'Server error. Please try again later.';
    } else {
      return 'An unexpected error occurred.';
    }
  }
}

/// Represents a stored analysis result
class StoredResult {
  final String taskId;
  final String filename;
  final String timestamp;
  final String modelUsed;
  final String? prediction;
  final double? confidence;
  final double? fakeProbability;
  final int totalFrames;

  const StoredResult({
    required this.taskId,
    required this.filename,
    required this.timestamp,
    required this.modelUsed,
    this.prediction,
    this.confidence,
    this.fakeProbability,
    required this.totalFrames,
  });

  factory StoredResult.fromJson(Map<String, dynamic> json) {
    return StoredResult(
      taskId: json['task_id'] ?? '',
      filename: json['filename'] ?? 'Unknown',
      timestamp: json['timestamp'] ?? '',
      modelUsed: json['model_used'] ?? 'Unknown',
      prediction: json['prediction'],
      confidence: json['confidence']?.toDouble(),
      fakeProbability: json['fake_probability']?.toDouble(),
      totalFrames: json['total_frames'] ?? 0,
    );
  }

  /// Format timestamp for display
  String get formattedTimestamp {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  /// Get confidence as percentage
  String get confidencePercentage {
    if (confidence == null) return 'N/A';
    return '${(confidence! * 100).toInt()}%';
  }

  /// Get short task ID for display
  String get shortTaskId => taskId.length > 8 ? taskId.substring(0, 8) : taskId;
} 