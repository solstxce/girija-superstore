import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/widgets.dart';
import '../../../services/services.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          const SectionHeader(title: 'Appearance'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: isDark ? AppTheme.blueDark : AppTheme.primaryPastel,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Theme',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ThemeOption(
                        icon: Icons.light_mode,
                        label: 'Light',
                        isSelected: !isDark,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ThemeOption(
                        icon: Icons.dark_mode,
                        label: 'Dark',
                        isSelected: isDark,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // System Section
          const SectionHeader(title: 'System'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                _SettingItem(
                  icon: Icons.system_update,
                  label: 'Check for Updates',
                  onTap: () => UpdateCheckHelper.checkForUpdates(context),
                ),
                const Divider(),
                _SettingItem(
                  icon: Icons.info_outline,
                  label: 'About',
                  onTap: () => _showAboutDialog(context),
                ),
                const Divider(),
                _SettingItem(
                  icon: Icons.info_outlined,
                  label: 'Version',
                  value: '1.0.0',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Girija Store'),
        content: const Text(
          'Girija Store is a neighborhood supermarket app that makes shopping convenient and easy.\n\nVersion: 1.0.0\n\nAll data is stored locally on your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? (isDark ? AppTheme.blueDark : AppTheme.primaryPastel)
                : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: isSelected
              ? (isDark ? AppTheme.blueDark : AppTheme.primaryPastel)
                  .withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? (isDark ? AppTheme.blueDark : AppTheme.primaryPastel)
                  : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? AppTheme.blueDark : AppTheme.primaryPastel)
                    : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: TextStyle(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
