import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialized = false;
  bool _isInitializing = false;

  // Initialize notification service
  Future<void> initialize() async {
    // Prevent multiple initializations
    if (_isInitialized || _isInitializing) {
      return;
    }
    
    _isInitializing = true;
    
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
        
        // Get FCM token and save to user document
        await _updateFCMToken();
        
        // Listen for token refresh (only once)
        if (!_isInitialized) {
          _messaging.onTokenRefresh.listen(_saveFCMToken);
          _configureMessageHandlers();
        }
        
        _isInitialized = true;
      } else {
        print('User declined or has not accepted permission');
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    } finally {
      _isInitializing = false;
    }
  }

  // Update FCM token in user document
  Future<void> _updateFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await _messaging.getToken();
        if (token != null) {
          await _saveFCMToken(token);
        }
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('FCM token saved: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Configure message handlers
  void _configureMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Opened app from notification: ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    // Handle messages when app is opened from terminated state
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('Opened app from terminated state: ${message.notification?.title}');
        _handleNotificationTap(message);
      }
    });
  }

  // Show local notification when app is in foreground
  void _showLocalNotification(RemoteMessage message) {
    // For now, we'll save to Firestore notifications collection
    // In a production app, you'd use flutter_local_notifications
    _saveNotificationToFirestore(message);
  }

  // Save notification to Firestore for display in notifications screen
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('notifications').add({
          'recipientId': user.uid,
          'title': message.notification?.title ?? 'Notification',
          'message': message.notification?.body ?? '',
          'type': message.data['type'] ?? 'general',
          'grade': message.data['grade'],
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'priority': message.data['priority'] ?? 'normal',
          'data': message.data,
        });
      }
    } catch (e) {
      print('Error saving notification to Firestore: $e');
    }
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    // Navigate to appropriate screen based on notification type
    final type = message.data['type'];
    print('Handling notification tap for type: $type');
    
    // You can add navigation logic here
    // For example: navigatorKey.currentState?.pushNamed('/notifications');
  }

  // Get user's notifications from Firestore
  Stream<QuerySnapshot> getUserNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots();
    }
    return const Stream.empty();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final unreadNotifications = await _firestore
            .collection('notifications')
            .where('recipientId', isEqualTo: user.uid)
            .where('read', isEqualTo: false)
            .get();

        final batch = _firestore.batch();
        for (var doc in unreadNotifications.docs) {
          batch.update(doc.reference, {
            'read': true,
            'readAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final unreadNotifications = await _firestore
            .collection('notifications')
            .where('recipientId', isEqualTo: user.uid)
            .where('read', isEqualTo: false)
            .get();
        return unreadNotifications.docs.length;
      }
    } catch (e) {
      print('Error getting unread count: $e');
    }
    return 0;
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.notification?.title}');
  // Handle background message here
}
