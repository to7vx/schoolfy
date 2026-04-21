import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminNotificationService {
  static final AdminNotificationService _instance = AdminNotificationService._internal();
  factory AdminNotificationService() => _instance;
  AdminNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // NOTE: In a production app, this should be handled by Firebase Functions
  // This is a simplified version for demonstration
  static const String _serverKey = 'YOUR_FIREBASE_SERVER_KEY'; // Replace with actual key

  /// Send push notification to specific guardians for a grade
  Future<void> sendGradeLeaveTimeNotification({
    required String grade,
    required String customNote,
  }) async {
    try {
      // Get all students in this grade
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('grade', isEqualTo: grade)
          .get();

      // Get all unique guardian IDs
      Set<String> guardianIds = {};
      for (var doc in studentsSnapshot.docs) {
        final student = doc.data();
        final primaryGuardianId = student['primaryGuardianId'];
        if (primaryGuardianId != null && primaryGuardianId.isNotEmpty) {
          guardianIds.add(primaryGuardianId);
        }
        final authorizedIds = List<String>.from(student['authorizedGuardianIds'] ?? []);
        guardianIds.addAll(authorizedIds.where((id) => id.isNotEmpty));
      }

      // Get FCM tokens for all guardians
      final List<String> fcmTokens = [];
      for (String guardianId in guardianIds) {
        final userDoc = await _firestore.collection('users').doc(guardianId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          final fcmToken = userData?['fcmToken'];
          if (fcmToken != null && fcmToken.isNotEmpty) {
            fcmTokens.add(fcmToken);
          }
        }
      }

      if (fcmTokens.isEmpty) {
        print('No FCM tokens found for guardians in grade $grade');
        return;
      }

      // Create notification message
      final title = '$grade Dismissal Notice';
      final message = customNote.isNotEmpty 
          ? '$grade students are being dismissed. $customNote'
          : '$grade students are being dismissed. Please arrange pickup.';

      // Save notifications to Firestore first
      await _saveNotificationsToFirestore(
        guardianIds: guardianIds,
        title: title,
        message: message,
        grade: grade,
      );

      // Send FCM notifications
      await _sendFCMNotification(
        tokens: fcmTokens,
        title: title,
        message: message,
        data: {
          'type': 'leave_time',
          'grade': grade,
          'priority': 'high',
        },
      );

      print('Sent notifications to ${guardianIds.length} guardians (${fcmTokens.length} tokens) for $grade');

    } catch (e) {
      print('Error sending grade leave time notification: $e');
      rethrow;
    }
  }

  /// Send custom notification to all guardians
  Future<void> sendCustomNotificationToAll(String message) async {
    try {
      // Get all guardians
      final guardiansSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'guardian')
          .get();

      final List<String> fcmTokens = [];
      final Set<String> guardianIds = {};

      for (var doc in guardiansSnapshot.docs) {
        final userData = doc.data();
        guardianIds.add(doc.id);
        
        final fcmToken = userData['fcmToken'];
        if (fcmToken != null && fcmToken.isNotEmpty) {
          fcmTokens.add(fcmToken);
        }
      }

      if (fcmTokens.isEmpty) {
        print('No FCM tokens found for guardians');
        return;
      }

      // Save notifications to Firestore
      await _saveNotificationsToFirestore(
        guardianIds: guardianIds,
        title: 'School Announcement',
        message: message,
        grade: null,
        type: 'announcement',
      );

      // Send FCM notifications
      await _sendFCMNotification(
        tokens: fcmTokens,
        title: 'School Announcement',
        message: message,
        data: {
          'type': 'announcement',
          'priority': 'normal',
        },
      );

      print('Sent custom notification to ${guardianIds.length} guardians (${fcmTokens.length} tokens)');

    } catch (e) {
      print('Error sending custom notification: $e');
      rethrow;
    }
  }

  /// Save notifications to Firestore
  Future<void> _saveNotificationsToFirestore({
    required Set<String> guardianIds,
    required String title,
    required String message,
    required String? grade,
    String type = 'leave_time',
  }) async {
    final batch = _firestore.batch();
    final currentUser = FirebaseAuth.instance.currentUser;
    
    for (String guardianId in guardianIds) {
      final notificationRef = _firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'recipientId': guardianId,
        'title': title,
        'message': message,
        'type': type,
        'grade': grade,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'priority': type == 'leave_time' ? 'high' : 'normal',
        'sentBy': currentUser?.email ?? 'admin@schoolfy.com',
        'sentById': currentUser?.uid,
      });
    }

    await batch.commit();
  }

  /// Send FCM notification using HTTP API
  /// NOTE: In production, this should be done through Firebase Functions for security
  Future<void> _sendFCMNotification({
    required List<String> tokens,
    required String title,
    required String message,
    required Map<String, String> data,
  }) async {
    // Skip FCM sending in development if no server key is configured
    if (_serverKey == 'YOUR_FIREBASE_SERVER_KEY') {
      print('FCM server key not configured. Notifications saved to Firestore only.');
      return;
    }

    try {
      final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$_serverKey',
      };

      // Send to all tokens (for simplicity, sending individually)
      // In production, you'd batch these or use topic messaging
      for (String token in tokens) {
        final payload = {
          'to': token,
          'notification': {
            'title': title,
            'body': message,
            'sound': 'default',
          },
          'data': data,
          'priority': 'high',
        };

        final response = await http.post(
          url,
          headers: headers,
          body: json.encode(payload),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['success'] == 1) {
            print('FCM notification sent successfully to token: ${token.substring(0, 20)}...');
          } else {
            print('FCM notification failed: ${responseData['results']}');
          }
        } else {
          print('FCM HTTP request failed: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('Error sending FCM notification: $e');
    }
  }

  /// Send emergency notification
  Future<void> sendEmergencyNotification(String message) async {
    try {
      // Get all guardians
      final guardiansSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'guardian')
          .get();

      final List<String> fcmTokens = [];
      final Set<String> guardianIds = {};

      for (var doc in guardiansSnapshot.docs) {
        final userData = doc.data();
        guardianIds.add(doc.id);
        
        final fcmToken = userData['fcmToken'];
        if (fcmToken != null && fcmToken.isNotEmpty) {
          fcmTokens.add(fcmToken);
        }
      }

      // Save notifications to Firestore
      await _saveNotificationsToFirestore(
        guardianIds: guardianIds,
        title: '🚨 EMERGENCY ALERT',
        message: message,
        grade: null,
        type: 'emergency',
      );

      // Send high-priority FCM notifications
      if (fcmTokens.isNotEmpty) {
        await _sendFCMNotification(
          tokens: fcmTokens,
          title: '🚨 EMERGENCY ALERT',
          message: message,
          data: {
            'type': 'emergency',
            'priority': 'high',
          },
        );
      }

      print('Sent emergency notification to ${guardianIds.length} guardians');

    } catch (e) {
      print('Error sending emergency notification: $e');
      rethrow;
    }
  }
}
