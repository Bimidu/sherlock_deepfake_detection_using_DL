/**
 * Sherlock - AI-Powered Deepfake Video Detection App
 * 
 * Upload Screen - Handles video selection, validation,
 * upload process, and navigation to results.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../providers/video_upload_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../utils/themes.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Video'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<VideoUploadProvider>(
        builder: (context, uploadProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (uploadProvider.status == UploadStatus.idle) ...[
                  _buildUploadInstructions(),
                  const SizedBox(height: AppConstants.largePadding),
                  _buildFileConstraints(),
                  const SizedBox(height: AppConstants.largePadding),
                  _buildModelSelection(),
                  const SizedBox(height: AppConstants.largePadding),
                  _buildUploadArea(uploadProvider),
                ],
                if (uploadProvider.status == UploadStatus.selecting) ...[
                  _buildLoadingIndicator('Selecting file...'),
                ],
                if (uploadProvider.status == UploadStatus.uploading) ...[
                  _buildUploadProgress(uploadProvider),
                ],
                if (uploadProvider.status == UploadStatus.uploaded) ...[
                  _buildUploadSuccess(uploadProvider),
                ],
                if (uploadProvider.status == UploadStatus.failed) ...[
                  _buildUploadError(uploadProvider),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  MdiIcons.informationOutline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'How it works',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildInstructionStep(
              number: '1',
              title: 'Select Video',
              description: 'Choose a video file from your device',
            ),
            _buildInstructionStep(
              number: '2',
              title: 'Analysis',
              description: 'Our AI models analyze the video for deepfake content',
            ),
            _buildInstructionStep(
              number: '3',
              title: 'Results',
              description: 'View confidence scores and suspicious frames',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
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
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileConstraints() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File Requirements',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildConstraintItem(
              icon: Icons.file_present,
              text: 'Supported formats: ${AppConstants.supportedVideoFormats.join(', ').toUpperCase()}',
            ),
            _buildConstraintItem(
              icon: Icons.storage,
              text: 'Maximum size: ${AppConstants.maxFileSize ~/ (1024 * 1024)}MB',
            ),
            _buildConstraintItem(
              icon: Icons.access_time,
              text: 'Maximum duration: ${AppConstants.maxVideoDuration ~/ 60} minutes',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConstraintItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelection() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detection Model',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                ...AppConstants.models.entries.map((entry) {
                  final isSelected = entry.key == settings.preferredModel;
                  return _buildModelOption(
                    key: entry.key,
                    model: entry.value,
                    isSelected: isSelected,
                    onTap: () => settings.setPreferredModel(entry.key),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModelOption({
    required String key,
    required ModelInfo model,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
          ),
          child: Row(
            children: [
              Radio<String>(
                value: key,
                groupValue: context.read<SettingsProvider>().preferredModel,
                onChanged: (value) => onTap(),
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      model.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Accuracy: ${(model.accuracy * 100).toInt()}% • Speed: ${model.inferenceTime}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea(VideoUploadProvider uploadProvider) {
    return Card(
      child: InkWell(
        onTap: uploadProvider.selectVideo,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.largePadding * 2),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                MdiIcons.cloudUpload,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'Tap to select video',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'Choose a video file from your device',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(String message) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgress(VideoUploadProvider uploadProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uploading Video',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            if (uploadProvider.selectedFile != null) ...[
              Text(
                'File: ${uploadProvider.selectedFile!.path.split('/').last}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppConstants.smallPadding),
            ],
            LinearPercentIndicator(
              lineHeight: 8,
              percent: uploadProvider.uploadProgress,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              progressColor: Theme.of(context).colorScheme.primary,
              barRadius: const Radius.circular(4),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              '${(uploadProvider.uploadProgress * 100).toInt()}% complete',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSuccess(VideoUploadProvider uploadProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: AppThemes.success,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Upload Successful!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppThemes.success,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              AppConstants.uploadSuccessMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.largePadding),
            ElevatedButton(
              onPressed: () {
                if (uploadProvider.taskId != null) {
                  context.push('/results/${uploadProvider.taskId}');
                }
              },
              child: const Text('View Results'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadError(VideoUploadProvider uploadProvider) {
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
              'Upload Failed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppThemes.error,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              uploadProvider.error ?? AppConstants.uploadFailedError,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.largePadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () => uploadProvider.reset(),
                  child: const Text('Try Again'),
                ),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 