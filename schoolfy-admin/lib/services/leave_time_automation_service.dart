import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LeaveTimeAutomationService {
  static final LeaveTimeAutomationService _instance = LeaveTimeAutomationService._internal();
  factory LeaveTimeAutomationService() => _instance;
  LeaveTimeAutomationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _automationTimer;
  bool _isRunning = false;

  /// Start the automation service
  void startAutomation() {
    if (_isRunning) return;
    
    _isRunning = true;
    
    // Check every minute for scheduled leave times
    _automationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkScheduledLeaveTimes();
    });
    
    if (kDebugMode) {
      print('Leave Time Automation Service started');
    }
  }

  /// Stop the automation service
  void stopAutomation() {
    _automationTimer?.cancel();
    _isRunning = false;
    
    if (kDebugMode) {
      print('Leave Time Automation Service stopped');
    }
  }

  /// Check if the service is running
  bool get isRunning => _isRunning;

  /// Check for scheduled leave times and process them
  Future<void> _checkScheduledLeaveTimes() async {
    try {
      // Check if global automation is enabled
      final globalSettings = await _firestore.collection('settings').doc('leave_time_automation').get();
      if (!globalSettings.exists || globalSettings.data()?['enabled'] != true) {
        return;
      }

      final now = DateTime.now();
      final currentTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);

      // Get all grades with auto-notification enabled
      final gradesSnapshot = await _firestore
          .collection('grade_leave_times')
          .where('autoNotificationEnabled', isEqualTo: true)
          .where('status', isEqualTo: 'not_sent')
          .get();

      for (final gradeDoc in gradesSnapshot.docs) {
        final gradeData = gradeDoc.data();
        final scheduledTime = gradeData['scheduledTime'] as Timestamp?;
        
        if (scheduledTime != null) {
          final scheduledDateTime = scheduledTime.toDate();
          final scheduledTimeOnly = DateTime(
            scheduledDateTime.year,
            scheduledDateTime.month,
            scheduledDateTime.day,
            scheduledDateTime.hour,
            scheduledDateTime.minute,
          );

          // Check if it's time to send the notification
          if (scheduledTimeOnly.isAtSameMomentAs(currentTime) ||
              scheduledTimeOnly.isBefore(currentTime)) {
            await _processAutomaticLeaveTime(gradeDoc.id, gradeData);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in automation service: $e');
      }
    }
  }

  /// Process automatic leave time for a grade
  Future<void> _processAutomaticLeaveTime(String grade, Map<String, dynamic> gradeData) async {
    try {
      final now = DateTime.now();
      
      if (kDebugMode) {
        print('Processing automatic leave time for $grade');
      }

      // Update grade status
      await _firestore.collection('grade_leave_times').doc(grade).update({
        'status': 'sent',
        'leaveTime': Timestamp.fromDate(now),
        'lastSent': Timestamp.fromDate(now),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get all students in this grade
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('grade', isEqualTo: grade)
          .get();

      // Update all students in this grade
      final batch = _firestore.batch();
      for (var doc in studentsSnapshot.docs) {
        batch.update(doc.reference, {
          'leaveStatus': 'left',
          'leaveTime': Timestamp.fromDate(now),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // Send notifications to guardians
      await _sendAutomaticNotifications(grade, gradeData['customNote'] ?? '', studentsSnapshot.docs.length);

      // Log to history
      await _firestore.collection('leave_time_history').add({
        'grade': grade,
        'action': 'Auto-Sent',
        'studentsNotified': studentsSnapshot.docs.length,
        'adminName': 'System (Automated)',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('Automatic leave time processed for $grade (${studentsSnapshot.docs.length} students)');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error processing automatic leave time for $grade: $e');
      }
    }
  }

  /// Send automatic notifications to guardians
  Future<void> _sendAutomaticNotifications(String grade, String customNote, int studentCount) async {
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

      // Create notification for each guardian
      final batch = _firestore.batch();
      for (String guardianId in guardianIds) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'recipientId': guardianId,
          'title': '$grade Automatic Dismissal',
          'message': customNote.isNotEmpty 
              ? '$grade students have been automatically dismissed. $customNote'
              : '$grade students have been automatically dismissed. Please arrange pickup.',
          'type': 'automatic_leave_time',
          'grade': grade,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'priority': 'high',
          'automated': true,
        });
      }

      await batch.commit();

      if (kDebugMode) {
        print('Sent automatic notifications to ${guardianIds.length} guardians for $grade');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error sending automatic notifications: $e');
      }
    }
  }

  /// Manual trigger for testing purposes
  Future<void> testAutomation() async {
    if (kDebugMode) {
      print('Testing automation service...');
      await _checkScheduledLeaveTimes();
    }
  }

  /// Get automation status
  Future<Map<String, dynamic>> getAutomationStatus() async {
    try {
      final globalSettings = await _firestore.collection('settings').doc('leave_time_automation').get();
      final gradesSnapshot = await _firestore
          .collection('grade_leave_times')
          .where('autoNotificationEnabled', isEqualTo: true)
          .get();

      final globalData = globalSettings.data();
      return {
        'isServiceRunning': _isRunning,
        'globalEnabled': globalSettings.exists && globalData != null ? globalData['enabled'] ?? false : false,
        'automatedGradesCount': gradesSnapshot.docs.length,
        'lastCheck': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'isServiceRunning': _isRunning,
        'error': e.toString(),
      };
    }
  }

  /// Schedule a one-time leave time notification
  Future<void> scheduleOneTimeNotification(String grade, DateTime scheduledTime, String customNote) async {
    try {
      await _firestore.collection('scheduled_notifications').add({
        'grade': grade,
        'scheduledTime': Timestamp.fromDate(scheduledTime),
        'customNote': customNote,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('Scheduled one-time notification for $grade at ${scheduledTime.toString()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling one-time notification: $e');
      }
    }
  }

  /// Cancel scheduled notification
  Future<void> cancelScheduledNotification(String grade) async {
    try {
      final scheduledDocs = await _firestore
          .collection('scheduled_notifications')
          .where('grade', isEqualTo: grade)
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = _firestore.batch();
      for (var doc in scheduledDocs.docs) {
        batch.update(doc.reference, {'status': 'cancelled'});
      }
      await batch.commit();

      if (kDebugMode) {
        print('Cancelled scheduled notifications for $grade');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling scheduled notification: $e');
      }
    }
  }
}
