import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({super.key});

  @override
  State<AttendanceManagementScreen> createState() => _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends State<AttendanceManagementScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedGrade = '';
  DateTime _selectedDate = DateTime.now();
  List<String> _availableGrades = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGrades();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGrades() async {
    try {
      final gradesSnapshot = await _firestore.collection('grades').get();
      setState(() {
        _availableGrades = gradesSnapshot.docs
            .map((doc) {
              final data = doc.data();
              final name = data['name'] as String?;
              final id = doc.id;
              
              // Use name if available, otherwise use ID only if it looks like a proper grade
              if (name != null && name.isNotEmpty) {
                return name;
              } else if (_isValidGradeName(id)) {
                return id;
              } else {
                return null; // Filter out invalid entries
              }
            })
            .where((grade) => grade != null)
            .cast<String>()
            .toSet() // Remove duplicates
            .toList()
          ..sort(_compareGrades);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading grades: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isValidGradeName(String grade) {
    // Filter out system-generated IDs and keep only valid grade names
    if (grade.length > 20) return false; // Too long to be a grade
    if (grade.contains('-') && grade.length > 10) return false; // Looks like UUID
    if (RegExp(r'^[a-f0-9]{20,}$').hasMatch(grade)) return false; // Hex ID
    
    // Accept common grade patterns
    if (RegExp(r'^(Grade\s?)?[0-9]{1,2}[A-Z]?$', caseSensitive: false).hasMatch(grade)) return true;
    if (RegExp(r'^[0-9]{1,2}(st|nd|rd|th)?\s?(Grade)?$', caseSensitive: false).hasMatch(grade)) return true;
    if (RegExp(r'^(KG|Kindergarten|Pre-?K)$', caseSensitive: false).hasMatch(grade)) return true;
    
    return false;
  }

  int _compareGrades(String a, String b) {
    // Custom sorting for grades to handle numeric ordering properly
    final aNum = RegExp(r'(\d+)').firstMatch(a.toLowerCase());
    final bNum = RegExp(r'(\d+)').firstMatch(b.toLowerCase());
    
    if (aNum != null && bNum != null) {
      final aInt = int.tryParse(aNum.group(1)!) ?? 0;
      final bInt = int.tryParse(bNum.group(1)!) ?? 0;
      if (aInt != bInt) return aInt.compareTo(bInt);
    }
    
    return a.compareTo(b);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Actions
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Management',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Track and manage student attendance',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showBulkAttendanceDialog,
                    icon: const Icon(Icons.checklist),
                    label: const Text('Mark Bulk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _exportAttendanceReport,
                    icon: const Icon(Icons.download),
                    label: const Text('Export'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters Section
          Card(
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search students...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[800] 
                            : Colors.grey[50],
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Grade Filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGrade.isEmpty ? null : _selectedGrade,
                      decoration: InputDecoration(
                        labelText: 'Grade',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[800] 
                            : Colors.grey[50],
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('All Grades'),
                        ),
                        ..._availableGrades.map((grade) => DropdownMenuItem(
                          value: grade,
                          child: Text(grade),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGrade = value ?? '';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Date Picker
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(text: 'Today\'s Attendance'),
                Tab(text: 'Attendance History'),
                Tab(text: 'Reports'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayAttendanceTab(),
                _buildHistoryTab(),
                _buildReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayAttendanceTab() {
    final today = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('students').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final students = snapshot.data?.docs ?? [];
        final filteredStudents = students.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final grade = data['grade'] ?? '';
          
          return (name.contains(_searchQuery) || _searchQuery.isEmpty) &&
                 (grade == _selectedGrade || _selectedGrade.isEmpty);
        }).toList();

        if (filteredStudents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 64,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'No students found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your filters',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return Card(
          color: Theme.of(context).cardColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredStudents.length,
            itemBuilder: (context, index) {
              final student = filteredStudents[index];
              final studentData = student.data() as Map<String, dynamic>;
              
              return _buildStudentAttendanceCard(student.id, studentData, today);
            },
          ),
        );
      },
    );
  }

  Widget _buildStudentAttendanceCard(String studentId, Map<String, dynamic> studentData, String date) {
    final studentName = studentData['name'] ?? 'Unknown';
    final grade = studentData['grade'] ?? '';
    final studentIdNumber = studentData['studentId'] ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('attendance')
          .doc('${studentId}_$date')
          .snapshots(),
      builder: (context, attendanceSnapshot) {
        final attendanceData = attendanceSnapshot.data?.data() as Map<String, dynamic>?;
        final status = attendanceData?['status'] ?? 'unmarked';
        final markedTime = attendanceData?['markedAt'] as Timestamp?;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[700]! 
                  : Colors.grey[300]!
            ),
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).cardColor,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(status).withOpacity(0.1),
              child: Text(
                studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              studentName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Grade: $grade • ID: $studentIdNumber'),
                if (markedTime != null)
                  Text(
                    'Marked at ${DateFormat('HH:mm').format(markedTime.toDate())}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusChip(status),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) => _markAttendance(studentId, value, date),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'present',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('Present'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'absent',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Absent'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'late',
                      child: Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text('Late'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'excused',
                      child: Row(
                        children: [
                          Icon(Icons.event_note, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text('Excused'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30))))
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final attendanceRecords = snapshot.data?.docs ?? [];
        
        if (attendanceRecords.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'No attendance history',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return Card(
          color: Theme.of(context).cardColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: attendanceRecords.length,
            itemBuilder: (context, index) {
              final record = attendanceRecords[index];
              final data = record.data() as Map<String, dynamic>;
              
              return _buildHistoryCard(data);
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data) {
    final date = data['date'] ?? '';
    final status = data['status'] ?? '';
    final studentName = data['studentName'] ?? '';
    final grade = data['grade'] ?? '';
    final markedAt = data['markedAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[700]! 
              : Colors.grey[300]!
        ),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).cardColor,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withOpacity(0.1),
          child: Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
          ),
        ),
        title: Text(studentName),
        subtitle: Text('Grade $grade • $date'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildStatusChip(status),
            if (markedAt != null)
              Text(
                DateFormat('HH:mm').format(markedAt.toDate()),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.schedule;
      case 'excused':
        return Icons.event_note;
      default:
        return Icons.help;
    }
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      child: Card(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Reports',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Report Options
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2,
                children: [
                  _buildReportCard(
                    'Daily Report',
                    'View attendance for a specific day',
                    Icons.today,
                    () => _generateDailyReport(),
                  ),
                  _buildReportCard(
                    'Weekly Report',
                    'Weekly attendance summary',
                    Icons.view_week,
                    () => _generateWeeklyReport(),
                  ),
                  _buildReportCard(
                    'Monthly Report',
                    'Monthly attendance statistics',
                    Icons.calendar_month,
                    () => _generateMonthlyReport(),
                  ),
                  _buildReportCard(
                    'Grade Report',
                    'Attendance by grade level',
                    Icons.grade,
                    () => _generateGradeReport(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppTheme.primaryColor),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios, 
                    size: 16, 
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4)
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _markAttendance(String studentId, String status, String date) async {
    try {
      // Get student data for the record
      final studentDoc = await _firestore.collection('students').doc(studentId).get();
      final studentData = studentDoc.data();
      
      await _firestore.collection('attendance').doc('${studentId}_$date').set({
        'studentId': studentId,
        'studentName': studentData?['name'] ?? '',
        'grade': studentData?['grade'] ?? '',
        'status': status,
        'date': date,
        'markedAt': FieldValue.serverTimestamp(),
        'markedBy': 'admin', // You can get actual admin info here
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance marked as $status'),
            backgroundColor: _getStatusColor(status),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBulkAttendanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Attendance'),
        content: const Text('Mark all students as present for today?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markBulkAttendance();
            },
            child: const Text('Mark All Present'),
          ),
        ],
      ),
    );
  }

  Future<void> _markBulkAttendance() async {
    try {
      final studentsSnapshot = await _firestore.collection('students').get();
      final today = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final batch = _firestore.batch();

      for (final doc in studentsSnapshot.docs) {
        final studentData = doc.data();
        final attendanceRef = _firestore.collection('attendance').doc('${doc.id}_$today');
        
        batch.set(attendanceRef, {
          'studentId': doc.id,
          'studentName': studentData['name'] ?? '',
          'grade': studentData['grade'] ?? '',
          'status': 'present',
          'date': today,
          'markedAt': FieldValue.serverTimestamp(),
          'markedBy': 'admin',
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bulk attendance marked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking bulk attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportAttendanceReport() {
    // Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _generateDailyReport() {
    // Implement daily report generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating daily report...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _generateWeeklyReport() {
    // Implement weekly report generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating weekly report...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _generateMonthlyReport() {
    // Implement monthly report generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating monthly report...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _generateGradeReport() {
    // Implement grade report generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating grade report...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
