import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  final List<Map<String, dynamic>> students;

  const HomePage({super.key, required this.students});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? firstName;
  Set<String> _pendingPickupRequests = {}; // Track students with pending pickup requests
  Map<String, String> _gradeLeaveTime = {}; // Store leave times for each grade
  List<StreamSubscription>? _gradeStreamSubscriptions; // Stream subscriptions for real-time updates
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadGradeLeaveTime();
    _setupGradeLeaveTimeStreams();
  }

  @override
  void dispose() {
    _gradeStreamSubscriptions?.forEach((subscription) => subscription.cancel());
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (mounted) {
            setState(() {
              firstName = userData?['firstName'] ?? 'Guardian';
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            firstName = 'Guardian';
          });
        }
      }
    }
  }

  Future<void> _loadGradeLeaveTime() async {
    try {
      // Get unique grades from students
      Set<String> studentGrades = {};
      for (var student in widget.students) {
        final grade = student['grade'];
        if (grade != null && grade.isNotEmpty) {
          studentGrades.add(grade);
        }
      }
      
      // Fetch leave times for each grade
      for (String grade in studentGrades) {
        final gradeDoc = await FirebaseFirestore.instance
            .collection('grade_leave_times')
            .doc(grade)
            .get();
            
        if (gradeDoc.exists && mounted) {
          final data = gradeDoc.data();
          final scheduledTime = data?['scheduledTime'] as Timestamp?;
          final leaveTime = data?['leaveTime']; // Can be String or Timestamp
          
          String timeString = '8:00 AM'; // Default fallback
          
          // Priority: 1. leaveTime (current day), 2. scheduledTime (future), 3. default
          if (leaveTime != null) {
            // If leave time is set, show it
            if (leaveTime is String) {
              // New format: leaveTime is a string like "20:37"
              timeString = _formatTimeFromString(leaveTime);
            } else if (leaveTime is Timestamp) {
              // Old format: leaveTime is a Timestamp
              final leaveDateTime = leaveTime.toDate();
              timeString = _formatTime(leaveDateTime);
            }
          } else if (scheduledTime != null) {
            // If scheduled time is set, show it
            final scheduledDateTime = scheduledTime.toDate();
            timeString = _formatTime(scheduledDateTime);
          }
          
          setState(() {
            _gradeLeaveTime[grade] = timeString;
          });
        }
      }
    } catch (e) {
      print('Error loading grade leave times: $e');
    }
  }

  void _setupGradeLeaveTimeStreams() {
    // Get unique grades from students
    Set<String> studentGrades = {};
    for (var student in widget.students) {
      final grade = student['grade'];
      if (grade != null && grade.isNotEmpty) {
        studentGrades.add(grade);
      }
    }

    _gradeStreamSubscriptions = [];

    // Set up real-time listeners for each grade
    for (String grade in studentGrades) {
      final subscription = FirebaseFirestore.instance
          .collection('grade_leave_times')
          .doc(grade)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          final data = snapshot.data();
          final scheduledTime = data?['scheduledTime'] as Timestamp?;
          final leaveTime = data?['leaveTime']; // Can be String or Timestamp
          
          String timeString = '8:00 AM'; // Default fallback
          
          // Priority: 1. leaveTime (current day), 2. scheduledTime (future), 3. default
          if (leaveTime != null) {
            // If leave time is set, show it regardless of status
            if (leaveTime is String) {
              // New format: leaveTime is a string like "20:37"
              timeString = _formatTimeFromString(leaveTime);
            } else if (leaveTime is Timestamp) {
              // Old format: leaveTime is a Timestamp
              final leaveDateTime = leaveTime.toDate();
              timeString = _formatTime(leaveDateTime);
            }
          } else if (scheduledTime != null) {
            // If scheduled time is set, show it
            final scheduledDateTime = scheduledTime.toDate();
            timeString = _formatTime(scheduledDateTime);
          }
          
          // Only update state if the time actually changed
          if (_gradeLeaveTime[grade] != timeString) {
            setState(() {
              _gradeLeaveTime[grade] = timeString;
            });
          }
        }
      });
      
      _gradeStreamSubscriptions!.add(subscription);
    }
  }
  
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr $period';
  }

  String _formatTimeFromString(String timeString) {
    try {
      // Parse time string like "20:37" or "08:30"
      final parts = timeString.split(':');
      if (parts.length != 2) return timeString; // Return original if invalid format
      
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final minuteStr = minute.toString().padLeft(2, '0');
      return '$hour12:$minuteStr $period';
    } catch (e) {
      return timeString; // Return original if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingXXL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    firstName != null ? 'Welcome back,' : 'Welcome back!',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    firstName ?? 'Guardian',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${widget.students.length} student${widget.students.length != 1 ? 's' : ''} linked',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.notifications_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: () => _showNotificationsSheet(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Empty State or Students List
          widget.students.isEmpty
              ? SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildModernStudentCard(widget.students[index], index),
                      childCount: widget.students.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXXL),
            Text(
              'No students linked yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Contact your school to link your children to your account',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXXL),
            ElevatedButton.icon(
              onPressed: () {
                // Could navigate to a help screen or contact info
              },
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text('Contact Support'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXXL,
                  vertical: AppTheme.spacingL,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStudentCard(Map<String, dynamic> student, int index) {
    final grade = student['grade'] ?? '';
    final studentName = student['studentName'] ?? '';
    final studentId = student['studentId'] ?? '';
    final leaveTime = _gradeLeaveTime[grade] ?? '8:00 AM';
    final isPendingPickup = _pendingPickupRequests.contains(studentId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          onTap: () => _showStudentDetails(context, student),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              children: [
                // Student Header
                Row(
                  children: [
                    // Modern Avatar
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getModernAvatarColor(index),
                            _getModernAvatarColor(index).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(studentName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingL),
                    
                    // Student Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Grade $grade',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: AppTheme.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Al-Noor Elementary',
                                  style: TextStyle(
                                    color: AppTheme.textTertiary,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.successColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingL),
                
                // Info Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildModernInfoCard(
                        icon: Icons.access_time_rounded,
                        label: 'Leave Time',
                        value: leaveTime,
                        color: AppTheme.infoColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('attendance')
                            .doc('${studentId}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}')
                            .snapshots(),
                        builder: (context, snapshot) {
                          String status = 'Not Marked';
                          Color statusColor = Colors.grey;
                          IconData statusIcon = Icons.help_rounded;
                          
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            final attendanceStatus = data?['status'] ?? 'unmarked';
                            
                            switch (attendanceStatus) {
                              case 'present':
                                status = 'Present';
                                statusColor = AppTheme.successColor;
                                statusIcon = Icons.check_circle_rounded;
                                break;
                              case 'absent':
                                status = 'Absent';
                                statusColor = Colors.red;
                                statusIcon = Icons.cancel_rounded;
                                break;
                              case 'late':
                                status = 'Late';
                                statusColor = AppTheme.warningColor;
                                statusIcon = Icons.schedule_rounded;
                                break;
                              case 'excused':
                                status = 'Excused';
                                statusColor = AppTheme.infoColor;
                                statusIcon = Icons.event_note_rounded;
                                break;
                            }
                          }
                          
                          return _buildModernInfoCard(
                            icon: statusIcon,
                            label: 'Attendance',
                            value: status,
                            color: statusColor,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: _buildTransportCard(student),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingL),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: isPendingPickup ? null : () => _sendPickupRequest(student),
                        icon: Icon(
                          isPendingPickup ? Icons.schedule_rounded : Icons.directions_bus_rounded,
                          size: 20,
                        ),
                        label: Text(
                          isPendingPickup ? 'Request Sent' : 'Request Pickup',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPendingPickup ? AppTheme.textTertiary : AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showStudentDetails(context, student),
                        icon: const Icon(Icons.info_outline_rounded, size: 20),
                        label: const Text(
                          'Details',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransportCard(Map<String, dynamic> student) {
    final studentId = student['studentId'];
    
    if (studentId == null) {
      return _buildModernInfoCard(
        icon: Icons.directions_bus,
        label: 'No Transport',
        value: 'None',
        color: Colors.grey,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .snapshots(),
      builder: (context, studentSnapshot) {
        if (studentSnapshot.connectionState == ConnectionState.waiting) {
          return _buildModernInfoCard(
            icon: Icons.directions_bus,
            label: 'Loading...',
            value: 'None',
            color: Colors.grey,
          );
        }

        if (studentSnapshot.hasError) {
          return _buildModernInfoCard(
            icon: Icons.directions_bus,
            label: 'Error',
            value: 'None',
            color: Colors.red,
          );
        }

        if (!studentSnapshot.hasData || !studentSnapshot.data!.exists) {
          return _buildModernInfoCard(
            icon: Icons.directions_bus,
            label: 'No Transport',
            value: 'None',
            color: Colors.grey,
          );
        }

        final studentData = studentSnapshot.data!.data() as Map<String, dynamic>;
        final busId = studentData['busId'];

        if (busId == null) {
          return _buildModernInfoCard(
            icon: Icons.directions_bus,
            label: 'No Transport',
            value: 'None',
            color: Colors.grey,
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('buses')
              .doc(busId)
              .snapshots(),
          builder: (context, busSnapshot) {
            Color cardColor;
            String statusText;
            IconData iconData;
            String busDisplayText = 'None';

            if (busSnapshot.connectionState == ConnectionState.waiting) {
              cardColor = Colors.grey;
              statusText = 'Loading...';
              iconData = Icons.directions_bus;
            } else if (busSnapshot.hasError) {
              cardColor = Colors.red;
              statusText = 'Error';
              iconData = Icons.directions_bus;
            } else if (!busSnapshot.hasData || !busSnapshot.data!.exists) {
              cardColor = Colors.grey;
              statusText = 'No Transport';
              iconData = Icons.directions_bus;
            } else {
              final busData = busSnapshot.data!.data() as Map<String, dynamic>?;
              if (busData == null) {
                cardColor = Colors.grey;
                statusText = 'No Transport';
                iconData = Icons.directions_bus;
              } else {
                final routeStatus = busData['routeStatus'] ?? 'idle';
                final busNumber = busData['busNumber'] ?? 'Unknown';
                busDisplayText = 'Bus $busNumber';
                
                if (routeStatus == 'on_route') {
                  cardColor = Colors.green;
                  statusText = 'On Route';
                  iconData = Icons.directions_bus;
                } else {
                  cardColor = AppTheme.primaryColor;
                  statusText = 'Transport';
                  iconData = Icons.directions_bus;
                }
              }
            }

            return _buildModernInfoCard(
              icon: iconData,
              label: statusText,
              value: busDisplayText,
              color: cardColor,
            );
          },
        );
      },
    );
  }

  Color _getModernAvatarColor(int index) {
    const colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.infoColor,
    ];
    return colors[index % colors.length];
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}';
    }
    return name[0];
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildStudentDetailsSheet(context, student),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNotificationsSheet(context),
    );
  }

  Widget _buildStudentDetailsSheet(BuildContext context, Map<String, dynamic> student) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    _getInitials(student['studentName'] ?? ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['studentName'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Grade ${student['grade'] ?? ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailSection(
                    'Student Information',
                    [
                      _buildDetailItem('Full Name', student['studentName'] ?? ''),
                      _buildDetailItem('Grade', student['grade'] ?? ''),
                      _buildDetailItem('School ID', student['schoolId'] ?? ''),
                      _buildDetailItem('Status', 'Active'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailSection(
                    'School Information',
                    [
                      _buildDetailItem('School', 'Al-Noor Elementary School'),
                      _buildDetailItem('Address', 'Riyadh, Saudi Arabia'),
                      _buildDetailItem('Phone', '+966114567890'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailSection(
                    'Attendance',
                    [
                      _buildDetailItem('Today', 'Present (${_gradeLeaveTime[student['grade']] ?? '8:00 AM'})'),
                      _buildDetailItem('This Week', '5/5 days'),
                      _buildDetailItem('This Month', '20/22 days'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSheet(BuildContext context) {
    // TODO: Fetch real notifications from Firebase
    final notifications = <Map<String, dynamic>>[];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${notifications.where((n) => !(n['isRead'] as bool)).length} unread',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.mark_email_read_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () {
                        // Mark all as read logic
                      },
                      tooltip: 'Mark all as read',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Notifications List
          Expanded(
            child: notifications.isEmpty
                ? _buildEmptyNotifications()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) => _buildNotificationCard(notifications[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNotifications() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 50,
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'We\'ll notify you about important updates',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] as bool;
    final type = notification['type'] as String;
    
    IconData getNotificationIcon() {
      switch (type) {
        case 'pickup':
          return Icons.directions_bus_rounded;
        case 'schedule':
          return Icons.schedule_rounded;
        case 'announcement':
          return Icons.campaign_rounded;
        case 'attendance':
          return Icons.check_circle_rounded;
        default:
          return Icons.notifications_rounded;
      }
    }
    
    Color getNotificationColor() {
      switch (type) {
        case 'pickup':
          return AppTheme.warningColor;
        case 'schedule':
          return AppTheme.infoColor;
        case 'announcement':
          return AppTheme.primaryColor;
        case 'attendance':
          return AppTheme.successColor;
        default:
          return AppTheme.primaryColor;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : AppTheme.primaryColor.withOpacity(0.2),
        ),
        boxShadow: isRead ? [] : AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          onTap: () {
            // Handle notification tap
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: getNotificationColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    getNotificationIcon(),
                    color: getNotificationColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'],
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification['time'],
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPickupRequest(Map<String, dynamic> student) async {
    final studentId = student['studentId'];
    
    // Check if there's already a pending pickup request for this student
    if (_pendingPickupRequests.contains(studentId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pickup request already sent for this student'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      // Add to pending requests immediately for UI feedback
      setState(() {
        _pendingPickupRequests.add(studentId);
      });

      // Generate pickup request
      final pickupRequest = {
        'studentId': studentId,
        'studentName': student['studentName'],
        'grade': student['grade'],
        'guardianId': FirebaseAuth.instance.currentUser?.uid,
        'guardianName': firstName ?? 'Guardian',
        'requestTime': ServerValue.timestamp,
        'status': 'pending',
        'priority': 'normal',
        'estimatedPickupTime': DateTime.now().add(const Duration(minutes: 15)).millisecondsSinceEpoch,
      };

      // Get today's date for the queue path
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Send to pickup queue with date-based path
      await FirebaseDatabase.instance
          .ref('pickupQueue/$dateString')
          .push()
          .set(pickupRequest);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pickup request sent for ${student['studentName']}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                // Remove from pending requests if user wants to undo
                setState(() {
                  _pendingPickupRequests.remove(studentId);
                });
              },
            ),
          ),
        );
      }

      // Auto-remove from pending requests after 30 seconds
      Timer(const Duration(seconds: 30), () {
        if (mounted) {
          setState(() {
            _pendingPickupRequests.remove(studentId);
          });
        }
      });

    } catch (e) {
      // Remove from pending requests on error
      setState(() {
        _pendingPickupRequests.remove(studentId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send pickup request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
