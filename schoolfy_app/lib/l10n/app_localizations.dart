import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ar.dart';

class AppLocalizations {
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  final String localeName;

  AppLocalizations(this.localeName);

  // App Title and General
  String get appTitle => Intl.message(
        'Schoolfy Guardian',
        name: 'appTitle',
        locale: localeName,
      );

  String get welcome => Intl.message(
        'Welcome',
        name: 'welcome',
        locale: localeName,
      );

  String get loading => Intl.message(
        'Loading...',
        name: 'loading',
        locale: localeName,
      );

  String get error => Intl.message(
        'Error',
        name: 'error',
        locale: localeName,
      );

  String get success => Intl.message(
        'Success',
        name: 'success',
        locale: localeName,
      );

  String get cancel => Intl.message(
        'Cancel',
        name: 'cancel',
        locale: localeName,
      );

  String get save => Intl.message(
        'Save',
        name: 'save',
        locale: localeName,
      );

  String get delete => Intl.message(
        'Delete',
        name: 'delete',
        locale: localeName,
      );

  String get edit => Intl.message(
        'Edit',
        name: 'edit',
        locale: localeName,
      );

  // Navigation
  String get home => Intl.message(
        'Home',
        name: 'home',
        locale: localeName,
      );

  String get students => Intl.message(
        'Students',
        name: 'students',
        locale: localeName,
      );

  String get guardians => Intl.message(
        'Guardians',
        name: 'guardians',
        locale: localeName,
      );

  String get settings => Intl.message(
        'Settings',
        name: 'settings',
        locale: localeName,
      );

  String get profile => Intl.message(
        'Profile',
        name: 'profile',
        locale: localeName,
      );

  // Settings Page
  String get appPreferences => Intl.message(
        'App Preferences',
        name: 'appPreferences',
        locale: localeName,
      );

  String get language => Intl.message(
        'Language',
        name: 'language',
        locale: localeName,
      );

  String get chooseLanguage => Intl.message(
        'Choose your preferred language',
        name: 'chooseLanguage',
        locale: localeName,
      );

  String get theme => Intl.message(
        'Theme',
        name: 'theme',
        locale: localeName,
      );

  String get chooseTheme => Intl.message(
        'Choose your app theme',
        name: 'chooseTheme',
        locale: localeName,
      );

  String get autoBackup => Intl.message(
        'Auto Backup',
        name: 'autoBackup',
        locale: localeName,
      );

  String get autoBackupDescription => Intl.message(
        'Automatically backup your data',
        name: 'autoBackupDescription',
        locale: localeName,
      );

  String get notifications => Intl.message(
        'Notifications',
        name: 'notifications',
        locale: localeName,
      );

  String get pushNotifications => Intl.message(
        'Push Notifications',
        name: 'pushNotifications',
        locale: localeName,
      );

  String get emailNotifications => Intl.message(
        'Email Notifications',
        name: 'emailNotifications',
        locale: localeName,
      );

  String get smsNotifications => Intl.message(
        'SMS Notifications',
        name: 'smsNotifications',
        locale: localeName,
      );

  String get attendanceAlerts => Intl.message(
        'Attendance Alerts',
        name: 'attendanceAlerts',
        locale: localeName,
      );

  String get gradeAlerts => Intl.message(
        'Grade Alerts',
        name: 'gradeAlerts',
        locale: localeName,
      );

  String get emergencyAlerts => Intl.message(
        'Emergency Alerts',
        name: 'emergencyAlerts',
        locale: localeName,
      );

  String get security => Intl.message(
        'Security',
        name: 'security',
        locale: localeName,
      );

  String get biometricLogin => Intl.message(
        'Biometric Login',
        name: 'biometricLogin',
        locale: localeName,
      );

  String get biometricLoginDescription => Intl.message(
        'Use fingerprint or face recognition',
        name: 'biometricLoginDescription',
        locale: localeName,
      );

  // Language Options
  String get english => Intl.message(
        'English',
        name: 'english',
        locale: localeName,
      );

  String get arabic => Intl.message(
        'Arabic',
        name: 'arabic',
        locale: localeName,
      );

  // Theme Options
  String get light => Intl.message(
        'Light',
        name: 'light',
        locale: localeName,
      );

  String get dark => Intl.message(
        'Dark',
        name: 'dark',
        locale: localeName,
      );

  String get system => Intl.message(
        'System',
        name: 'system',
        locale: localeName,
      );

  // Student related
  String get studentName => Intl.message(
        'Student Name',
        name: 'studentName',
        locale: localeName,
      );

  String get grade => Intl.message(
        'Grade',
        name: 'grade',
        locale: localeName,
      );

  String get attendance => Intl.message(
        'Attendance',
        name: 'attendance',
        locale: localeName,
      );

  String get pickup => Intl.message(
        'Pickup',
        name: 'pickup',
        locale: localeName,
      );

  String get requestPickup => Intl.message(
        'Request Pickup',
        name: 'requestPickup',
        locale: localeName,
      );

  // Common actions
  String get logout => Intl.message(
        'Logout',
        name: 'logout',
        locale: localeName,
      );

  String get signOut => Intl.message(
        'Sign Out',
        name: 'signOut',
        locale: localeName,
      );

  String get signOutDescription => Intl.message(
        'Sign out of your account',
        name: 'signOutDescription',
        locale: localeName,
      );

  String get signOutConfirmation => Intl.message(
        'Are you sure you want to sign out of your account?',
        name: 'signOutConfirmation',
        locale: localeName,
      );

  String get deleteAccountWarning => Intl.message(
        'This action cannot be undone. All your data will be permanently deleted.',
        name: 'deleteAccountWarning',
        locale: localeName,
      );

  // Home Page
  String get welcomeBack => Intl.message(
        'Welcome back,',
        name: 'welcomeBack',
        locale: localeName,
      );

  String get welcomeBackDefault => Intl.message(
        'Welcome back!',
        name: 'welcomeBackDefault',
        locale: localeName,
      );

  String get guardian => Intl.message(
        'Guardian',
        name: 'guardian',
        locale: localeName,
      );

  String get studentsLinked => Intl.message(
        'students linked',
        name: 'studentsLinked',
        locale: localeName,
      );

  String get studentLinked => Intl.message(
        'student linked',
        name: 'studentLinked',
        locale: localeName,
      );

  String get noStudentsLinked => Intl.message(
        'No students linked yet',
        name: 'noStudentsLinked',
        locale: localeName,
      );

  String get contactSchoolToLink => Intl.message(
        'Contact your school to link your children to your account',
        name: 'contactSchoolToLink',
        locale: localeName,
      );

  String get contactSupport => Intl.message(
        'Contact Support',
        name: 'contactSupport',
        locale: localeName,
      );

  String get active => Intl.message(
        'Active',
        name: 'active',
        locale: localeName,
      );

  String get leaveTime => Intl.message(
        'Leave Time',
        name: 'leaveTime',
        locale: localeName,
      );

  String get notMarked => Intl.message(
        'Not Marked',
        name: 'notMarked',
        locale: localeName,
      );

  String get present => Intl.message(
        'Present',
        name: 'present',
        locale: localeName,
      );

  String get absent => Intl.message(
        'Absent',
        name: 'absent',
        locale: localeName,
      );

  String get late => Intl.message(
        'Late',
        name: 'late',
        locale: localeName,
      );

  String get excused => Intl.message(
        'Excused',
        name: 'excused',
        locale: localeName,
      );

  String get pickupRequested => Intl.message(
        'Pickup Requested',
        name: 'pickupRequested',
        locale: localeName,
      );

  String get pickupRequestSent => Intl.message(
        'Pickup request sent for',
        name: 'pickupRequestSent',
        locale: localeName,
      );

  String get viewDetails => Intl.message(
        'Details',
        name: 'viewDetails',
        locale: localeName,
      );

  // Students Page
  String get searchStudents => Intl.message(
        'Search students...',
        name: 'searchStudents',
        locale: localeName,
      );

  String get all => Intl.message(
        'All',
        name: 'all',
        locale: localeName,
      );

  String get name => Intl.message(
        'Name',
        name: 'name',
        locale: localeName,
      );

  String get sortBy => Intl.message(
        'Sort by',
        name: 'sortBy',
        locale: localeName,
      );

  String get filter => Intl.message(
        'Filter',
        name: 'filter',
        locale: localeName,
      );

  String get class_ => Intl.message(
        'Class',
        name: 'class_',
        locale: localeName,
      );

  String get sortByName => Intl.message(
        'Sort by Name',
        name: 'sortByName',
        locale: localeName,
      );

  String get sortByGrade => Intl.message(
        'Sort by Grade',
        name: 'sortByGrade',
        locale: localeName,
      );

  String get confirm => Intl.message(
        'Confirm',
        name: 'confirm',
        locale: localeName,
      );

  // Additional Settings translations
  String get account => Intl.message(
        'Account',
        name: 'account',
        locale: localeName,
      );

  String get personalInfo => Intl.message(
        'Personal Info',
        name: 'personalInfo',
        locale: localeName,
      );

  String get managePersonalInfo => Intl.message(
        'Manage your personal information',
        name: 'managePersonalInfo',
        locale: localeName,
      );

  String get changePassword => Intl.message(
        'Change Password',
        name: 'changePassword',
        locale: localeName,
      );

  String get updatePassword => Intl.message(
        'Update your password',
        name: 'updatePassword',
        locale: localeName,
      );

  String get twoFactorAuth => Intl.message(
        'Two-Factor Authentication',
        name: 'twoFactorAuth',
        locale: localeName,
      );

  String get twoFactorAuthDescription => Intl.message(
        'Add an extra layer of security',
        name: 'twoFactorAuthDescription',
        locale: localeName,
      );

  String get setup2FA => Intl.message(
        'Set up two-factor authentication',
        name: 'setup2FA',
        locale: localeName,
      );

  String get dataPrivacy => Intl.message(
        'Data & Privacy',
        name: 'dataPrivacy',
        locale: localeName,
      );

  String get manageDataPrivacy => Intl.message(
        'Manage your data privacy settings',
        name: 'manageDataPrivacy',
        locale: localeName,
      );

  String get exportData => Intl.message(
        'Export Data',
        name: 'exportData',
        locale: localeName,
      );

  String get downloadData => Intl.message(
        'Download your data',
        name: 'downloadData',
        locale: localeName,
      );

  String get deleteAccount => Intl.message(
        'Delete Account',
        name: 'deleteAccount',
        locale: localeName,
      );

  String get permanentlyDelete => Intl.message(
        'Permanently delete your account',
        name: 'permanentlyDelete',
        locale: localeName,
      );

  // Support section
  String get support => Intl.message(
        'Support',
        name: 'support',
        locale: localeName,
      );

  String get helpCenter => Intl.message(
        'Help Center',
        name: 'helpCenter',
        locale: localeName,
      );

  String get findAnswers => Intl.message(
        'Find answers to common questions',
        name: 'findAnswers',
        locale: localeName,
      );

  String get getHelp => Intl.message(
        'Get help from our team',
        name: 'getHelp',
        locale: localeName,
      );

  String get reportBug => Intl.message(
        'Report a Bug',
        name: 'reportBug',
        locale: localeName,
      );

  String get reportIssue => Intl.message(
        'Report an issue with the app',
        name: 'reportIssue',
        locale: localeName,
      );

  String get privacyPolicy => Intl.message(
        'Privacy Policy',
        name: 'privacyPolicy',
        locale: localeName,
      );

  String get readPrivacyPolicy => Intl.message(
        'Read our privacy policy',
        name: 'readPrivacyPolicy',
        locale: localeName,
      );

  String get termsOfService => Intl.message(
        'Terms of Service',
        name: 'termsOfService',
        locale: localeName,
      );

  String get readTerms => Intl.message(
        'Read our terms of service',
        name: 'readTerms',
        locale: localeName,
      );

  String get about => Intl.message(
        'About',
        name: 'about',
        locale: localeName,
      );

  String get aboutApp => Intl.message(
        'About the app and version info',
        name: 'aboutApp',
        locale: localeName,
      );

  // About section
  String get aboutTitle => Intl.message(
        'About App',
        name: 'aboutTitle',
        locale: localeName,
      );

  String get appVersion => Intl.message(
        'App Version',
        name: 'appVersion',
        locale: localeName,
      );

  String get buildNumber => Intl.message(
        'Build Number',
        name: 'buildNumber',
        locale: localeName,
      );

  String get developer => Intl.message(
        'Developer',
        name: 'developer',
        locale: localeName,
      );

  String get website => Intl.message(
        'Website',
        name: 'website',
        locale: localeName,
      );

  String get email => Intl.message(
        'Email',
        name: 'email',
        locale: localeName,
      );

  String get followUs => Intl.message(
        'Follow Us',
        name: 'followUs',
        locale: localeName,
      );

  String get rateApp => Intl.message(
        'Rate App',
        name: 'rateApp',
        locale: localeName,
      );

  String get shareApp => Intl.message(
        'Share App',
        name: 'shareApp',
        locale: localeName,
      );

  String get checkUpdates => Intl.message(
        'Check for Updates',
        name: 'checkUpdates',
        locale: localeName,
      );

  // Navigation and common
  String get myProfile => Intl.message(
        'My Profile',
        name: 'myProfile',
        locale: localeName,
      );

  String get accountSettings => Intl.message(
        'Account Settings',
        name: 'accountSettings',
        locale: localeName,
      );

  String get appSettings => Intl.message(
        'App Settings',
        name: 'appSettings',
        locale: localeName,
      );

  String get helpSupport => Intl.message(
        'Help & Support',
        name: 'helpSupport',
        locale: localeName,
      );

  String get emergencyContact => Intl.message(
        'Emergency Contact',
        name: 'emergencyContact',
        locale: localeName,
      );

  String get signOutConfirm => Intl.message(
        'Are you sure you want to sign out?',
        name: 'signOutConfirm',
        locale: localeName,
      );
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.contains(locale);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'ar':
        return AppLocalizationsAr();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

Future<bool> initializeMessages(String localeName) async {
  // This would normally load from ARB files, but for simplicity
  // we'll use hardcoded translations for now
  return true;
}
