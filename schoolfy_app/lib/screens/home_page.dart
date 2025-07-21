import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
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
    print('DEBUG: HomePage initState called');
    print('DEBUG: Students data: ${widget.students}');
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
      
      print('DEBUG: Student grades found: $studentGrades');
      
      // Fetch leave times for each grade
      for (String grade in studentGrades) {
        print('DEBUG: Fetching leave time for grade: $grade');
        final gradeDoc = await FirebaseFirestore.instance
            .collection('grade_leave_times')
            .doc(grade)
            .get();
            
        print('DEBUG: Grade document exists for $grade: ${gradeDoc.exists}');
        if (gradeDoc.exists) {
          print('DEBUG: Grade document data for $grade: ${gradeDoc.data()}');
        }
            
        if (gradeDoc.exists && mounted) {
          final data = gradeDoc.data();
          final scheduledTime = data?['scheduledTime'] as Timestamp?;
          final leaveTime = data?['leaveTime']; // Can be String or Timestamp
          final status = data?['status'];
          
          print('DEBUG: Grade $grade - Status: $status, LeaveTime: $leaveTime, ScheduledTime: $scheduledTime');
          
          String timeString = '8:00 AM'; // Default fallback
          
          // Priority: 1. leaveTime (current day), 2. scheduledTime (future), 3. default
          if (leaveTime != null) {
            // If leave time is set, show it
            if (leaveTime is String) {
              // New format: leaveTime is a string like "20:37"
              timeString = _formatTimeFromString(leaveTime);
              print('DEBUG: Using leaveTime string for $grade: $timeString');
            } else if (leaveTime is Timestamp) {
              // Old format: leaveTime is a Timestamp
              final leaveDateTime = leaveTime.toDate();
              timeString = _formatTime(leaveDateTime);
              print('DEBUG: Using leaveTime timestamp for $grade: $timeString');
            }
          } else if (scheduledTime != null) {
            // If scheduled time is set, show it
            final scheduledDateTime = scheduledTime.toDate();
            timeString = _formatTime(scheduledDateTime);
            print('DEBUG: Using scheduledTime for $grade: $timeString');
          }
          
          setState(() {
            _gradeLeaveTime[grade] = timeString;
          });
          
          print('DEBUG: Set leave time for $grade to: $timeString');
        }
      }
      
      print('DEBUG: Final gradeLeaveTime map: $_gradeLeaveTime');
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
      print('DEBUG: Setting up stream listener for grade: $grade');
      final subscription = FirebaseFirestore.instance
          .collection('grade_leave_times')
          .doc(grade)
          .snapshots()
          .listen((snapshot) {
        print('DEBUG: Stream update for grade $grade - exists: ${snapshot.exists}');
        if (snapshot.exists) {
          print('DEBUG: Stream data for $grade: ${snapshot.data()}');
        }
        
        if (snapshot.exists && mounted) {
          final data = snapshot.data();
          final scheduledTime = data?['scheduledTime'] as Timestamp?;
          final leaveTime = data?['leaveTime']; // Can be String or Timestamp
          final status = data?['status'] ?? 'not_sent';
          
          print('DEBUG: Stream - Grade $grade, Status: $status, LeaveTime: $leaveTime, ScheduledTime: $scheduledTime');
          
          String timeString = '8:00 AM'; // Default fallback
          
          // Priority: 1. leaveTime (current day), 2. scheduledTime (future), 3. default
          if (leaveTime != null) {
            // If leave time is set, show it regardless of status
            if (leaveTime is String) {
              // New format: leaveTime is a string like "20:37"
              timeString = _formatTimeFromString(leaveTime);
              print('DEBUG: Stream - Using leaveTime string for $grade: $timeString');
            } else if (leaveTime is Timestamp) {
              // Old format: leaveTime is a Timestamp
              final leaveDateTime = leaveTime.toDate();
              timeString = _formatTime(leaveDateTime);
              print('DEBUG: Stream - Using leaveTime timestamp for $grade: $timeString');
            }
          } else if (scheduledTime != null) {
            // If scheduled time is set, show it
            final scheduledDateTime = scheduledTime.toDate();
            timeString = _formatTime(scheduledDateTime);
            print('DEBUG: Stream - Using scheduledTime for $grade: $timeString');
          }
          
          // Only update state if the time actually changed
          if (_gradeLeaveTime[grade] != timeString) {
            setState(() {
              _gradeLeaveTime[grade] = timeString;
            });
            print('DEBUG: Stream - Updated leave time for $grade to: $timeString');
          } else {
            print('DEBUG: Stream - Leave time for $grade unchanged: $timeString');
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
      print('DEBUG: Error formatting time string $timeString: $e');
      return timeString; // Return original if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Students',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: 'Logout',
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: widget.students.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No students linked yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact your school to link your children',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header with student count and school info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstName != null ? 'Welcome back, $firstName!' : 'Welcome back!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.students.length} student${widget.students.length != 1 ? 's' : ''} linked',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Students list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.students.length,
                    itemBuilder: (context, index) {
                      final student = widget.students[index];
                      return _buildStudentCard(student, index);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student info row
          Row(
            children: [
              // Student avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _getAvatarColor(index),
                    child: Text(
                      _getInitials(student['studentName'] ?? ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        student['grade'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Student name and info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['studentName'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.school,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Grade ${student['grade'] ?? ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Al-Noor Elementary School',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Linked',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick info cards
          Row(
            children: [
              _buildInfoCard(
                icon: Icons.access_time,
                label: 'Leave Time',
                value: _gradeLeaveTime[student['grade']] ?? '8:00 AM',
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildInfoCard(
                icon: Icons.person,
                label: 'Status',
                value: 'Present',
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _buildInfoCard(
                icon: Icons.directions_car,
                label: 'Pickup',
                value: 'Ready',
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(_pendingPickupRequests.contains(student['studentId']) 
                      ? Icons.schedule 
                      : Icons.notifications_active),
                  label: Text(_pendingPickupRequests.contains(student['studentId'])
                      ? 'Request Sent'
                      : 'Request Pickup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pendingPickupRequests.contains(student['studentId'])
                        ? Colors.grey
                        : Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _sendPickupRequest(student),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.info_outline),
                label: const Text('Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  side: const BorderSide(color: Colors.deepPurple),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showStudentDetails(context, student),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(int index) {
    switch (index % 5) {
      case 0:
        return Colors.deepPurple;
      case 1:
        return Colors.teal;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 4:
        return Colors.orange;
      default:
        return Colors.deepPurple;
    }
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
