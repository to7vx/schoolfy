import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/auth/phone_auth_screen.dart';
import 'screens/main_nav_screen.dart';


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
    );
  }




}

// Placeholder for Welcome/Language Selection screen
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

// AuthGate widget: Shows HomePage if logged in, else WelcomeScreen
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
          
          // Automatically link guardian to students based on phone number
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
                      
                      return MainNavScreen(students: students);
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

      print('Starting linking process for phone: $phoneNumber');

      // Check if guardian user document exists
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
        print('Existing guardian found with ID: $guardianId, current linked students: $currentLinkedStudents');
      } else {
        // Generate new guardian ID for new user
        guardianId = _generateGuardianId();
        print('Creating new guardian with ID: $guardianId');
      }

      // Query students collection for matching guardian phone
      final studentsQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('guardianPhone', isEqualTo: phoneNumber)
          .get();

      print('Found ${studentsQuery.docs.length} students matching phone number');

      final batch = FirebaseFirestore.instance.batch();
      final newLinkedStudents = List<String>.from(currentLinkedStudents);

      for (final studentDoc in studentsQuery.docs) {
        final studentData = studentDoc.data();
        final studentId = studentDoc.id;
        final studentName = studentData['name'] ?? 'Unknown';

        print('Processing student: $studentName (ID: $studentId)');
        print('Current primaryGuardianId: ${studentData['primaryGuardianId']}');
        print('Current status: ${studentData['status']}');

        // Check if student is already linked to another guardian
        if (studentData['primaryGuardianId'] != null && 
            studentData['primaryGuardianId'] != guardianId) {
          print('Student $studentName is already linked to another guardian: ${studentData['primaryGuardianId']}');
          continue;
        }

        // Link student to guardian
        if (!newLinkedStudents.contains(studentId)) {
          newLinkedStudents.add(studentId);
          print('Added student $studentName to linked students list');
        } else {
          print('Student $studentName already in linked students list');
        }

        // Update student document
        final studentRef = FirebaseFirestore.instance
            .collection('students')
            .doc(studentId);
            
        print('Adding batch update for student: $studentName -> Guardian: $guardianId');
        batch.update(studentRef, {
          'primaryGuardianId': guardianId,
          'status': 'linked',
          'linkedAt': FieldValue.serverTimestamp(),
        });
      }

      // Handle guardian document creation or update
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      if (userExists) {
        // Update existing guardian document
        batch.update(userRef, {
          'linkedStudents': newLinkedStudents,
          'guardianId': guardianId,
          'lastLinkCheck': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new guardian document
        batch.set(userRef, {
          'uid': user.uid,
          'guardianId': guardianId,
          'phone': phoneNumber,
          'linkedStudents': newLinkedStudents,
          'role': 'guardian',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLinkCheck': FieldValue.serverTimestamp(),
        });
      }

      // Commit all changes
      print('Committing batch with ${newLinkedStudents.length} students...');
      await batch.commit();
      print('Batch committed successfully');

      // Verify the changes were applied
      print('Verifying student updates...');
      for (final studentDoc in studentsQuery.docs) {
        final studentId = studentDoc.id;
        final studentName = studentDoc.data()['name'] ?? 'Unknown';
        
        try {
          final updatedStudent = await FirebaseFirestore.instance
              .collection('students')
              .doc(studentId)
              .get();
              
          if (updatedStudent.exists) {
            final updatedData = updatedStudent.data()!;
            print('Verified $studentName: primaryGuardianId = ${updatedData['primaryGuardianId']}, status = ${updatedData['status']}');
          } else {
            print('ERROR: Student $studentName not found after update');
          }
        } catch (e) {
          print('ERROR verifying student $studentName: $e');
        }
      }

      print('Successfully linked ${newLinkedStudents.length} students to guardian $guardianId');
      print('Final linked students: $newLinkedStudents');
      
    } catch (e) {
      print('Error linking guardian to students: $e');
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


