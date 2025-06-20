/**
 * Sherlock - AI-Powered Deepfake Video Detection App
 * 
 * Results Screen - Displays detection results including
 * confidence scores, suspicious frames, and detailed analysis.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../providers/results_provider.dart';
import '../models/upload_result.dart';
import '../utils/constants.dart';
import '../utils/themes.dart';

class ResultsScreen extends StatefulWidget {
  final String taskId;

  const ResultsScreen({super.key, required this.taskId});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResultsProvider>().startPolling(widget.taskId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<ResultsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentResult == null) {
            return _buildLoadingScreen();
          }

          if (provider.error != null && provider.currentResult == null) {
            return _buildErrorScreen(provider);
          }

          if (provider.currentResult == null) {
            return _buildLoadingScreen();
          }

          final result = provider.currentResult!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTaskHeader(result),
                const SizedBox(height: AppConstants.defaultPadding),
                if (result.status == TaskStatus.processing ||
                    result.status == TaskStatus.uploaded) ...[
                  _buildProcessingStatus(provider),
                  const SizedBox(height: AppConstants.defaultPadding),
                ],
                if (result.status == TaskStatus.completed && result.results != null) ...[
                  _buildDetectionResults(result.results!),
                ],
                if (result.status == TaskStatus.failed) ...[
                  _buildFailedResults(result),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorScreen(ResultsProvider provider) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error,
                size: 64,
                color: AppThemes.error,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'Error Loading Results',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppThemes.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                provider.error ?? AppConstants.unknownError,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.largePadding),
              ElevatedButton(
                onPressed: () => provider.retry(widget.taskId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskHeader(TaskResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(result.status),
                  color: _getStatusColor(result.status),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: Text(
                    'Task ${widget.taskId.substring(0, 8)}...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(result.status),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildInfoRow('File', result.filename),
            _buildInfoRow('Model', result.modelUsed),
            if (result.createdAt != null)
              _buildInfoRow('Created', result.createdAt!),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingStatus(ResultsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (provider.isPolling)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Processing Video...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'This may take a few minutes depending on video length and complexity.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionResults(DetectionResults results) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getResultIcon(results.prediction),
                  color: AppThemes.getResultColor(results.prediction),
                  size: 32,
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getResultTitle(results.prediction),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppThemes.getResultColor(results.prediction),
                        ),
                      ),
                      Text(
                        _getResultDescription(results.prediction),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.largePadding),
            _buildConfidenceScore(results.confidence),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildFrameAnalysis(results),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceScore(double confidence) {
    final percentage = (confidence * 100).toInt();
    final color = AppThemes.getConfidenceColor(confidence);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confidence Score',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
                border: Border.all(color: color, width: 4),
              ),
              child: Center(
                child: Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confidence Level: ${_getConfidenceLevel(confidence)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _getConfidenceDescription(confidence),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFrameAnalysis(DetectionResults results) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Frames',
            results.statistics.totalFrames.toString(),
            Icons.video_library,
          ),
        ),
        const SizedBox(width: AppConstants.smallPadding),
        Expanded(
          child: _buildStatCard(
            'Suspicious',
            results.suspiciousFrames.length.toString(),
            Icons.warning,
          ),
        ),
        const SizedBox(width: AppConstants.smallPadding),
        Expanded(
          child: _buildStatCard(
            'Model',
            results.modelInfo.modelUsed,
            Icons.model_training,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFailedResults(TaskResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Icon(
              Icons.error,
              size: 64,
              color: AppThemes.error,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Analysis Failed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppThemes.error,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              result.error ?? AppConstants.processingFailedError,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
        vertical: AppConstants.smallPadding / 2,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius / 2),
      ),
      child: Text(
        status.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.uploaded:
        return Icons.schedule;
      case TaskStatus.processing:
        return Icons.refresh;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.failed:
        return Icons.error;
      case TaskStatus.unknown:
        return Icons.help;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.uploaded:
        return AppThemes.warning;
      case TaskStatus.processing:
        return Theme.of(context).colorScheme.primary;
      case TaskStatus.completed:
        return AppThemes.success;
      case TaskStatus.failed:
        return AppThemes.error;
      case TaskStatus.unknown:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  IconData _getResultIcon(String result) {
    switch (result.toLowerCase()) {
      case 'real':
        return MdiIcons.checkCircle;
      case 'fake':
      case 'ai-generated':
        return MdiIcons.alertCircle;
      default:
        return MdiIcons.helpCircle;
    }
  }

  String _getResultTitle(String result) {
    switch (result.toLowerCase()) {
      case 'real':
        return 'Authentic Video';
      case 'fake':
      case 'ai-generated':
        return 'AI-Generated Content Detected';
      default:
        return 'Uncertain Result';
    }
  }

  String _getResultDescription(String result) {
    switch (result.toLowerCase()) {
      case 'real':
        return 'This video appears to be authentic with no signs of AI generation.';
      case 'fake':
      case 'ai-generated':
        return 'This video shows signs of AI generation or manipulation.';
      default:
        return 'The analysis could not determine the authenticity with high confidence.';
    }
  }

  String _getConfidenceLevel(double confidence) {
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.6) return 'Medium';
    return 'Low';
  }

  String _getConfidenceDescription(double confidence) {
    if (confidence >= 0.8) return 'Very confident in the prediction';
    if (confidence >= 0.6) return 'Moderately confident in the prediction';
    return 'Low confidence - manual review recommended';
  }
} 