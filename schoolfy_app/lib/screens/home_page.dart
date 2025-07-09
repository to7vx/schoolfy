import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final List<Map<String, dynamic>> students;

  const HomePage({super.key, required this.students});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? firstName;
  Set<String> _pendingPickupRequests = {}; // Track students with pending pickup requests
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
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
                      return _buildEnhancedStudentCard(context, student);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEnhancedStudentCard(BuildContext context, Map<String, dynamic> student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student header with avatar and basic info
            Row(
              children: [
                // Enhanced avatar with grade indicator
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _getGradeColor(student['grade']),
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
                  label: 'Today',
                  value: '8:00 AM',
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
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
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

  Color _getGradeColor(String? grade) {
    if (grade == null) return Colors.grey;
    final gradeNum = int.tryParse(grade.substring(0, 1)) ?? 0;
    switch (gradeNum) {
      case 1:
        return Colors.purple;
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
                  radius: 25,
                  backgroundColor: _getGradeColor(student['grade']),
                  child: Text(
                    _getInitials(student['studentName'] ?? ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
                      _buildDetailItem('Today', 'Present (8:00 AM)'),
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
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Pickup request already sent for ${student['studentName']}'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Add to pending requests
    _pendingPickupRequests.add(studentId);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user data for guardian name
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final userData = userDoc.data();
      final guardianName = userData?['fullName'] ?? 'Guardian';

      // Send pickup request to Firebase Realtime Database
      final database = FirebaseDatabase.instance.ref();
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final pickupId = 'pickup_${DateTime.now().millisecondsSinceEpoch}';
      
      await database
          .child('pickupQueue')
          .child(todayKey)
          .child(pickupId)
          .set({
        'studentId': student['studentId'],
        'studentName': student['studentName'],
        'grade': student['grade'],
        'time': DateTime.now().toIso8601String(),
        'guardianName': guardianName,
        'guardianPhone': user.phoneNumber,
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pickup request sent for ${student['studentName']}!\nPlease wait at the pickup area.',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Remove from pending requests after 30 seconds to allow new requests
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) {
            _pendingPickupRequests.remove(studentId);
          }
        });
      }
    } catch (e) {
      // Remove from pending requests on error
      _pendingPickupRequests.remove(studentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to send pickup request: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
