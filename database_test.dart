import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Simple test function to verify Firebase Realtime Database connection
Future<void> testDatabaseConnection() async {
  try {
    final database = FirebaseDatabase.instance.ref();
    final user = FirebaseAuth.instance.currentUser;
    
    print('Testing database connection...');
    print('Current user: ${user?.uid}');
    print('User authenticated: ${user != null}');
    
    // Try to write a simple test value
    await database.child('test').child('connection').set({
      'timestamp': DateTime.now().toIso8601String(),
      'user': user?.uid ?? 'anonymous',
      'message': 'Database connection test'
    });
    
    print('✅ Database write test successful!');
    
    // Try to read the value back
    final snapshot = await database.child('test').child('connection').get();
    if (snapshot.exists) {
      print('✅ Database read test successful!');
      print('Data: ${snapshot.value}');
    } else {
      print('❌ Database read test failed - no data found');
    }
    
  } catch (e) {
    print('❌ Database test failed: $e');
  }
}

// Call this function to test your database connection
// You can add this to your HomePage's initState for testing
