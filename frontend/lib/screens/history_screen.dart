/**
 * Sherlock - AI-Powered Deepfake Video Detection App
 * 
 * History Screen - Displays past analyses and allows
 * users to view previous results.
 */

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../utils/constants.dart';
import '../utils/themes.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<Map<String, dynamic>> _mockHistory = [
    {
      'id': '1a2b3c4d',
      'filename': 'sample_video.mp4',
      'result': 'Real',
      'confidence': 0.89,
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'completed',
    },
    {
      'id': '5e6f7g8h',
      'filename': 'test_deepfake.avi',
      'result': 'AI-Generated',
      'confidence': 0.93,
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'completed',
    },
    {
      'id': '9i0j1k2l',
      'filename': 'interview_clip.mov',
      'result': 'Real',
      'confidence': 0.76,
      'createdAt': DateTime.now().subtract(const Duration(days: 3)),
      'status': 'completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _showClearHistoryDialog,
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: _mockHistory.isEmpty ? _buildEmptyState() : _buildHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                MdiIcons.history,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'No Analysis History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'Your past video analyses will appear here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.largePadding),
              ElevatedButton(
                onPressed: () => context.push('/upload'),
                child: const Text('Analyze First Video'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: _mockHistory.length,
      itemBuilder: (context, index) {
        final item = _mockHistory[index];
        return _buildHistoryItem(item);
      },
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final result = item['result'] as String;
    final confidence = item['confidence'] as double;
    final createdAt = item['createdAt'] as DateTime;
    final filename = item['filename'] as String;
    final id = item['id'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: InkWell(
        onTap: () => context.push('/results/$id'),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getResultIcon(result),
                    color: AppThemes.getResultColor(result),
                    size: 24,
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          filename,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatDateTime(createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildResultChip(result),
                ],
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Row(
                children: [
                  Expanded(
                    child: _buildMetric(
                      'Result',
                      _getResultDisplayText(result),
                      AppThemes.getResultColor(result),
                    ),
                  ),
                  Expanded(
                    child: _buildMetric(
                      'Confidence',
                      '${(confidence * 100).toInt()}%',
                      AppThemes.getConfidenceColor(confidence),
                    ),
                  ),
                  Expanded(
                    child: _buildMetric(
                      'ID',
                      id.substring(0, 8),
                      Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => context.push('/results/$id'),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                  ),
                  IconButton(
                    onPressed: () => _showDeleteDialog(id),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                    color: Theme.of(context).colorScheme.error,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultChip(String result) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
        vertical: AppConstants.smallPadding / 2,
      ),
      decoration: BoxDecoration(
        color: AppThemes.getResultColor(result),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius / 2),
      ),
      child: Text(
        result,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Analysis'),
        content: const Text(
          'Are you sure you want to delete this analysis? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _mockHistory.removeWhere((item) => item['id'] == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analysis deleted'),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'Are you sure you want to clear all analysis history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _mockHistory.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('History cleared'),
                ),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  IconData _getResultIcon(String result) {
    switch (result.toLowerCase()) {
      case 'real':
        return MdiIcons.checkCircle;
      case 'ai-generated':
      case 'fake':
        return MdiIcons.alertCircle;
      default:
        return MdiIcons.helpCircle;
    }
  }

  String _getResultDisplayText(String result) {
    switch (result.toLowerCase()) {
      case 'real':
        return 'Authentic';
      case 'ai-generated':
      case 'fake':
        return 'Deepfake';
      default:
        return 'Unknown';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
} 