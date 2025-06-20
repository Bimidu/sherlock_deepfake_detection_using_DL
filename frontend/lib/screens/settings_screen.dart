/**
 * Sherlock - AI-Powered Deepfake Video Detection App
 * 
 * Settings Screen - App configuration and preferences
 * including theme, model selection, and API settings.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            children: [
              _buildThemeSection(context, settings),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildModelSection(context, settings),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildAPISection(context, settings),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildPrivacySection(context, settings),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildDeveloperSection(context),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildActionsSection(context, settings),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, SettingsProvider settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Theme'),
              subtitle: Text(settings.getThemeModeDisplayName()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemeDialog(context, settings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSection(BuildContext context, SettingsProvider settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detection Models',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ...AppConstants.models.entries.map((entry) {
              final isSelected = entry.key == settings.preferredModel;
              return RadioListTile<String>(
                value: entry.key,
                groupValue: settings.preferredModel,
                onChanged: (value) => settings.setPreferredModel(value!),
                title: Text(entry.value.name),
                subtitle: Text(entry.value.description),
                secondary: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAPISection(BuildContext context, SettingsProvider settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('API URL'),
              subtitle: Text(settings.apiUrl),
              trailing: const Icon(Icons.edit),
              onTap: () => _showApiUrlDialog(context, settings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection(BuildContext context, SettingsProvider settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy & Data',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            SwitchListTile(
              secondary: const Icon(Icons.history),
              title: const Text('Save History'),
              subtitle: const Text('Keep a record of past analyses'),
              value: settings.saveHistory,
              onChanged: settings.setSaveHistoryEnabled,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              subtitle: const Text('Receive analysis completion notifications'),
              value: settings.enableNotifications,
              onChanged: settings.setNotificationsEnabled,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.analytics),
              title: const Text('Analytics'),
              subtitle: const Text('Help improve the app with usage data'),
              value: settings.enableAnalytics,
              onChanged: settings.setAnalyticsEnabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, SettingsProvider settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Reset to Defaults'),
              subtitle: const Text('Restore all settings to default values'),
              onTap: () => _showResetDialog(context, settings),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              subtitle: Text('${AppConstants.appName} v${AppConstants.appVersion}'),
              onTap: () => _showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              value: mode,
              groupValue: settings.themeMode,
              onChanged: (value) {
                settings.setThemeMode(value!);
                Navigator.pop(context);
              },
              title: Text(_getThemeModeDisplayName(mode)),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showApiUrlDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.apiUrl);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter API URL',
            hintText: 'http://localhost:8000',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();
              if (settings.isValidApiUrl(url)) {
                settings.setApiUrl(url);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid URL'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              settings.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: const Icon(Icons.security, size: 48),
      children: [
        const Text(AppConstants.appDescription),
        const SizedBox(height: 16),
        const Text(
          'This app uses advanced machine learning models to detect AI-generated or manipulated video content.',
        ),
      ],
    );
  }

  String _getThemeModeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }
  
  Widget _buildDeveloperSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Developer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('View Logs'),
              subtitle: const Text('See application logs for debugging'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/logs'),
            ),
          ],
        ),
      ),
    );
  }
} 