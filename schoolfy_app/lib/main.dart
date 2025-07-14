import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/auth/phone_auth_screen.dart';
import 'screens/home_page.dart';
import 'screens/students_page.dart';
import 'screens/authorized_guardians_page.dart';
import 'screens/settings_page.dart';
import 'screens/profile_setup_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schoolfy Guardian',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
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
                        return const Scaffold(
                          body: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.school, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No linked students yet'),
                                SizedBox(height: 8),
                                Text('Contact your school administrator to link your children.',
                                    style: TextStyle(color: Colors.grey)),
                              ],
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

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(students: widget.students),
      const StudentsPage(),
      const AuthorizedGuardiansPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Guardians'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}


