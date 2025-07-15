import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class StudentLeaveTimeScreen extends StatefulWidget {
  const StudentLeaveTimeScreen({super.key});

  @override
  State<StudentLeaveTimeScreen> createState() => _StudentLeaveTimeScreenState();
}

class _StudentLeaveTimeScreenState extends State<StudentLeaveTimeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, TextEditingController> _noteControllers = {};
  final Map<String, TextEditingController> _timeControllers = {};
  bool _globalAutoNotification = false;

  final List<String> _grades = [
    '1A', '1B', '2A', '2B', '3A', '3B', '4A', '4B', '5A', '5B', '6A', '6B',
    'KG-A', 'KG-B', 'Pre-K-A', 'Pre-K-B'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadGlobalSettings();
  }

  void _initializeControllers() {
    for (String grade in _grades) {
      _noteControllers[grade] = TextEditingController();
      _timeControllers[grade] = TextEditingController();
    }
  }

  Future<void> _loadGlobalSettings() async {
    try {
      final doc = await _firestore.collection('settings').doc('leave_time_automation').get();
      if (doc.exists) {
        setState(() {
          _globalAutoNotification = doc.data()?['enabled'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading global settings: $e');
    }
  }

  @override
  void dispose() {
    for (var controller in _noteControllers.values) {
      controller.dispose();
    }
    for (var controller in _timeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule_send,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Student Leave Time Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildGlobalControls(),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Row
          _buildStatsRow(),
          const SizedBox(height: 24),

          // Grade Leave Time Management
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Grade List
                Expanded(
                  flex: 2,
                  child: _buildGradesList(),
                ),
                const SizedBox(width: 24),
                // History Panel
                Expanded(
                  flex: 1,
                  child: _buildHistoryPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Global Settings',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value: _globalAutoNotification,
                  onChanged: _toggleGlobalAutoNotification,
                  activeColor: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text('Enable Auto-Notification for All Grades'),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _sendCustomNotificationToAll,
              icon: const Icon(Icons.notifications_active, size: 16),
              label: const Text('Send Custom Alert'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('students').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        Map<String, int> gradeCounts = {};
        Map<String, int> leftCounts = {};

        for (var doc in snapshot.data!.docs) {
          final student = doc.data() as Map<String, dynamic>;
          final grade = student['grade'] ?? 'Unknown';
          final status = student['leaveStatus'] ?? 'in_school';
          
          gradeCounts[grade] = (gradeCounts[grade] ?? 0) + 1;
          if (status == 'left') {
            leftCounts[grade] = (leftCounts[grade] ?? 0) + 1;
          }
        }

        return Row(
          children: [
            _buildStatCard(
              'Total Students',
              '${snapshot.data!.docs.length}',
              Icons.people,
              AppTheme.primaryColor,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Students Left Today',
              '${leftCounts.values.fold(0, (a, b) => a + b)}',
              Icons.exit_to_app,
              AppTheme.successColor,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Still in School',
              '${gradeCounts.values.fold(0, (a, b) => a + b) - leftCounts.values.fold(0, (a, b) => a + b)}',
              Icons.school,
              AppTheme.warningColor,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Grades Active',
              '${gradeCounts.keys.length}',
              Icons.grade,
              AppTheme.accentColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradesList() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.class_, size: 20),
                SizedBox(width: 8),
                Text(
                  'Grade Leave Time Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: _grades.length,
              itemBuilder: (context, index) {
                return _buildGradeItem(_grades[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeItem(String grade) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('grade_leave_times').doc(grade).snapshots(),
      builder: (context, snapshot) {
        final gradeData = snapshot.hasData && snapshot.data!.exists
            ? snapshot.data!.data() as Map<String, dynamic>
            : <String, dynamic>{};

        final status = gradeData['status'] ?? 'not_sent';
        final autoEnabled = gradeData['autoNotificationEnabled'] ?? false;

        return ExpansionTile(
          leading: _buildStatusIndicator(status),
          title: Row(
            children: [
              Text(
                grade,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              _buildStatusChip(status),
              if (autoEnabled) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'AUTO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: _buildGradeSubtitle(gradeData, grade),
          children: [
            _buildGradeControls(grade, gradeData),
          ],
        );
      },
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'sent':
        color = AppTheme.successColor;
        icon = Icons.check_circle;
        break;
      case 'scheduled':
        color = AppTheme.warningColor;
        icon = Icons.schedule;
        break;
      default:
        color = Colors.grey;
        icon = Icons.radio_button_unchecked;
    }

    return Icon(icon, color: color);
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'sent':
        color = AppTheme.successColor;
        label = 'SENT';
        break;
      case 'scheduled':
        color = AppTheme.warningColor;
        label = 'SCHEDULED';
        break;
      default:
        color = Colors.grey;
        label = 'NOT SENT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildGradeSubtitle(Map<String, dynamic> gradeData, String grade) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('students')
          .where('grade', isEqualTo: grade)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Text('Loading...');

        final totalStudents = snapshot.data!.docs.length;
        final leftStudents = snapshot.data!.docs
            .where((doc) => (doc.data() as Map<String, dynamic>)['leaveStatus'] == 'left')
            .length;
        final inSchool = totalStudents - leftStudents;

        String timeText = '';
        if (gradeData['lastSent'] != null) {
          final lastSent = (gradeData['lastSent'] as Timestamp).toDate();
          timeText = ' • Last sent: ${_formatTime(lastSent)}';
        } else if (gradeData['scheduledTime'] != null) {
          final scheduled = (gradeData['scheduledTime'] as Timestamp).toDate();
          timeText = ' • Scheduled: ${_formatTime(scheduled)}';
        }

        return Text(
          '$inSchool/$totalStudents in school$timeText',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        );
      },
    );
  }

  Widget _buildGradeControls(String grade, Map<String, dynamic> gradeData) {
    _noteControllers[grade]?.text = gradeData['customNote'] ?? '';
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto-notification toggle
          Row(
            children: [
              Switch(
                value: gradeData['autoNotificationEnabled'] ?? false,
                onChanged: (value) => _toggleAutoNotification(grade, value),
                activeColor: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text('Enable Auto-Notification'),
              const Spacer(),
              if (gradeData['autoNotificationEnabled'] == true) ...[
                const Text('Scheduled: '),
                InkWell(
                  onTap: () => _showTimePicker(context, grade, true),
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _timeControllers[grade]?.text.isNotEmpty == true 
                                ? _timeControllers[grade]!.text 
                                : 'HH:MM',
                            style: TextStyle(
                              color: _timeControllers[grade]?.text.isNotEmpty == true 
                                  ? Colors.black87 
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Custom note
          TextFormField(
            controller: _noteControllers[grade],
            decoration: const InputDecoration(
              labelText: 'Custom Note (Optional)',
              border: OutlineInputBorder(),
              hintText: 'e.g., "Please pick up your child from the main entrance"',
            ),
            maxLines: 2,
            onChanged: (value) => _updateCustomNote(grade, value),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _setLeaveTimeNow(grade),
                icon: const Icon(Icons.access_time, size: 16),
                label: const Text('Set Time Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showTimePicker(context, grade, false),
                icon: const Icon(Icons.schedule, size: 16),
                label: const Text('Pick Custom Time'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _sendNotification(grade),
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Send Notification'),
              ),
              const SizedBox(width: 12),
              if (gradeData['status'] == 'sent')
                TextButton.icon(
                  onPressed: () => _resetGradeStatus(grade),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.history, size: 20),
                SizedBox(width: 8),
                Text(
                  'Leave Time History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('leave_time_history')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No leave time history yet'),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final history = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return _buildHistoryItem(history);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> history) {
    final timestamp = (history['timestamp'] as Timestamp).toDate();
    final grade = history['grade'] ?? 'Unknown';
    final action = history['action'] ?? 'Unknown';
    final adminName = history['adminName'] ?? 'System';
    final studentsCount = history['studentsNotified'] ?? 0;

    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _getActionColor(action).withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          _getActionIcon(action),
          size: 16,
          color: _getActionColor(action),
        ),
      ),
      title: Text(
        '$grade - $action',
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        '$studentsCount students • $adminName\n${_formatDateTime(timestamp)}',
        style: const TextStyle(fontSize: 11),
      ),
      isThreeLine: true,
    );
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'sent':
        return AppTheme.successColor;
      case 'scheduled':
        return AppTheme.warningColor;
      case 'reset':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'sent':
        return Icons.send;
      case 'scheduled':
        return Icons.schedule;
      case 'reset':
        return Icons.refresh;
      default:
        return Icons.info;
    }
  }

  // Action Methods
  Future<void> _toggleGlobalAutoNotification(bool value) async {
    try {
      await _firestore.collection('settings').doc('leave_time_automation').set({
        'enabled': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _globalAutoNotification = value;
      });
    } catch (e) {
      print('Error updating global setting: $e');
    }
  }

  Future<void> _toggleAutoNotification(String grade, bool value) async {
    try {
      await _firestore.collection('grade_leave_times').doc(grade).set({
        'autoNotificationEnabled': value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating auto notification: $e');
    }
  }

  Future<void> _updateScheduledTime(String grade, String time) async {
    try {
      if (time.isNotEmpty && time.contains(':')) {
        final parts = time.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          
          if (hour != null && minute != null && hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
            final now = DateTime.now();
            final scheduledDateTime = DateTime(now.year, now.month, now.day, hour, minute);
            
            await _firestore.collection('grade_leave_times').doc(grade).set({
              'scheduledTime': Timestamp.fromDate(scheduledDateTime),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }
      }
    } catch (e) {
      print('Error updating scheduled time: $e');
    }
  }

  Future<void> _showTimePicker(BuildContext context, String grade, bool isScheduled) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppTheme.primaryColor,
            colorScheme: ColorScheme.light(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      final timeString = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      _timeControllers[grade]?.text = timeString;
      
      if (isScheduled) {
        await _updateScheduledTime(grade, timeString);
      } else {
        await _setCustomLeaveTime(grade, selectedTime);
      }
    }
  }

  Future<void> _setCustomLeaveTime(String grade, TimeOfDay selectedTime) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final now = DateTime.now();
      final customDateTime = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
      final leaveTimeString = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      
      // Update grade status with custom time
      await _firestore.collection('grade_leave_times').doc(grade).set({
        'gradeId': grade,
        'leaveTime': leaveTimeString, // Mobile app expects string format like "09:30"
        'schoolId': 'SCH_001',
        'setBy': authProvider.user?.email ?? 'admin@schoolfy.com',
        'setAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'status': 'sent',
        'lastSent': Timestamp.fromDate(customDateTime),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update all students in this grade
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('grade', isEqualTo: grade)
          .get();

      final batch = _firestore.batch();
      for (var doc in studentsSnapshot.docs) {
        batch.update(doc.reference, {
          'leaveStatus': 'left',
          'leaveTime': Timestamp.fromDate(customDateTime),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // Send notification
      await _sendNotification(grade);

      // Log to history
      await _logToHistory(grade, 'Sent', studentsSnapshot.docs.length, authProvider.userData?['name'] ?? 'Admin');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave time set to ${selectedTime.format(context)} for Grade $grade'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error setting custom leave time: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error setting leave time'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateCustomNote(String grade, String note) async {
    try {
      await _firestore.collection('grade_leave_times').doc(grade).set({
        'customNote': note,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating custom note: $e');
    }
  }

  Future<void> _setLeaveTimeNow(String grade) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final now = DateTime.now();
      final leaveTimeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      // Update grade status
      await _firestore.collection('grade_leave_times').doc(grade).set({
        'gradeId': grade,
        'leaveTime': leaveTimeString, // Mobile app expects string format like "09:30"
        'schoolId': 'SCH_001',
        'setBy': authProvider.user?.email ?? 'admin@schoolfy.com',
        'setAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'status': 'sent',
        'lastSent': Timestamp.fromDate(now),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update all students in this grade
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('grade', isEqualTo: grade)
          .get();

      final batch = _firestore.batch();
      for (var doc in studentsSnapshot.docs) {
        batch.update(doc.reference, {
          'leaveStatus': 'left',
          'leaveTime': Timestamp.fromDate(now),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // Send notification
      await _sendNotification(grade);

      // Log to history
      await _logToHistory(grade, 'Sent', studentsSnapshot.docs.length, authProvider.userData?['name'] ?? 'Admin');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave time set for $grade (${studentsSnapshot.docs.length} students)'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      print('Error setting leave time: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting leave time: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendNotification(String grade) async {
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

      // Get custom note
      final gradeDoc = await _firestore.collection('grade_leave_times').doc(grade).get();
      final gradeData = gradeDoc.data();
      final customNote = gradeDoc.exists && gradeData != null ? gradeData['customNote'] ?? '' : '';

      // Create notification for each guardian
      final batch = _firestore.batch();
      for (String guardianId in guardianIds) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'recipientId': guardianId,
          'title': '$grade Dismissal Notice',
          'message': customNote.isNotEmpty 
              ? '$grade students are being dismissed. $customNote'
              : '$grade students are being dismissed. Please arrange pickup.',
          'type': 'leave_time',
          'grade': grade,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'priority': 'high',
        });
      }

      await batch.commit();

      print('Sent notifications to ${guardianIds.length} guardians for $grade');

    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> _sendCustomNotificationToAll() async {
    showDialog(
      context: context,
      builder: (context) => _CustomNotificationDialog(
        onSend: (message) async {
          try {
            // Get all guardians
            final guardiansSnapshot = await _firestore
                .collection('users')
                .where('role', isEqualTo: 'guardian')
                .get();

            final batch = _firestore.batch();
            for (var doc in guardiansSnapshot.docs) {
              final notificationRef = _firestore.collection('notifications').doc();
              batch.set(notificationRef, {
                'recipientId': doc.id,
                'title': 'School Announcement',
                'message': message,
                'type': 'custom_alert',
                'timestamp': FieldValue.serverTimestamp(),
                'read': false,
                'priority': 'high',
              });
            }

            await batch.commit();

            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            await _logToHistory('All Grades', 'Custom Alert', guardiansSnapshot.docs.length, authProvider.userData?['name'] ?? 'Admin');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Custom notification sent to ${guardiansSnapshot.docs.length} guardians'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          } catch (e) {
            print('Error sending custom notification: $e');
          }
        },
      ),
    );
  }

  Future<void> _resetGradeStatus(String grade) async {
    try {
      await _firestore.collection('grade_leave_times').doc(grade).set({
        'status': 'not_sent',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Reset all students in this grade
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('grade', isEqualTo: grade)
          .get();

      final batch = _firestore.batch();
      for (var doc in studentsSnapshot.docs) {
        batch.update(doc.reference, {
          'leaveStatus': 'in_school',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await _logToHistory(grade, 'Reset', studentsSnapshot.docs.length, authProvider.userData?['name'] ?? 'Admin');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$grade status reset'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    } catch (e) {
      print('Error resetting grade status: $e');
    }
  }

  Future<void> _logToHistory(String grade, String action, int studentsCount, String adminName) async {
    try {
      await _firestore.collection('leave_time_history').add({
        'grade': grade,
        'action': action,
        'studentsNotified': studentsCount,
        'adminName': adminName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging to history: $e');
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${_formatTime(dateTime)}';
  }
}

class _CustomNotificationDialog extends StatefulWidget {
  final Function(String) onSend;

  const _CustomNotificationDialog({required this.onSend});

  @override
  State<_CustomNotificationDialog> createState() => _CustomNotificationDialogState();
}

class _CustomNotificationDialogState extends State<_CustomNotificationDialog> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send Custom Notification'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will send a notification to all guardians.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                hintText: 'e.g., School will close early today due to weather...',
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _messageController.text.isNotEmpty
              ? () {
                  widget.onSend(_messageController.text);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Send to All'),
        ),
      ],
    );
  }
}
