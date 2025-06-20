/**
 * Sherlock - AI-Powered Deepfake Video Detection App
 * 
 * History Screen - Displays past analyses and allows
 * users to view previous results.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../providers/history_provider.dart';
import '../utils/constants.dart';
import '../utils/themes.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadResults(refresh: true);
    });
  }

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
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<HistoryProvider>().loadResults(refresh: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.results.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.results.isEmpty) {
            return _buildErrorState(provider);
          }

          if (provider.isEmpty) {
            return _buildEmptyState();
          }

          return _buildHistoryList(provider);
        },
      ),
    );
  }

  Widget _buildErrorState(HistoryProvider provider) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppThemes.error,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'Error Loading History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                provider.error ?? 'Unknown error occurred',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.largePadding),
              ElevatedButton(
                onPressed: () => provider.retry(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
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
                'Your past video analyses will appear here.\nResults are automatically saved to files.',
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

  Widget _buildHistoryList(HistoryProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadResults(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: provider.results.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Load more indicator
          if (index == provider.results.length) {
            if (provider.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                child: Center(child: CircularProgressIndicator()),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: ElevatedButton(
                  onPressed: () => provider.loadResults(),
                  child: const Text('Load More'),
                ),
              );
            }
          }

          final result = provider.results[index];
          return _buildHistoryItem(result, provider);
        },
      ),
    );
  }

  Widget _buildHistoryItem(StoredResult result, HistoryProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: InkWell(
        onTap: () => context.push('/results/${result.taskId}'),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getResultIcon(result.prediction),
                    color: _getResultColor(result.prediction),
                    size: 24,
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.filename,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          result.formattedTimestamp,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildResultChip(result.prediction),
                ],
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Row(
                children: [
                  Expanded(
                    child: _buildMetric(
                      'Result',
                      result.prediction ?? 'Unknown',
                      _getResultColor(result.prediction),
                    ),
                  ),
                  Expanded(
                    child: _buildMetric(
                      'Confidence',
                      result.confidencePercentage,
                      _getConfidenceColor(result.confidence),
                    ),
                  ),
                  Expanded(
                    child: _buildMetric(
                      'Frames',
                      '${result.totalFrames}',
                      Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: ${result.shortTaskId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => context.push('/results/${result.taskId}'),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View'),
                      ),
                      IconButton(
                        onPressed: () => _showDeleteDialog(result.taskId, provider),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
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

  void _showDeleteDialog(String id, HistoryProvider provider) {
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
                provider.deleteResult(id);
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

  Color _getResultColor(String result) {
    switch (result.toLowerCase()) {
      case 'real':
        return AppThemes.getResultColor(result);
      case 'ai-generated':
      case 'fake':
        return AppThemes.getResultColor(result);
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  Color _getConfidenceColor(double confidence) {
    return AppThemes.getConfidenceColor(confidence);
  }
} 