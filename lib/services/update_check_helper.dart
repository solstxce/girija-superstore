import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import 'update_service.dart';

class UpdateCheckHelper {
  static final UpdateService _updateService = UpdateService();

  static Future<void> checkForUpdates(BuildContext context, {bool showUpToDateMessage = true}) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      debugPrint('🚀 Manual update check...');
      debugPrint('📱 Current app version: $currentVersion');
      
      final updateInfo = await _updateService.checkForUpdate();
      
      // Close loading indicator
      if (context.mounted) Navigator.pop(context);
      
      if (updateInfo == null) {
        debugPrint('❌ No update info received');
        if (context.mounted && showUpToDateMessage) {
          _showErrorDialog(context, 'Unable to check for updates. Please try again later.');
        }
        return;
      }
      
      debugPrint('🔍 Comparing versions: current=$currentVersion, latest=${updateInfo.version}');
      final isUpdateAvailable = _updateService.isUpdateAvailable(currentVersion, updateInfo.version);
      debugPrint('📊 Is update available: $isUpdateAvailable');
      
      if (!isUpdateAvailable) {
        debugPrint('✅ App is up to date');
        if (context.mounted && showUpToDateMessage) {
          _showUpToDateDialog(context, currentVersion);
        }
        return;
      }
      
      final isRequired = _updateService.isUpdateRequired(currentVersion, updateInfo);
      debugPrint('⚠️ Is update required: $isRequired');
      
      if (context.mounted) {
        debugPrint('🎯 Showing update dialog');
        showDialog(
          context: context,
          barrierDismissible: !isRequired,
          builder: (context) => UpdateDialog(
            updateInfo: updateInfo,
            currentVersion: currentVersion,
            isRequired: isRequired,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking for updates: $e');
      // Close loading indicator if still open
      if (context.mounted) {
        Navigator.pop(context);
        if (showUpToDateMessage) {
          _showErrorDialog(context, 'An error occurred while checking for updates.');
        }
      }
    }
  }

  static void _showUpToDateDialog(BuildContext context, String version) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Up to Date'),
          ],
        ),
        content: Text('You are running the latest version ($version) of Girija Store.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
