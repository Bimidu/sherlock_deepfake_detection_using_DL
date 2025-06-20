/**
 * Sherlock - AI-Powered Deepfake Video Detection App
 * 
 * API Service for communicating with the FastAPI backend.
 * Handles all HTTP requests including file uploads and result polling.
 */

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../models/upload_result.dart';
import '../utils/constants.dart';

class ApiService {
  static const String _baseUrl = AppConstants.baseUrl;
  static const Duration _timeout = AppConstants.apiTimeout;

  /// Upload video file for analysis
  Future<UploadResponse> uploadVideo(File videoFile, {String? model}) async {
    try {
      final url = Uri.parse('$_baseUrl${AppConstants.uploadEndpoint}');
      final request = http.MultipartRequest('POST', url);
      
      // Add video file
      final fileStream = http.ByteStream(videoFile.openRead());
      final fileLength = await videoFile.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: path.basename(videoFile.path),
      );
      request.files.add(multipartFile);
      
      // Add model parameter if specified
      if (model != null) {
        request.fields['model'] = model;
      }
      
      // Set headers
      request.headers.addAll({
        'Accept': 'application/json',
      });
      
      // Send request with timeout
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 202) {
        final jsonData = json.decode(response.body);
        return UploadResponse.fromJson(jsonData);
      } else {
        throw HttpException('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get task result by ID
  Future<TaskResult> getTaskResult(String taskId) async {
    try {
      final url = Uri.parse('$_baseUrl${AppConstants.resultsEndpoint}/$taskId');
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TaskResult.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw HttpException('Task not found');
      } else {
        throw HttpException('Failed to get result: ${response.statusCode}');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get health status
  Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      final url = Uri.parse('$_baseUrl${AppConstants.healthEndpoint}');
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw HttpException('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get available models
  Future<List<Map<String, dynamic>>> getAvailableModels() async {
    try {
      final url = Uri.parse('$_baseUrl${AppConstants.modelsEndpoint}');
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return List<Map<String, dynamic>>.from(jsonData['models']);
      } else {
        throw HttpException('Failed to get models: ${response.statusCode}');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Cancel a task
  Future<void> cancelTask(String taskId) async {
    try {
      final url = Uri.parse('$_baseUrl${AppConstants.taskEndpoint}/$taskId/cancel');
      final response = await http.post(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode != 200) {
        throw HttpException('Failed to cancel task: ${response.statusCode}');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get task status
  Future<Map<String, dynamic>> getTaskStatus(String taskId) async {
    try {
      final url = Uri.parse('$_baseUrl${AppConstants.taskEndpoint}/$taskId/status');
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw HttpException('Task not found');
      } else {
        throw HttpException('Failed to get task status: ${response.statusCode}');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Validate video file before upload
  Future<bool> validateVideoFile(File file) async {
    try {
      // Check file size
      final fileSize = await file.length();
      if (fileSize > AppConstants.maxFileSize) {
        throw Exception(AppConstants.fileTooLargeError);
      }
      
      // Check file extension
      final extension = path.extension(file.path).toLowerCase().substring(1);
      if (!AppConstants.supportedVideoFormats.contains(extension)) {
        throw Exception(AppConstants.invalidFileFormatError);
      }
      
      // Check if file exists and is readable
      if (!await file.exists()) {
        throw Exception(AppConstants.fileNotFoundError);
      }
      
      return true;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Download result file (if available)
  Future<List<int>> downloadResultFile(String taskId, String filename) async {
    try {
      final url = Uri.parse('$_baseUrl${AppConstants.resultsEndpoint}/$taskId/download/$filename');
      final response = await http.get(url).timeout(AppConstants.downloadTimeout);
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw HttpException('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle and format errors
  Exception _handleError(dynamic error) {
    if (error is SocketException) {
      return Exception(AppConstants.networkError);
    } else if (error is HttpException) {
      return Exception(error.message);
    } else if (error.toString().contains('TimeoutException')) {
      return Exception('Request timeout. Please try again.');
    } else {
      return Exception(AppConstants.unknownError);
    }
  }

  /// Test connection to the backend
  Future<bool> testConnection() async {
    try {
      await getHealthStatus();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get server info
  Future<Map<String, dynamic>> getServerInfo() async {
    try {
      final url = Uri.parse('$_baseUrl/info');
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw HttpException('Failed to get server info: ${response.statusCode}');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }
} 