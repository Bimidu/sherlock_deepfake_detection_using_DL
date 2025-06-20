/**
 * Sherlock - AI-Powered Deepfake Video Detection App
 * 
 * Home Screen - Main landing page with app overview,
 * quick actions, and navigation to key features.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../providers/settings_provider.dart';
import '../providers/video_upload_provider.dart';
import '../utils/constants.dart';
import '../utils/themes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final settingsProvider = context.read<SettingsProvider>();
    await settingsProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: AppConstants.largePadding),
            _buildQuickActions(),
            const SizedBox(height: AppConstants.largePadding),
            _buildFeaturesSection(),
            const SizedBox(height: AppConstants.largePadding),
            _buildModelInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  MdiIcons.eyeCheck,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: Text(
                    'Welcome to ${AppConstants.appName}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              AppConstants.appDescription,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Upload a video to analyze whether it contains AI-generated (deepfake) content using advanced machine learning models.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Upload Video',
                subtitle: 'Analyze new video',
                icon: Icons.upload_file,
                color: Theme.of(context).colorScheme.primary,
                onTap: () => context.push('/upload'),
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: _buildActionCard(
                title: 'View History',
                subtitle: 'Past analyses',
                icon: Icons.history,
                color: Theme.of(context).colorScheme.secondary,
                onTap: () => context.push('/history'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        _buildFeatureItem(
          icon: MdiIcons.robot,
          title: 'AI Detection',
          description: 'Advanced machine learning models for accurate deepfake detection',
        ),
        _buildFeatureItem(
          icon: MdiIcons.speedometer,
          title: 'Real-time Analysis',
          description: 'Fast processing with real-time progress updates',
        ),
        _buildFeatureItem(
          icon: MdiIcons.chartLine,
          title: 'Confidence Scoring',
          description: 'Detailed confidence scores and suspicious frame highlighting',
        ),
        _buildFeatureItem(
          icon: MdiIcons.shield,
          title: 'Privacy First',
          description: 'Videos are processed locally and not stored permanently',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding / 2),
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

  Widget _buildModelInfo() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final selectedModel = AppConstants.models[settings.preferredModel];
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      MdiIcons.brain,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppConstants.smallPadding),
                    Text(
                      'Detection Models',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                if (selectedModel != null) ...[
                  _buildModelCard(
                    name: selectedModel.name,
                    description: selectedModel.description,
                    accuracy: selectedModel.accuracy,
                    speed: selectedModel.inferenceTime,
                    isSelected: true,
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                ],
                TextButton(
                  onPressed: () => context.push('/settings'),
                  child: const Text('View All Models'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModelCard({
    required String name,
    required String description,
    required double accuracy,
    required String speed,
    bool isSelected = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: isSelected
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : null,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Row(
            children: [
              _buildMetricChip('Accuracy: ${(accuracy * 100).toInt()}%'),
              const SizedBox(width: AppConstants.smallPadding),
              _buildMetricChip('Speed: $speed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
        vertical: AppConstants.smallPadding / 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius / 2),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
} 