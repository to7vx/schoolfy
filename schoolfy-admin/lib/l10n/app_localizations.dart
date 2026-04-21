import 'package:flutter/material.dart';

abstract class AppLocalizations {
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  // Auth
  String get signIn;
  String get signOut;
  String get email;
  String get password;
  String get phoneNumber;
  String get verificationCode;
  String get forgotPassword;
  String get resetPassword;
  String get accessDenied;
  String get adminAccessRequired;
  String get createAdminAccount;
  String get createAccount;

  // Dashboard
  String get dashboard;
  String get home;
  String get students;
  String get guardians;
  String get pickupQueue;
  String get history;
  String get settings;

  // Students
  String get studentManagement;
  String get addStudent;
  String get editStudent;
  String get deleteStudent;
  String get studentName;
  String get grade;
  String get guardianPhone;
  String get schoolId;
  String get status;

  // Guardians
  String get guardianLinking;
  String get authorizedGuardians;
  String get linkGuardian;
  String get unlinkGuardian;
  String get guardianName;
  String get relationship;

  // Pickup Queue
  String get livePickupQueue;
  String get clearEntry;
  String get clearAll;
  String get requestedAt;
  String get waitingTime;

  // History
  String get pickupHistory;
  String get exportLogs;
  String get filterByDate;
  String get filterByGrade;

  // Common
  String get save;
  String get cancel;
  String get delete;
  String get edit;
  String get view;
  String get search;
  String get filter;
  String get export;
  String get refresh;
  String get loading;
  String get error;
  String get success;
  String get warning;
  String get language;
  String get arabic;
  String get english;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.contains(locale);
  }

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

class AppLocalizationsEn extends AppLocalizations {
  @override
  String get signIn => 'Sign In';
  @override
  String get signOut => 'Sign Out';
  @override
  String get email => 'Email';
  @override
  String get password => 'Password';
  @override
  String get phoneNumber => 'Phone Number';
  @override
  String get verificationCode => 'Verification Code';
  @override
  String get forgotPassword => 'Forgot Password?';
  @override
  String get resetPassword => 'Reset Password';
  @override
  String get accessDenied => 'Access Denied';
  @override
  String get adminAccessRequired => 'Administrator access required to use this dashboard.';
  @override
  String get createAdminAccount => 'Create Admin Account';
  @override
  String get createAccount => 'Create Account';

  @override
  String get dashboard => 'Dashboard';
  @override
  String get home => 'Home';
  @override
  String get students => 'Students';
  @override
  String get guardians => 'Guardians';
  @override
  String get pickupQueue => 'Pickup Queue';
  @override
  String get history => 'History';
  @override
  String get settings => 'Settings';

  @override
  String get studentManagement => 'Student Management';
  @override
  String get addStudent => 'Add Student';
  @override
  String get editStudent => 'Edit Student';
  @override
  String get deleteStudent => 'Delete Student';
  @override
  String get studentName => 'Student Name';
  @override
  String get grade => 'Grade';
  @override
  String get guardianPhone => 'Guardian Phone';
  @override
  String get schoolId => 'School ID';
  @override
  String get status => 'Status';

  @override
  String get guardianLinking => 'Guardian Linking';
  @override
  String get authorizedGuardians => 'Authorized Guardians';
  @override
  String get linkGuardian => 'Link Guardian';
  @override
  String get unlinkGuardian => 'Unlink Guardian';
  @override
  String get guardianName => 'Guardian Name';
  @override
  String get relationship => 'Relationship';

  @override
  String get livePickupQueue => 'Live Pickup Queue';
  @override
  String get clearEntry => 'Clear Entry';
  @override
  String get clearAll => 'Clear All';
  @override
  String get requestedAt => 'Requested At';
  @override
  String get waitingTime => 'Waiting Time';

  @override
  String get pickupHistory => 'Pickup History';
  @override
  String get exportLogs => 'Export Logs';
  @override
  String get filterByDate => 'Filter by Date';
  @override
  String get filterByGrade => 'Filter by Grade';

  @override
  String get save => 'Save';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String get view => 'View';
  @override
  String get search => 'Search';
  @override
  String get filter => 'Filter';
  @override
  String get export => 'Export';
  @override
  String get refresh => 'Refresh';
  @override
  String get loading => 'Loading...';
  @override
  String get error => 'Error';
  @override
  String get success => 'Success';
  @override
  String get warning => 'Warning';
  @override
  String get language => 'Language';
  @override
  String get arabic => 'العربية';
  @override
  String get english => 'English';
}

class AppLocalizationsAr extends AppLocalizations {
  @override
  String get signIn => 'تسجيل الدخول';
  @override
  String get signOut => 'تسجيل الخروج';
  @override
  String get email => 'البريد الإلكتروني';
  @override
  String get password => 'كلمة المرور';
  @override
  String get phoneNumber => 'رقم الهاتف';
  @override
  String get verificationCode => 'رمز التحقق';
  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';
  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';
  @override
  String get accessDenied => 'تم رفض الوصول';
  @override
  String get adminAccessRequired => 'يتطلب وصول المدير لاستخدام هذه اللوحة.';
  @override
  String get createAdminAccount => 'إنشاء حساب مدير';
  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get dashboard => 'لوحة التحكم';
  @override
  String get home => 'الرئيسية';
  @override
  String get students => 'الطلاب';
  @override
  String get guardians => 'أولياء الأمور';
  @override
  String get pickupQueue => 'قائمة الاستلام';
  @override
  String get history => 'السجل';
  @override
  String get settings => 'الإعدادات';

  @override
  String get studentManagement => 'إدارة الطلاب';
  @override
  String get addStudent => 'إضافة طالب';
  @override
  String get editStudent => 'تعديل الطالب';
  @override
  String get deleteStudent => 'حذف الطالب';
  @override
  String get studentName => 'اسم الطالب';
  @override
  String get grade => 'الصف';
  @override
  String get guardianPhone => 'هاتف ولي الأمر';
  @override
  String get schoolId => 'رقم المدرسة';
  @override
  String get status => 'الحالة';

  @override
  String get guardianLinking => 'ربط أولياء الأمور';
  @override
  String get authorizedGuardians => 'أولياء الأمور المصرح لهم';
  @override
  String get linkGuardian => 'ربط ولي الأمر';
  @override
  String get unlinkGuardian => 'إلغاء ربط ولي الأمر';
  @override
  String get guardianName => 'اسم ولي الأمر';
  @override
  String get relationship => 'صلة القرابة';

  @override
  String get livePickupQueue => 'قائمة الاستلام المباشرة';
  @override
  String get clearEntry => 'مسح الإدخال';
  @override
  String get clearAll => 'مسح الكل';
  @override
  String get requestedAt => 'وقت الطلب';
  @override
  String get waitingTime => 'وقت الانتظار';

  @override
  String get pickupHistory => 'سجل الاستلام';
  @override
  String get exportLogs => 'تصدير السجلات';
  @override
  String get filterByDate => 'تصفية حسب التاريخ';
  @override
  String get filterByGrade => 'تصفية حسب الصف';

  @override
  String get save => 'حفظ';
  @override
  String get cancel => 'إلغاء';
  @override
  String get delete => 'حذف';
  @override
  String get edit => 'تعديل';
  @override
  String get view => 'عرض';
  @override
  String get search => 'بحث';
  @override
  String get filter => 'تصفية';
  @override
  String get export => 'تصدير';
  @override
  String get refresh => 'تحديث';
  @override
  String get loading => 'جاري التحميل...';
  @override
  String get error => 'خطأ';
  @override
  String get success => 'نجح';
  @override
  String get warning => 'تحذير';
  @override
  String get language => 'اللغة';
  @override
  String get arabic => 'العربية';
  @override
  String get english => 'English';
}
