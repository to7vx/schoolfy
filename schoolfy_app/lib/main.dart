import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/auth/phone_auth_screen.dart';
import 'screens/home_page.dart';
import 'screens/students_page.dart';
import 'screens/authorized_guardians_page.dart';
import 'screens/settings_page.dart';
import 'screens/profile_setup_page.dart';
import 'services/notification_service.dart';
import 'l10n/app_localizations.dart';
import 'providers/language_provider.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => LanguageProvider()..initialize(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          title: 'Schoolfy Guardian',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          locale: languageProvider.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('ar', ''),
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale?.languageCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
          home: const AuthGate(),
          routes: {
            '/profile-setup': (context) => const ProfileSetupPage(),
            '/main': (context) => const AuthGate(),
          },
        );
      },
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1), // Indigo
              Color(0xFF8B5CF6), // Purple
              Color(0xFFA855F7), // Purple
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        
                        // App Logo/Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // App Title
                        const Text(
                          'Schoolfy',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Subtitle
                        Text(
                          'Guardian App',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.5,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        // Description
                        Text(
                          'Stay connected with your child\'s school pickup\nand manage authorized guardians',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                        
                        const Spacer(flex: 3),
                        
                        // Get Started Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      const PhoneAuthScreen(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(1.0, 0.0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6366F1),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Features Preview
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildFeatureItem(Icons.notifications_active, 'Real-time\nNotifications'),
                            _buildFeatureItem(Icons.people_alt, 'Authorized\nGuardians'),
                            _buildFeatureItem(Icons.security, 'Secure\n& Safe'),
                          ],
                        ),
                        
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          
          // Check if user profile is complete
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              
              final userData = userSnapshot.data?.data();
              final profileComplete = userData?['profileComplete'] ?? false;
              
              // If profile is not complete, redirect to profile setup
              if (!profileComplete) {
                return const ProfileSetupPage();
              }
              
              // Profile is complete, continue with student linking
              return FutureBuilder<void>(
                future: _linkGuardianToStudents(user),
                builder: (context, linkSnapshot) {
                  if (linkSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Linking to your students...'),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  if (linkSnapshot.hasError) {
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 48, color: Colors.red),
                            SizedBox(height: 16),
                            Text('Error linking students: ${linkSnapshot.error}'),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => FirebaseAuth.instance.signOut(),
                              child: Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  // get the linked students for this guardian
                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(body: Center(child: CircularProgressIndicator()));
                      }
                      
                      if (userSnapshot.hasError) {
                        return Scaffold(body: Center(child: Text('Error loading user data')));
                      }
                      
                      final userData = userSnapshot.data?.data();
                      final linkedStudentIds = List<String>.from(userData?['linkedStudents'] ?? []);
                      
                      if (linkedStudentIds.isEmpty) {
                        return Scaffold(
                          backgroundColor: AppTheme.backgroundColor,
                          appBar: AppBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            automaticallyImplyLeading: false,
                            actions: [
                              Container(
                                margin: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    try {
                                      await FirebaseAuth.instance.signOut();
                                      if (context.mounted) {
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                                          (route) => false,
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error signing out: $e'),
                                            backgroundColor: AppTheme.errorColor,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: Icon(
                                    Icons.logout_rounded,
                                    color: AppTheme.errorColor,
                                  ),
                                  tooltip: 'Sign Out',
                                ),
                              ),
                            ],
                          ),
                          body: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.spacingXXL),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Modern Icon Container
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(60),
                                    ),
                                    child: Icon(
                                      Icons.school_rounded,
                                      size: 60,
                                      color: AppTheme.primaryColor.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacingXXL),
                                  
                                  // Title
                                  Text(
                                    'No Students Linked Yet',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppTheme.spacingM),
                                  
                                  // Description
                                  Text(
                                    'Contact your school administrator to link your children to your account.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppTheme.textSecondary,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppTheme.spacingXXL),
                                  
                                  // Info Card
                                  Container(
                                    padding: const EdgeInsets.all(AppTheme.spacingL),
                                    decoration: BoxDecoration(
                                      color: AppTheme.infoColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                                      border: Border.all(
                                        color: AppTheme.infoColor.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppTheme.infoColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.info_outline_rounded,
                                            color: AppTheme.infoColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: AppTheme.spacingM),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'What to do next?',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Provide your phone number to your school\'s admin to get your children linked to this account.',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppTheme.textSecondary,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacingXXL),
                                  
                                  // Sign Out Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        try {
                                          await FirebaseAuth.instance.signOut();
                                          if (context.mounted) {
                                            Navigator.of(context).pushAndRemoveUntil(
                                              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                                              (route) => false,
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error signing out: $e'),
                                                backgroundColor: AppTheme.errorColor,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.errorColor,
                                        side: BorderSide(color: AppTheme.errorColor),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                        ),
                                      ),
                                      icon: const Icon(Icons.logout_rounded),
                                      label: const Text(
                                        'Sign Out & Try Different Account',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      
                      // Get student details for linked students
                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('students')
                            .where(FieldPath.documentId, whereIn: linkedStudentIds)
                            .snapshots(),
                        builder: (context, studentSnapshot) {
                          if (studentSnapshot.connectionState == ConnectionState.waiting) {
                            return const Scaffold(body: Center(child: CircularProgressIndicator()));
                          }
                          
                          if (studentSnapshot.hasError) {
                            return Scaffold(body: Center(child: Text('Error loading students')));
                          }
                          
                          final students = studentSnapshot.data?.docs.map((doc) {
                            final data = doc.data();
                            return {
                              'studentId': doc.id,
                              'studentName': data['name'] ?? '',
                              'grade': data['grade'] ?? '',
                              'schoolId': data['schoolId'] ?? '',
                            };
                          }).toList() ?? [];
                          
                          return _MainNavScreen(students: students);
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        }
        return const WelcomeScreen();
      },
    );
  }

  /// Automatically link guardian to students based on phone number
  Future<void> _linkGuardianToStudents(User user) async {
    try {
      final phoneNumber = user.phoneNumber;
      if (phoneNumber == null) {
        throw Exception('Phone number not available');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String guardianId;
      List<String> currentLinkedStudents = [];
      bool userExists = userDoc.exists;

      if (userExists) {
        // User exists, get current data
        final userData = userDoc.data()!;
        guardianId = userData['guardianId'] ?? _generateGuardianId();
        currentLinkedStudents = List<String>.from(userData['linkedStudents'] ?? []);
      } else {
        guardianId = _generateGuardianId();
      }

      // Query students collection for matching guardian phone
      final studentsQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('guardianPhone', isEqualTo: phoneNumber)
          .get();


      final batch = FirebaseFirestore.instance.batch();
      final newLinkedStudents = List<String>.from(currentLinkedStudents);

      for (final studentDoc in studentsQuery.docs) {
        final studentData = studentDoc.data();
        final studentId = studentDoc.id;

        if (studentData['primaryGuardianId'] != null && 
            studentData['primaryGuardianId'] != guardianId) {
          continue;
        }

        // Link student to guardian
        if (!newLinkedStudents.contains(studentId)) {
          newLinkedStudents.add(studentId);
        } else {
        }

        // Update student document
        final studentRef = FirebaseFirestore.instance
            .collection('students')
            .doc(studentId);
            
        batch.update(studentRef, {
          'primaryGuardianId': guardianId,
          'status': 'linked',
          'linkedAt': FieldValue.serverTimestamp(),
        });
      }

      // Handle guardian document creation or update
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      if (userExists) {
        // Update existing guardian document, preserve existing profile data
        batch.update(userRef, {
          'linkedStudents': newLinkedStudents,
          'guardianId': guardianId,
          'lastLinkCheck': FieldValue.serverTimestamp(),
          'phoneNumber': phoneNumber, // Ensure phone number is updated
        });
      } else {
        // Create new guardian document
        batch.set(userRef, {
          'uid': user.uid,
          'guardianId': guardianId,
          'phoneNumber': phoneNumber,
          'linkedStudents': newLinkedStudents,
          'role': 'guardian',
          'profileComplete': false, // New users need to complete profile
          'createdAt': FieldValue.serverTimestamp(),
          'lastLinkCheck': FieldValue.serverTimestamp(),
        });
      }

      // Commit all changes
      await batch.commit();
      
    } catch (e) {
      rethrow;
    }
  }

  /// Generate a unique guardian ID
  String _generateGuardianId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.toString().substring(timestamp.toString().length - 6);
    return 'GDN_$random';
  }
}

class _MainNavScreen extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  const _MainNavScreen({required this.students});

  @override
  State<_MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<_MainNavScreen> {
  int _selectedIndex = 0;
  static bool _notificationsInitialized = false; // Static to persist across rebuilds

  @override
  void initState() {
    super.initState();
    // Initialize notification service only once globally
    if (!_notificationsInitialized) {
      _initializeNotifications();
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      _notificationsInitialized = true;
      final notificationService = NotificationService();
      await notificationService.initialize();
    } catch (e) {
      print('Error initializing notifications: $e');
      _notificationsInitialized = false; // Reset on error so it can retry
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      HomePage(students: widget.students),
      const StudentsPage(),
      const AuthorizedGuardiansPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, l10n?.home ?? 'Home'),
                _buildNavItem(1, Icons.school_rounded, l10n?.students ?? 'Students'),
                _buildNavItem(2, Icons.group_rounded, l10n?.guardians ?? 'Guardians'),
                _buildNavItem(3, Icons.settings_rounded, l10n?.settings ?? 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


