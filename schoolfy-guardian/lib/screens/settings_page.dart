import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _attendanceAlerts = true;
  bool _gradeAlerts = true;
  bool _emergencyAlerts = true;
  bool _biometricLogin = false;
  bool _autoBackup = true;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingXXL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        StreamBuilder<DocumentSnapshot>(
                          stream: user != null
                              ? FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user!.uid)
                                  .snapshots()
                              : null,
                          builder: (context, snapshot) {
                            final userData = snapshot.data?.data() as Map<String, dynamic>?;
                            final firstName = userData?['firstName'] ?? 'Guardian';
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n?.settings ?? 'Settings',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hi $firstName!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Manage your account & preferences',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Profile Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                boxShadow: AppTheme.softShadow,
              ),
              child: StreamBuilder<DocumentSnapshot>(
                stream: user != null
                    ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .snapshots()
                    : null,
                builder: (context, snapshot) {
                  final userData = snapshot.data?.data() as Map<String, dynamic>?;
                  final firstName = userData?['firstName'] ?? 'Guardian';
                  final lastName = userData?['lastName'] ?? '';
                  final email = user?.email ?? '';
                  
                  return Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials('$firstName $lastName'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingL),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$firstName $lastName',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Verified Guardian',
                                      style: TextStyle(
                                        color: AppTheme.successColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showEditProfileDialog(),
                              icon: Icon(
                                Icons.edit_rounded,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Settings Sections
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Notifications Section
                _buildSettingsSection(
                  l10n?.notifications ?? 'Notifications',
                  Icons.notifications_rounded,
                  [
                    _buildSwitchTile(
                      l10n?.pushNotifications ?? 'Push Notifications',
                      'Receive notifications on your device',
                      _pushNotifications,
                      (value) => setState(() => _pushNotifications = value),
                    ),
                    _buildSwitchTile(
                      l10n?.emailNotifications ?? 'Email Notifications',
                      'Receive notifications via email',
                      _emailNotifications,
                      (value) => setState(() => _emailNotifications = value),
                    ),
                    _buildSwitchTile(
                      l10n?.smsNotifications ?? 'SMS Notifications',
                      'Receive important updates via SMS',
                      _smsNotifications,
                      (value) => setState(() => _smsNotifications = value),
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      l10n?.attendanceAlerts ?? 'Attendance Alerts',
                      'Get notified about attendance updates',
                      _attendanceAlerts,
                      (value) => setState(() => _attendanceAlerts = value),
                    ),
                    _buildSwitchTile(
                      l10n?.gradeAlerts ?? 'Grade Alerts',
                      'Get notified about grade changes',
                      _gradeAlerts,
                      (value) => setState(() => _gradeAlerts = value),
                    ),
                    _buildSwitchTile(
                      l10n?.emergencyAlerts ?? 'Emergency Alerts',
                      'Receive emergency notifications',
                      _emergencyAlerts,
                      (value) => setState(() => _emergencyAlerts = value),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingL),
                
                // Security Section
                _buildSettingsSection(
                  l10n?.security ?? 'Security & Privacy',
                  Icons.security_rounded,
                  [
                    _buildSwitchTile(
                      l10n?.biometricLogin ?? 'Biometric Login',
                      l10n?.biometricLoginDescription ?? 'Use fingerprint or face unlock',
                      _biometricLogin,
                      (value) => setState(() => _biometricLogin = value),
                    ),
                    _buildTapTile(
                      l10n?.changePassword ?? 'Change Password',
                      l10n?.updatePassword ?? 'Update your account password',
                      Icons.lock_rounded,
                      () {
                        // Change password
                      },
                    ),
                    _buildTapTile(
                      l10n?.twoFactorAuth ?? 'Two-Factor Authentication',
                      l10n?.twoFactorAuthDescription ?? 'Add an extra layer of security',
                      Icons.shield_rounded,
                      () {
                        // Setup 2FA
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingL),
                
                // App Preferences Section
                _buildSettingsSection(
                  l10n?.appPreferences ?? 'App Preferences',
                  Icons.tune_rounded,
                  [
                    _buildLanguageSelector(),
                    _buildThemeSelector(),
                    _buildSwitchTile(
                      'Auto Backup',
                      'Automatically backup your data',
                      _autoBackup,
                      (value) => setState(() => _autoBackup = value),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingL),
                
                // Support Section
                _buildSettingsSection(
                  l10n?.support ?? 'Support',
                  Icons.help_rounded,
                  [
                    _buildTapTile(
                      l10n?.helpCenter ?? 'Help Center',
                      l10n?.findAnswers ?? 'Get help and support',
                      Icons.help_center_rounded,
                      () {
                        // Open help center
                      },
                    ),
                    _buildTapTile(
                      l10n?.contactSupport ?? 'Contact Support',
                      l10n?.getHelp ?? 'Get in touch with our team',
                      Icons.support_agent_rounded,
                      () {
                        // Contact support
                      },
                    ),
                    _buildTapTile(
                      l10n?.termsOfService ?? 'Terms of Service',
                      l10n?.readTerms ?? 'Read our terms and conditions',
                      Icons.description_rounded,
                      () {
                        // Show terms
                      },
                    ),
                    _buildTapTile(
                      l10n?.privacyPolicy ?? 'Privacy Policy',
                      l10n?.readPrivacyPolicy ?? 'Learn about our privacy practices',
                      Icons.privacy_tip_rounded,
                      () {
                        // Show privacy policy
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingL),
                
                // Account Actions Section
                _buildSettingsSection(
                  l10n?.account ?? 'Account',
                  Icons.account_circle_rounded,
                  [
                    _buildTapTile(
                      l10n?.exportData ?? 'Export Data',
                      l10n?.downloadData ?? 'Download your account data',
                      Icons.download_rounded,
                      () {
                        // Export data
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingL),
                
                // Sign Out Button
                Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingXXL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      onTap: () => _showLogoutConfirmation(l10n),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingL),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingL),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n?.signOut ?? 'Sign Out',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                  Text(
                                    l10n?.signOutDescription ?? 'Sign out of your account',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingS,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTapTile(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? Colors.red : AppTheme.textPrimary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingL,
            vertical: AppTheme.spacingM,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDestructive ? Colors.red.withOpacity(0.7) : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final l10n = AppLocalizations.of(context);
        
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingL,
            vertical: AppTheme.spacingS,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.language ?? 'Language',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n?.chooseLanguage ?? 'Choose your preferred language',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButton<String>(
                value: languageProvider.currentLocale.languageCode,
                onChanged: (String? newLanguageCode) {
                  if (newLanguageCode != null) {
                    languageProvider.setLanguage(newLanguageCode);
                  }
                },
                underline: Container(),
                items: [
                  DropdownMenuItem<String>(
                    value: 'en',
                    child: Text(l10n?.english ?? 'English'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'ar',
                    child: Text(l10n?.arabic ?? 'العربية'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeSelector() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final l10n = AppLocalizations.of(context);
        
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingL,
            vertical: AppTheme.spacingS,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.theme ?? 'Theme',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n?.chooseTheme ?? 'Choose your app theme',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButton<AppThemeMode>(
                value: themeProvider.themeMode,
                onChanged: (AppThemeMode? newThemeMode) {
                  if (newThemeMode != null) {
                    themeProvider.setThemeMode(newThemeMode);
                  }
                },
                underline: Container(),
                items: [
                  DropdownMenuItem<AppThemeMode>(
                    value: AppThemeMode.light,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.light_mode, size: 16),
                        const SizedBox(width: 8),
                        Text(l10n?.light ?? 'Light'),
                      ],
                    ),
                  ),
                  DropdownMenuItem<AppThemeMode>(
                    value: AppThemeMode.dark,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.dark_mode, size: 16),
                        const SizedBox(width: 8),
                        Text(l10n?.dark ?? 'Dark'),
                      ],
                    ),
                  ),
                  DropdownMenuItem<AppThemeMode>(
                    value: AppThemeMode.system,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.settings_brightness, size: 16),
                        const SizedBox(width: 8),
                        Text(l10n?.system ?? 'System'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'G';
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}';
    }
    return words[0][0];
  }

  void _showLogoutConfirmation(AppLocalizations? l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(l10n?.signOut ?? 'Sign Out'),
            ],
          ),
          content: Text(
            l10n?.signOutConfirmation ?? 'Are you sure you want to sign out of your account?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n?.cancel ?? 'Cancel',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                FirebaseAuth.instance.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
              child: Text(
                l10n?.signOut ?? 'Sign Out',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileDialog() {
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => _EditProfileDialog(user: user!),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final User user;

  const _EditProfileDialog({required this.user});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
      
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          firstNameController.text = data['firstName'] ?? '';
          lastNameController.text = data['lastName'] ?? '';
          emailController.text = data['email'] ?? '';
          phoneController.text = data['phoneNumber'] ?? '';
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      title: Row(
        children: [
          Icon(
            Icons.edit_rounded,
            color: AppTheme.primaryColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Edit Profile'),
        ],
      ),
      content: _isInitialized
          ? SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: const Icon(Icons.person_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  TextField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}
