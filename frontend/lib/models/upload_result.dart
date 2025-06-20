/**
 * Data Models for Sherlock App
 * 
 * Defines the data structures for API responses, upload results,
 * detection results, and other domain objects used throughout the app.
 */

import 'package:equatable/equatable.dart';

/// Represents the response from video upload endpoint
class UploadResponse extends Equatable {
  final bool success;
  final String taskId;
  final String message;
  final String filename;
  final String model;
  final String statusUrl;

  const UploadResponse({
    required this.success,
    required this.taskId,
    required this.message,
    required this.filename,
    required this.model,
    required this.statusUrl,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      success: json['success'] ?? false,
      taskId: json['task_id'] ?? '',
      message: json['message'] ?? '',
      filename: json['filename'] ?? '',
      model: json['model'] ?? '',
      statusUrl: json['status_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'task_id': taskId,
      'message': message,
      'filename': filename,
      'model': model,
      'status_url': statusUrl,
    };
  }

  @override
  List<Object?> get props => [
        success,
        taskId,
        message,
        filename,
        model,
        statusUrl,
      ];
}

/// Represents the status of a video processing task
enum TaskStatus {
  uploaded,
  processing,
  completed,
  failed,
  unknown;

  static TaskStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'uploaded':
        return TaskStatus.uploaded;
      case 'processing':
        return TaskStatus.processing;
      case 'completed':
        return TaskStatus.completed;
      case 'failed':
        return TaskStatus.failed;
      default:
        return TaskStatus.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case TaskStatus.uploaded:
        return 'Uploaded';
      case TaskStatus.processing:
        return 'Processing';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.failed:
        return 'Failed';
      case TaskStatus.unknown:
        return 'Unknown';
    }
  }

  bool get isFinished => this == TaskStatus.completed || this == TaskStatus.failed;
  bool get isProcessing => this == TaskStatus.processing || this == TaskStatus.uploaded;
}

/// Represents a suspicious frame in the video
class SuspiciousFrame extends Equatable {
  final double timestamp;
  final int frameIndex;
  final double fakeProbability;
  final double confidence;

  const SuspiciousFrame({
    required this.timestamp,
    required this.frameIndex,
    required this.fakeProbability,
    required this.confidence,
  });

  factory SuspiciousFrame.fromJson(Map<String, dynamic> json) {
    return SuspiciousFrame(
      timestamp: (json['timestamp'] ?? 0.0).toDouble(),
      frameIndex: json['frame_index'] ?? 0,
      fakeProbability: (json['fake_probability'] ?? 0.0).toDouble(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'frame_index': frameIndex,
      'fake_probability': fakeProbability,
      'confidence': confidence,
    };
  }

  /// Format timestamp as MM:SS
  String get formattedTimestamp {
    final minutes = (timestamp / 60).floor();
    final seconds = (timestamp % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [timestamp, frameIndex, fakeProbability, confidence];
}

/// Statistics about the detection results
class DetectionStatistics extends Equatable {
  final int totalFrames;
  final int fakeFrames;
  final int realFrames;
  final double fakePercentage;
  final double meanPrediction;
  final double stdPrediction;
  final double meanConfidence;

  const DetectionStatistics({
    required this.totalFrames,
    required this.fakeFrames,
    required this.realFrames,
    required this.fakePercentage,
    required this.meanPrediction,
    required this.stdPrediction,
    required this.meanConfidence,
  });

  factory DetectionStatistics.fromJson(Map<String, dynamic> json) {
    return DetectionStatistics(
      totalFrames: json['total_frames'] ?? 0,
      fakeFrames: json['fake_frames'] ?? 0,
      realFrames: json['real_frames'] ?? 0,
      fakePercentage: (json['fake_percentage'] ?? 0.0).toDouble(),
      meanPrediction: (json['mean_prediction'] ?? 0.0).toDouble(),
      stdPrediction: (json['std_prediction'] ?? 0.0).toDouble(),
      meanConfidence: (json['mean_confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_frames': totalFrames,
      'fake_frames': fakeFrames,
      'real_frames': realFrames,
      'fake_percentage': fakePercentage,
      'mean_prediction': meanPrediction,
      'std_prediction': stdPrediction,
      'mean_confidence': meanConfidence,
    };
  }

  @override
  List<Object?> get props => [
        totalFrames,
        fakeFrames,
        realFrames,
        fakePercentage,
        meanPrediction,
        stdPrediction,
        meanConfidence,
      ];
}

/// Information about the ML model used
class ModelInfo extends Equatable {
  final String modelUsed;
  final double threshold;
  final int totalFramesAnalyzed;

  const ModelInfo({
    required this.modelUsed,
    required this.threshold,
    required this.totalFramesAnalyzed,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      modelUsed: json['model_used'] ?? '',
      threshold: (json['threshold'] ?? 0.0).toDouble(),
      totalFramesAnalyzed: json['total_frames_analyzed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model_used': modelUsed,
      'threshold': threshold,
      'total_frames_analyzed': totalFramesAnalyzed,
    };
  }

  @override
  List<Object?> get props => [modelUsed, threshold, totalFramesAnalyzed];
}

/// The main detection results
class DetectionResults extends Equatable {
  final String prediction; // 'real' or 'fake'
  final double confidence;
  final double fakeProbability;
  final DetectionStatistics statistics;
  final List<SuspiciousFrame> suspiciousFrames;
  final ModelInfo modelInfo;

  const DetectionResults({
    required this.prediction,
    required this.confidence,
    required this.fakeProbability,
    required this.statistics,
    required this.suspiciousFrames,
    required this.modelInfo,
  });

  factory DetectionResults.fromJson(Map<String, dynamic> json) {
    return DetectionResults(
      prediction: json['prediction'] ?? 'unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      fakeProbability: (json['fake_probability'] ?? 0.0).toDouble(),
      statistics: DetectionStatistics.fromJson(json['statistics'] ?? {}),
      suspiciousFrames: (json['suspicious_frames'] as List<dynamic>? ?? [])
          .map((frame) => SuspiciousFrame.fromJson(frame))
          .toList(),
      modelInfo: ModelInfo.fromJson(json['model_info'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prediction': prediction,
      'confidence': confidence,
      'fake_probability': fakeProbability,
      'statistics': statistics.toJson(),
      'suspicious_frames': suspiciousFrames.map((frame) => frame.toJson()).toList(),
      'model_info': modelInfo.toJson(),
    };
  }

  /// Whether the video is predicted to be fake
  bool get isFake => prediction.toLowerCase() == 'fake';

  /// Whether the video is predicted to be real
  bool get isReal => prediction.toLowerCase() == 'real';

  /// Get confidence level category
  ConfidenceLevel get confidenceLevel {
    if (confidence >= 80) return ConfidenceLevel.high;
    if (confidence >= 60) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  @override
  List<Object?> get props => [
        prediction,
        confidence,
        fakeProbability,
        statistics,
        suspiciousFrames,
        modelInfo,
      ];
}

/// Represents the full task result response
class TaskResult extends Equatable {
  final String taskId;
  final TaskStatus status;
  final int progress;
  final String? createdAt;
  final String? completedAt;
  final String filename;
  final String modelUsed;
  final DetectionResults? results;
  final String? error;

  const TaskResult({
    required this.taskId,
    required this.status,
    required this.progress,
    this.createdAt,
    this.completedAt,
    required this.filename,
    required this.modelUsed,
    this.results,
    this.error,
  });

  factory TaskResult.fromJson(Map<String, dynamic> json) {
    return TaskResult(
      taskId: json['task_id'] ?? '',
      status: TaskStatus.fromString(json['status'] ?? ''),
      progress: json['progress'] ?? 0,
      createdAt: json['created_at'],
      completedAt: json['completed_at'],
      filename: json['filename'] ?? '',
      modelUsed: json['model_used'] ?? '',
      results: json['results'] != null ? DetectionResults.fromJson(json['results']) : null,
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'status': status.name,
      'progress': progress,
      'created_at': createdAt,
      'completed_at': completedAt,
      'filename': filename,
      'model_used': modelUsed,
      'results': results?.toJson(),
      'error': error,
    };
  }

  /// Whether the task has completed successfully
  bool get isCompleted => status == TaskStatus.completed && results != null;

  /// Whether the task has failed
  bool get hasFailed => status == TaskStatus.failed || error != null;

  /// Whether the task is still processing
  bool get isProcessing => status.isProcessing;

  @override
  List<Object?> get props => [
        taskId,
        status,
        progress,
        createdAt,
        completedAt,
        filename,
        modelUsed,
        results,
        error,
      ];
}

/// Confidence level categories
enum ConfidenceLevel {
  high,
  medium,
  low;

  String get displayName {
    switch (this) {
      case ConfidenceLevel.high:
        return 'High';
      case ConfidenceLevel.medium:
        return 'Medium';
      case ConfidenceLevel.low:
        return 'Low';
    }
  }

  String get description {
    switch (this) {
      case ConfidenceLevel.high:
        return 'Very confident in the prediction';
      case ConfidenceLevel.medium:
        return 'Moderately confident in the prediction';
      case ConfidenceLevel.low:
        return 'Low confidence - manual review recommended';
    }
  }
}

/// Represents an error response from the API
class ApiError extends Equatable {
  final String message;
  final String code;
  final String? detail;

  const ApiError({
    required this.message,
    required this.code,
    this.detail,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['error'] ?? json['message'] ?? 'Unknown error',
      code: json['code'] ?? 'UNKNOWN_ERROR',
      detail: json['detail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'code': code,
      'detail': detail,
    };
  }

  @override
  List<Object?> get props => [message, code, detail];
} 