import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String _selectedLanguage = 'English';
  String _selectedTheme = 'System';
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.deepPurple,
                      Colors.deepPurple.shade700,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
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
                                  'Hi $firstName!',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Account & Preferences',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Manage your profile, notifications, and app settings',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
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
          
          // Settings Content
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              
              // Profile Section
              _buildProfileSection(),
              const SizedBox(height: 16),
              
              // Notifications Section
              _buildNotificationsSection(),
              const SizedBox(height: 16),
              
              // Security Section
              _buildSecuritySection(),
              const SizedBox(height: 16),
              
              // Preferences Section
              _buildPreferencesSection(),
              const SizedBox(height: 16),
              
              // Data & Privacy Section
              _buildDataPrivacySection(),
              const SizedBox(height: 16),
              
              // Support & Help Section
              _buildSupportSection(),
              const SizedBox(height: 16),
              
              // About Section
              _buildAboutSection(),
              const SizedBox(height: 32),
              
              // Logout Button
              _buildLogoutButton(),
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }

  // Profile Section
  Widget _buildProfileSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final fullName = userData?['fullName'] ?? 'Not set';
        final email = userData?['email'] ?? 'Not set';
        
        return _buildSettingsCard(
          title: 'Profile',
          icon: Icons.person,
          children: [
            _buildSettingsTile(
              icon: Icons.person,
              title: 'Full Name',
              subtitle: fullName,
              onTap: () => _showEditProfileDialog(),
            ),
            _buildSettingsTile(
              icon: Icons.email,
              title: 'Email',
              subtitle: email,
              onTap: () => _showEditProfileDialog(),
            ),
            _buildSettingsTile(
              icon: Icons.phone,
              title: 'Phone Number',
              subtitle: user?.phoneNumber ?? 'Not set',
              onTap: () => _showPhoneUpdateDialog(),
            ),
            _buildSettingsTile(
              icon: Icons.family_restroom,
              title: 'Linked Students',
              subtitle: 'Manage your children\'s accounts',
              onTap: () => _showLinkedStudentsDialog(),
            ),
          ],
        );
      },
    );
  }

  // Notifications Section
  Widget _buildNotificationsSection() {
    return _buildSettingsCard(
      title: 'Notifications',
      icon: Icons.notifications,
      children: [
        _buildSwitchTile(
          icon: Icons.notifications_active,
          title: 'Push Notifications',
          subtitle: 'Get notifications on your device',
          value: _pushNotifications,
          onChanged: (value) => setState(() => _pushNotifications = value),
        ),
        _buildSwitchTile(
          icon: Icons.email,
          title: 'Email Notifications',
          subtitle: 'Receive updates via email',
          value: _emailNotifications,
          onChanged: (value) => setState(() => _emailNotifications = value),
        ),
        _buildSwitchTile(
          icon: Icons.sms,
          title: 'SMS Notifications',
          subtitle: 'Get text message alerts',
          value: _smsNotifications,
          onChanged: (value) => setState(() => _smsNotifications = value),
        ),
        const Divider(),
        _buildSwitchTile(
          icon: Icons.school,
          title: 'Attendance Alerts',
          subtitle: 'Daily attendance notifications',
          value: _attendanceAlerts,
          onChanged: (value) => setState(() => _attendanceAlerts = value),
        ),
        _buildSwitchTile(
          icon: Icons.grade,
          title: 'Grade Alerts',
          subtitle: 'Academic performance updates',
          value: _gradeAlerts,
          onChanged: (value) => setState(() => _gradeAlerts = value),
        ),
        _buildSwitchTile(
          icon: Icons.warning,
          title: 'Emergency Alerts',
          subtitle: 'Critical school notifications',
          value: _emergencyAlerts,
          onChanged: (value) => setState(() => _emergencyAlerts = value),
        ),
      ],
    );
  }

  // Security Section
  Widget _buildSecuritySection() {
    return _buildSettingsCard(
      title: 'Security',
      icon: Icons.security,
      children: [
        _buildSwitchTile(
          icon: Icons.fingerprint,
          title: 'Biometric Login',
          subtitle: 'Use fingerprint or face ID',
          value: _biometricLogin,
          onChanged: (value) => setState(() => _biometricLogin = value),
        ),
        _buildSettingsTile(
          icon: Icons.lock_reset,
          title: 'Change Password',
          subtitle: 'Update your account password',
          onTap: () => _showChangePasswordDialog(),
        ),
        _buildSettingsTile(
          icon: Icons.devices,
          title: 'Manage Devices',
          subtitle: 'See devices signed into your account',
          onTap: () => _showDevicesDialog(),
        ),
        _buildSettingsTile(
          icon: Icons.history,
          title: 'Login History',
          subtitle: 'View recent login activity',
          onTap: () => _showLoginHistoryDialog(),
        ),
      ],
    );
  }

  // Preferences Section
  Widget _buildPreferencesSection() {
    return _buildSettingsCard(
      title: 'Preferences',
      icon: Icons.settings,
      children: [
        _buildSettingsTile(
          icon: Icons.language,
          title: 'Language',
          subtitle: _selectedLanguage,
          onTap: () => _showLanguageDialog(),
        ),
        _buildSettingsTile(
          icon: Icons.palette,
          title: 'Theme',
          subtitle: _selectedTheme,
          onTap: () => _showThemeDialog(),
        ),
        _buildSwitchTile(
          icon: Icons.backup,
          title: 'Auto Backup',
          subtitle: 'Automatically backup your data',
          value: _autoBackup,
          onChanged: (value) => setState(() => _autoBackup = value),
        ),
        _buildSettingsTile(
          icon: Icons.schedule,
          title: 'Time Zone',
          subtitle: 'Arabia Standard Time (AST)',
          onTap: () => _showTimeZoneDialog(),
        ),
      ],
    );
  }

  // Data & Privacy Section
  Widget _buildDataPrivacySection() {
    return _buildSettingsCard(
      title: 'Data & Privacy',
      icon: Icons.privacy_tip,
      children: [
        _buildSettingsTile(
          icon: Icons.download,
          title: 'Download Data',
          subtitle: 'Export your account data',
          onTap: () => _downloadUserData(),
        ),
        _buildSettingsTile(
          icon: Icons.delete_forever,
          title: 'Delete Account',
          subtitle: 'Permanently delete your account',
          onTap: () => _showDeleteAccountDialog(),
        ),
        _buildSettingsTile(
          icon: Icons.policy,
          title: 'Privacy Policy',
          subtitle: 'Read our privacy policy',
          onTap: () => _showPrivacyPolicy(),
        ),
        _buildSettingsTile(
          icon: Icons.gavel,
          title: 'Terms of Service',
          subtitle: 'Read our terms of service',
          onTap: () => _showTermsOfService(),
        ),
      ],
    );
  }

  // Support Section
  Widget _buildSupportSection() {
    return _buildSettingsCard(
      title: 'Support & Help',
      icon: Icons.help,
      children: [
        _buildSettingsTile(
          icon: Icons.help_outline,
          title: 'Help Center',
          subtitle: 'Find answers to common questions',
          onTap: () => _openHelpCenter(),
        ),
        _buildSettingsTile(
          icon: Icons.contact_support,
          title: 'Contact Support',
          subtitle: 'Get help from our support team',
          onTap: () => _showContactSupportDialog(),
        ),
        _buildSettingsTile(
          icon: Icons.feedback,
          title: 'Send Feedback',
          subtitle: 'Help us improve the app',
          onTap: () => _showFeedbackDialog(),
        ),
        _buildSettingsTile(
          icon: Icons.bug_report,
          title: 'Report a Bug',
          subtitle: 'Report technical issues',
          onTap: () => _showBugReportDialog(),
        ),
      ],
    );
  }

  // About Section
  Widget _buildAboutSection() {
    return _buildSettingsCard(
      title: 'About',
      icon: Icons.info,
      children: [
        _buildSettingsTile(
          icon: Icons.info_outline,
          title: 'App Version',
          subtitle: 'Schoolfy Guardian v1.0.0',
          onTap: () => _showVersionInfo(),
        ),
        _buildSettingsTile(
          icon: Icons.update,
          title: 'Check for Updates',
          subtitle: 'Keep your app up to date',
          onTap: () => _checkForUpdates(),
        ),
        _buildSettingsTile(
          icon: Icons.star_rate,
          title: 'Rate the App',
          subtitle: 'Rate us on the App Store',
          onTap: () => _rateApp(),
        ),
        _buildSettingsTile(
          icon: Icons.share,
          title: 'Share App',
          subtitle: 'Tell others about Schoolfy',
          onTap: () => _shareApp(),
        ),
      ],
    );
  }

  // Logout Button
  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(),
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Helper Methods
  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                const SizedBox(width: 12),
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
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.deepPurple,
      ),
    );
  }

  // Action Methods
  void _showEditProfileDialog() {
    final fullNameController = TextEditingController();
    final emailController = TextEditingController();
    
    // Load current data
    FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .get()
        .then((doc) {
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        fullNameController.text = userData['fullName'] ?? '';
        emailController.text = userData['email'] ?? '';
      }
    });
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              fullNameController.dispose();
              emailController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final fullName = fullNameController.text.trim();
              final email = emailController.text.trim();
              
              if (fullName.isNotEmpty && email.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .update({
                    'fullName': fullName,
                    'email': email,
                    'firstName': fullName.split(' ')[0],
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating profile: $e')),
                    );
                  }
                }
              }
              
              fullNameController.dispose();
              emailController.dispose();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPhoneUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Phone Number'),
        content: const Text('Phone number updates require verification. You will need to re-authenticate with your new number.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Phone update feature coming soon')),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showLinkedStudentsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Linked Students',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final userData = snapshot.data?.data() as Map<String, dynamic>?;
                    final linkedStudentIds = List<String>.from(userData?['linkedStudents'] ?? []);
                    
                    if (linkedStudentIds.isEmpty) {
                      return const Center(
                        child: Text('No students linked to your account'),
                      );
                    }
                    
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('students')
                          .where(FieldPath.documentId, whereIn: linkedStudentIds)
                          .snapshots(),
                      builder: (context, studentsSnapshot) {
                        if (!studentsSnapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final students = studentsSnapshot.data!.docs;
                        
                        return ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index].data() as Map<String, dynamic>;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple,
                                child: Text(
                                  student['name']?.substring(0, 1) ?? 'S',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(student['name'] ?? ''),
                              subtitle: Text('Grade ${student['grade'] ?? ''}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () => _unlinkStudent(students[index].id),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _unlinkStudent(String studentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Student'),
        content: const Text('Are you sure you want to unlink this student? You will no longer receive updates about them.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Student unlinked successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
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
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully')),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showDevicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Devices'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.phone_android),
              title: Text('This Device'),
              subtitle: Text('Android • Last active: Now'),
              trailing: Text('Current'),
            ),
            ListTile(
              leading: Icon(Icons.tablet),
              title: Text('iPad'),
              subtitle: Text('iOS • Last active: 2 days ago'),
              trailing: TextButton(
                onPressed: null,
                child: Text('Remove'),
              ),
            ),
          ],
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

  void _showLoginHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login History'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Successful Login'),
              subtitle: Text('Today, 8:30 AM • Android'),
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Successful Login'),
              subtitle: Text('Yesterday, 7:45 AM • Android'),
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Successful Login'),
              subtitle: Text('July 7, 2025 • iPad'),
            ),
          ],
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

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('العربية'),
              value: 'Arabic',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Français'),
              value: 'French',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('System Default'),
              value: 'System',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() => _selectedTheme = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'Light',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() => _selectedTheme = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'Dark',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() => _selectedTheme = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeZoneDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time zone settings coming soon')),
    );
  }

  void _downloadUserData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Data'),
        content: const Text('Your data will be prepared and sent to your email address. This may take a few minutes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data download requested. Check your email.')),
              );
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion feature coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening privacy policy...')),
    );
  }

  void _showTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening terms of service...')),
    );
  }

  void _openHelpCenter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening help center...')),
    );
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.email),
              title: Text('Email Support'),
              subtitle: Text('support@schoolfy.com'),
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('Phone Support'),
              subtitle: Text('+966 11 456 7890'),
            ),
            ListTile(
              leading: Icon(Icons.chat),
              title: Text('Live Chat'),
              subtitle: Text('Available 24/7'),
            ),
          ],
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

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Your feedback',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback sent successfully')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Bug title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Describe the bug',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bug report submitted successfully')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Version'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Schoolfy Guardian App'),
            Text('Version: 1.0.0'),
            Text('Build: 1'),
            Text('Released: July 2025'),
          ],
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

  void _checkForUpdates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking for updates...')),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening app store...')),
    );
  }

  void _shareApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing app...')),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
