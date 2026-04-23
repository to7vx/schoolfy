import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.settings,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Settings Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  _buildSectionCard(
                    title: 'Profile Information',
                    icon: Icons.person_outline,
                    children: [
                      _buildProfileInfo(context, authProvider.userData),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Language Section
                  _buildSectionCard(
                    title: l10n.language,
                    icon: Icons.language,
                    children: [
                      _buildLanguageSettings(context, localeProvider, l10n),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Display Section
                  _buildSectionCard(
                    title: 'Display Settings',
                    icon: Icons.display_settings,
                    children: [
                      _buildDisplaySettings(context),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // System Section
                  _buildSectionCard(
                    title: 'System Information',
                    icon: Icons.info_outline,
                    children: [
                      _buildSystemInfo(context),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Actions Section
                  _buildSectionCard(
                    title: 'Actions',
                    icon: Icons.settings_applications,
                    children: [
                      _buildActionButtons(context, authProvider, l10n),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, Map<String, dynamic>? userData) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                userData?['name']?.substring(0, 1).toUpperCase() ?? 'A',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData?['name'] ?? 'Admin User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userData?['email'] ?? 'admin@schoolfy.com',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      userData?['role']?.toUpperCase() ?? 'ADMIN',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoTile(
                context,
                'School ID',
                userData?['schoolId'] ?? 'SCH_001',
                Icons.school,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoTile(
                context,
                'Last Login',
                'Just now',
                Icons.access_time,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTile(BuildContext context, String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: isDark ? AppTheme.borderColor : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon, 
                size: 16, 
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSettings(BuildContext context, LocaleProvider localeProvider, AppLocalizations l10n) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.translate),
          title: Text(l10n.language),
          subtitle: Text(localeProvider.isArabic ? l10n.arabic : l10n.english),
          trailing: Switch(
            value: localeProvider.isArabic,
            onChanged: (value) {
              localeProvider.toggleLocale();
            },
            activeColor: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDisplaySettings(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
              title: const Text('Dark Mode'),
              subtitle: Text(themeProvider.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled'),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSystemInfo(BuildContext context) {
    return Column(
      children: [
        _buildSystemInfoRow(context, 'Version', '1.0.0'),
        _buildSystemInfoRow(context, 'Build', '2025.01.10'),
        _buildSystemInfoRow(context, 'Platform', 'Flutter Web'),
        _buildSystemInfoRow(context, 'Firebase', 'Connected'),
        _buildSystemInfoRow(context, 'Last Updated', 'January 10, 2025'),
      ],
    );
  }

  Widget _buildSystemInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AuthProvider authProvider, AppLocalizations l10n) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showChangePasswordDialog(context),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Change Password'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAboutDialog(context),
            icon: const Icon(Icons.info_outline),
            label: const Text('About Schoolfy'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showSignOutDialog(context, authProvider, l10n),
            icon: const Icon(Icons.logout_rounded),
            label: Text(l10n.signOut),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password change functionality not implemented in demo'),
                  backgroundColor: AppTheme.warningColor,
                ),
              );
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('About Schoolfy'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schoolfy Admin Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text(
              'A comprehensive school pickup management system built with Flutter and Firebase.',
            ),
            SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text('• Real-time pickup queue management'),
            Text('• Student and guardian administration'),
            Text('• Multilingual support (Arabic/English)'),
            Text('• Export capabilities'),
            Text('• Live pickup display integration'),
            SizedBox(height: 16),
            Text(
              '© 2025 Schoolfy. All rights reserved.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider authProvider, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOut),
        content: const Text('Are you sure you want to sign out of the admin dashboard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              authProvider.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}
