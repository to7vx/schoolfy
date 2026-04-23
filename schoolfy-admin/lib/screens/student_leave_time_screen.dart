import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/admin_notification_service.dart';

class StudentLeaveTimeScreen extends StatefulWidget {
  const StudentLeaveTimeScreen({super.key});

  @override
  State<StudentLeaveTimeScreen> createState() => _StudentLeaveTimeScreenState();
}

class _StudentLeaveTimeScreenState extends State<StudentLeaveTimeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, TextEditingController> _timeControllers = {};
  final AdminNotificationService _notificationService = AdminNotificationService();

  List<String> _grades = []; // Dynamic grades from Firestore
  bool _isLoadingGrades = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _loadGradesFromFirestore();
  }

  Future<void> _loadGradesFromFirestore() async {
    try {
      final gradesSnapshot = await _firestore
          .collection('grades')
          .orderBy('name')
          .get();
      
      final loadedGrades = gradesSnapshot.docs
          .map((doc) => (doc.data())['name'] as String)
          .toList();
      
      setState(() {
        _grades = loadedGrades;
        _isLoadingGrades = false;
      });
      
      // Initialize controllers after loading grades
      _initializeControllers();
    } catch (e) {
      print('Error loading grades from Firestore: $e');
      // Fallback to hardcoded grades if Firestore fails
      setState(() {
        _grades = [
          '1A', '1B', '2A', '2B', '3A', '3B', '4A', '4B', '5A', '5B', '6A', '6B',
          'KG-A', 'KG-B', 'Pre-K-A', 'Pre-K-B'
        ];
        _isLoadingGrades = false;
      });
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    for (String grade in _grades) {
      _timeControllers[grade] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _timeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
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
                  const Expanded(
                    child: Text(
                      'Student Leave Time Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
        ),
      ),
    );
  }

  Widget _buildGlobalControls() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Bulk Actions',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _setLeaveTimeForAllGrades,
                      icon: const Icon(Icons.schedule_send, size: 16),
                      label: const Text('Set Leave Time for All Grades'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showBulkTimePicker,
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text('Custom Time for All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.infoColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _resetAllGrades,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset All Grades'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('students').snapshots(),
      builder: (context, snapshot) {
        // Handle errors
        if (snapshot.hasError) {
          print('Error in stats stream: ${snapshot.error}');
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: AppTheme.errorColor),
                const SizedBox(width: 8),
                Text(
                  'Error loading statistics. Please refresh the page.',
                  style: TextStyle(color: const Color(0xFFB91C1C)),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 80, maxHeight: 120),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
            child: _isLoadingGrades
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading grades...'),
                      ],
                    ),
                  )
                : _grades.isEmpty
                    ? _buildEmptyGradesState()
                    : StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('grades').orderBy('name').snapshots(),
                        builder: (context, snapshot) {
                          // Use cached grades until new data arrives
                          final currentGrades = snapshot.hasData && snapshot.data!.docs.isNotEmpty
                              ? snapshot.data!.docs
                                  .map((doc) => (doc.data() as Map<String, dynamic>)['name'] as String)
                                  .toList()
                              : _grades;

                          return ListView.builder(
                            itemCount: currentGrades.length,
                            itemBuilder: (context, index) {
                              return _buildGradeItem(currentGrades[index]);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGradesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 64,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No Grades Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please add grades in Student Management first',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadGradesFromFirestore(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Grades'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
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
        final autoEnabled = gradeData['autosetEnabled'] ?? false;

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
                    'AUTOSET',
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
        color = AppTheme.textMuted;
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
        color = AppTheme.textMuted;
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
        // Handle errors
        if (snapshot.hasError) {
          print('Error in grade subtitle stream for $grade: ${snapshot.error}');
          return Text(
            'Error loading grade data',
            style: TextStyle(color: AppTheme.errorColor, fontSize: 12),
          );
        }

        // Handle loading and no data
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return const Text('Loading...', style: TextStyle(fontSize: 12));
        }

        final totalStudents = snapshot.data!.docs.length;
        final leftStudents = snapshot.data!.docs
            .where((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                return data['leaveStatus'] == 'left';
              } catch (e) {
                print('Error reading student data: $e');
                return false;
              }
            })
            .length;
        final inSchool = totalStudents - leftStudents;

        String timeText = '';
        if (gradeData['lastSent'] != null) {
          try {
            final lastSent = (gradeData['lastSent'] as Timestamp).toDate();
            timeText = ' • Last sent: ${_formatTime(lastSent)}';
          } catch (e) {
            print('Error formatting lastSent time: $e');
          }
        } else if (gradeData['scheduledTime'] != null) {
          try {
            final scheduled = (gradeData['scheduledTime'] as Timestamp).toDate();
            timeText = ' • Scheduled: ${_formatTime(scheduled)}';
          } catch (e) {
            print('Error formatting scheduled time: $e');
          }
        }

        return Text(
          '$inSchool/$totalStudents in school$timeText',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        );
      },
    );
  }

  Widget _buildGradeControls(String grade, Map<String, dynamic> gradeData) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Autoset toggle
          Row(
            children: [
              Switch(
                value: gradeData['autosetEnabled'] ?? false,
                onChanged: (value) => _toggleAutoset(grade, value),
                activeColor: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text('Autoset - Leave time shows daily on app'),
              const Spacer(),
              if (gradeData['autosetEnabled'] == true) ...[
                const Text('Time: '),
                InkWell(
                  onTap: () => _showTimePicker(context, grade, true),
                  child: Container(
                    width: 120,
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.textMuted),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.access_time, size: 16, color: AppTheme.textMuted),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _timeControllers[grade]?.text.isNotEmpty == true 
                                ? _timeControllers[grade]!.text 
                                : 'HH:MM',
                            style: TextStyle(
                              color: _timeControllers[grade]?.text.isNotEmpty == true 
                                  ? Colors.black87 
                                  : AppTheme.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                  backgroundColor: AppTheme.infoColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              if (gradeData['status'] == 'sent')
                TextButton.icon(
                  onPressed: () => _resetGradeStatus(grade),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.warningColor,
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
                // Handle errors
                if (snapshot.hasError) {
                  print('Error in history stream: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: AppTheme.errorColor, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading history',
                          style: TextStyle(color: const Color(0xFFB91C1C), fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please check your connection and try again.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Handle loading state
                if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, color: AppTheme.textMuted, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'No leave time history yet',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'History will appear here when you send leave time notifications',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    try {
                      final history = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      return _buildHistoryItem(history);
                    } catch (e) {
                      print('Error building history item $index: $e');
                      return ListTile(
                        leading: Icon(Icons.error, color: AppTheme.errorColor),
                        title: const Text('Error loading this item'),
                        subtitle: Text('Item $index could not be loaded'),
                      );
                    }
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
        return AppTheme.warningColor;
      default:
        return AppTheme.textMuted;
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
  Future<void> _toggleAutoset(String grade, bool value) async {
    try {
      await _firestore.collection('grade_leave_times').doc(grade).set({
        'autosetEnabled': value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating autoset: $e');
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
              'autosetTime': time, // Store as string for autoset functionality
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
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      print('Error setting custom leave time: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error setting leave time'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
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
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _sendNotification(String grade) async {
    try {
      // Use the enhanced notification service without custom note
      await _notificationService.sendGradeLeaveTimeNotification(
        grade: grade,
        customNote: '', // No custom note functionality
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notifications sent to Grade $grade guardians'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      print('Error sending notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending notifications: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
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

  // New bulk action methods
  Future<void> _setLeaveTimeForAllGrades() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final now = DateTime.now();
      final leaveTimeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      int totalStudents = 0;
      final batch = _firestore.batch();
      
      // Process each grade
      for (String grade in _grades) {
        // Update grade status
        final gradeRef = _firestore.collection('grade_leave_times').doc(grade);
        batch.set(gradeRef, {
          'gradeId': grade,
          'leaveTime': leaveTimeString,
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
        
        totalStudents += studentsSnapshot.docs.length;
        
        for (var doc in studentsSnapshot.docs) {
          batch.update(doc.reference, {
            'leaveStatus': 'left',
            'leaveTime': Timestamp.fromDate(now),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      await batch.commit();
      
      // Log to history
      await _logToHistory('All Grades', 'Bulk Set', totalStudents, authProvider.userData?['name'] ?? 'Admin');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave time set for all grades ($totalStudents students)'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      print('Error setting leave time for all grades: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting leave time: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showBulkTimePicker() async {
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
      await _setBulkCustomLeaveTime(selectedTime);
    }
  }

  Future<void> _setBulkCustomLeaveTime(TimeOfDay selectedTime) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final now = DateTime.now();
      final customDateTime = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
      final leaveTimeString = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      
      int totalStudents = 0;
      final batch = _firestore.batch();
      
      // Process each grade
      for (String grade in _grades) {
        // Update grade status with custom time
        final gradeRef = _firestore.collection('grade_leave_times').doc(grade);
        batch.set(gradeRef, {
          'gradeId': grade,
          'leaveTime': leaveTimeString,
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
        
        totalStudents += studentsSnapshot.docs.length;
        
        for (var doc in studentsSnapshot.docs) {
          batch.update(doc.reference, {
            'leaveStatus': 'left',
            'leaveTime': Timestamp.fromDate(customDateTime),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      await batch.commit();
      
      // Log to history
      await _logToHistory('All Grades', 'Bulk Custom Time', totalStudents, authProvider.userData?['name'] ?? 'Admin');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave time set to ${selectedTime.format(context)} for all grades ($totalStudents students)'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      print('Error setting bulk custom leave time: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error setting leave time'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _resetAllGrades() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      int totalStudents = 0;
      final batch = _firestore.batch();
      
      // Process each grade
      for (String grade in _grades) {
        // Reset grade status
        final gradeRef = _firestore.collection('grade_leave_times').doc(grade);
        batch.set(gradeRef, {
          'status': 'not_sent',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        // Reset all students in this grade
        final studentsSnapshot = await _firestore
            .collection('students')
            .where('grade', isEqualTo: grade)
            .get();
        
        totalStudents += studentsSnapshot.docs.length;
        
        for (var doc in studentsSnapshot.docs) {
          batch.update(doc.reference, {
            'leaveStatus': 'in_school',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      await batch.commit();
      
      // Log to history
      await _logToHistory('All Grades', 'Bulk Reset', totalStudents, authProvider.userData?['name'] ?? 'Admin');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All grades reset ($totalStudents students back to school)'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    } catch (e) {
      print('Error resetting all grades: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting grades: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
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

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${_formatTime(dateTime)}';
  }
}
