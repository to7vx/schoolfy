import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/auth/phone_auth_screen.dart';
import 'screens/home_page.dart';
import 'screens/students_page.dart';
import 'screens/authorized_guardians_page.dart';
import 'screens/settings_page.dart';
import 'screens/profile_setup_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schoolfy Guardian',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Schoolfy',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PhoneAuthScreen()),
                );
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
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
                  
                  // Now get the linked students for this guardian
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


