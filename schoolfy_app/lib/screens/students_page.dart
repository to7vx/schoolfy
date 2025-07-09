import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _sortBy = 'Name';
  bool _sortAscending = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.deepPurple,
                        Colors.deepPurple.shade700,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final userData = snapshot.data?.data() as Map<String, dynamic>?;
                              final linkedStudents = userData?['linkedStudents'] as List? ?? [];
                              final firstName = userData?['firstName'] ?? 'Guardian';
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hi $firstName!',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${linkedStudents.length} Students',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Manage your children\'s information',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Search and Filter Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar with Sort Button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search students...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.sort,
                            color: Colors.deepPurple,
                          ),
                        ),
                        onSelected: (value) {
                          setState(() {
                            if (_sortBy == value) {
                              _sortAscending = !_sortAscending;
                            } else {
                              _sortBy = value;
                              _sortAscending = true;
                            }
                          });
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'Name',
                            child: Row(
                              children: [
                                const Icon(Icons.person),
                                const SizedBox(width: 8),
                                const Text('Sort by Name'),
                                if (_sortBy == 'Name') ...[
                                  const Spacer(),
                                  Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'Grade',
                            child: Row(
                              children: [
                                const Icon(Icons.school),
                                const SizedBox(width: 8),
                                const Text('Sort by Grade'),
                                if (_sortBy == 'Grade') ...[
                                  const Spacer(),
                                  Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'Attendance',
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today),
                                const SizedBox(width: 8),
                                const Text('Sort by Attendance'),
                                if (_sortBy == 'Attendance') ...[
                                  const Spacer(),
                                  Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All'),
                        _buildFilterChip('Grade 1'),
                        _buildFilterChip('Grade 2'),
                        _buildFilterChip('Grade 3'),
                        _buildFilterChip('Grade 4'),
                        _buildFilterChip('Present'),
                        _buildFilterChip('Absent'),
                        _buildFilterChip('High Achiever'),
                        _buildFilterChip('Needs Attention'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.deepPurple,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.deepPurple,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Attendance'),
                  Tab(text: 'Reports'),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildAttendanceTab(),
                  _buildReportsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? label : 'All';
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: Colors.deepPurple.shade50,
        checkmarkColor: Colors.deepPurple,
        labelStyle: TextStyle(
          color: isSelected ? Colors.deepPurple : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final linkedStudentIds = List<String>.from(userData?['linkedStudents'] ?? []);
        
        if (linkedStudentIds.isEmpty) {
          return _buildEmptyState();
        }
        
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('students')
              .where(FieldPath.documentId, whereIn: linkedStudentIds)
              .snapshots(),
          builder: (context, studentsSnapshot) {
            if (!studentsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            var students = studentsSnapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                ...data,
              };
            }).toList();
            
            // Apply search filter
            if (_searchQuery.isNotEmpty) {
              students = students.where((student) {
                final name = student['name']?.toLowerCase() ?? '';
                final grade = student['grade']?.toLowerCase() ?? '';
                final schoolId = student['schoolId']?.toLowerCase() ?? '';
                final query = _searchQuery.toLowerCase();
                return name.contains(query) || grade.contains(query) || schoolId.contains(query);
              }).toList();
            }
            
            // Apply grade/status filter
            if (_selectedFilter != 'All') {
              students = students.where((student) {
                if (_selectedFilter.startsWith('Grade')) {
                  final grade = _selectedFilter.split(' ')[1];
                  return student['grade']?.startsWith(grade) ?? false;
                } else if (_selectedFilter == 'Present' || _selectedFilter == 'Absent') {
                  final index = students.indexOf(student);
                  final isPresent = index % 2 == 0;
                  return (_selectedFilter == 'Present') ? isPresent : !isPresent;
                } else if (_selectedFilter == 'High Achiever') {
                  // Demo: Students with even index are high achievers
                  final index = students.indexOf(student);
                  return index % 3 == 0;
                } else if (_selectedFilter == 'Needs Attention') {
                  // Demo: Students with specific pattern need attention
                  final index = students.indexOf(student);
                  return index % 4 == 3;
                }
                return true;
              }).toList();
            }
            
            // Apply sorting
            students.sort((a, b) {
              int comparison = 0;
              switch (_sortBy) {
                case 'Name':
                  comparison = (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
                  break;
                case 'Grade':
                  comparison = (a['grade'] ?? '').toString().compareTo((b['grade'] ?? '').toString());
                  break;
                case 'Attendance':
                  // Demo: sort by attendance percentage (simulated)
                  final aAttendance = (a['name']?.hashCode ?? 0) % 100;
                  final bAttendance = (b['name']?.hashCode ?? 0) % 100;
                  comparison = aAttendance.compareTo(bAttendance);
                  break;
              }
              return _sortAscending ? comparison : -comparison;
            });
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return _buildEnhancedStudentCard(student, index);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAttendanceTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final linkedStudentIds = List<String>.from(userData?['linkedStudents'] ?? []);
        
        if (linkedStudentIds.isEmpty) {
          return _buildEmptyState();
        }
        
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('students')
              .where(FieldPath.documentId, whereIn: linkedStudentIds)
              .snapshots(),
          builder: (context, studentsSnapshot) {
            if (!studentsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final students = studentsSnapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                ...data,
              };
            }).toList();
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return _buildEnhancedAttendanceCard(student, index);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedAttendanceCard(Map<String, dynamic> student, int index) {
    // Generate mock attendance data for the last 30 days
    final attendanceData = List.generate(30, (dayIndex) {
      final random = (student['name']?.hashCode ?? 0) + dayIndex;
      return {
        'date': DateTime.now().subtract(Duration(days: 29 - dayIndex)),
        'status': ['present', 'absent', 'late'][random % 3],
        'arrivalTime': random % 3 == 0 ? '8:00 AM' : random % 3 == 1 ? 'Absent' : '8:15 AM',
        'departureTime': random % 3 == 0 ? '3:00 PM' : random % 3 == 1 ? 'Absent' : '3:00 PM',
      };
    });

    final presentDays = attendanceData.where((d) => d['status'] == 'present').length;
    final absentDays = attendanceData.where((d) => d['status'] == 'absent').length;
    final lateDays = attendanceData.where((d) => d['status'] == 'late').length;
    final attendanceRate = (presentDays + lateDays) / 30 * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _getGradeColor(student['grade']),
                  child: Text(
                    _getInitials(student['name'] ?? ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getAttendanceColor(attendanceRate).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${attendanceRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getAttendanceColor(attendanceRate),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Attendance Stats
            Row(
              children: [
                _buildAttendanceStatCard('Present', presentDays.toString(), Colors.green),
                _buildAttendanceStatCard('Absent', absentDays.toString(), Colors.red),
                _buildAttendanceStatCard('Late', lateDays.toString(), Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            
            // Mini Calendar View
            Text(
              'Last 7 Days',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayIndex) {
                final dayData = attendanceData[attendanceData.length - 7 + dayIndex];
                final date = dayData['date'] as DateTime;
                final status = dayData['status'] as String;
                
                return Column(
                  children: [
                    Text(
                      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date.day.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(status),
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: const Text('Full Calendar'),
                    onPressed: () => _showFullAttendanceCalendar(student, attendanceData),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.notifications, size: 18),
                    label: const Text('Set Alerts'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _setAttendanceAlerts(student),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAttendanceColor(double rate) {
    if (rate >= 95) return Colors.green;
    if (rate >= 90) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present': return Colors.green;
      case 'absent': return Colors.red;
      case 'late': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present': return Icons.check;
      case 'absent': return Icons.close;
      case 'late': return Icons.schedule;
      default: return Icons.help;
    }
  }

  void _showFullAttendanceCalendar(Map<String, dynamic> student, List<Map<String, dynamic>> attendanceData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${student['name']} - Attendance Calendar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: attendanceData.length,
                  itemBuilder: (context, index) {
                    final dayData = attendanceData[index];
                    final date = dayData['date'] as DateTime;
                    final status = dayData['status'] as String;
                    
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getStatusIcon(status),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${date.day}/${date.month}/${date.year}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Arrival: ${dayData['arrivalTime']} | Departure: ${dayData['departureTime']}',
                      ),
                      trailing: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setAttendanceAlerts(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendance Alerts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Daily Attendance'),
              subtitle: const Text('Get notified about daily attendance'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Absence Alerts'),
              subtitle: const Text('Alert when student is absent'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Late Arrival Alerts'),
              subtitle: const Text('Alert when student arrives late'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attendance alerts updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final linkedStudentIds = List<String>.from(userData?['linkedStudents'] ?? []);
        
        if (linkedStudentIds.isEmpty) {
          return _buildEmptyState();
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('students')
              .where(FieldPath.documentId, whereIn: linkedStudentIds)
              .snapshots(),
          builder: (context, studentsSnapshot) {
            if (!studentsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final students = studentsSnapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                ...data,
              };
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Summary Card
                  _buildOverallSummaryCard(students),
                  const SizedBox(height: 16),
                  
                  // Individual Student Reports
                  ...students.map((student) => _buildStudentReportCard(student)),
                  
                  // Quick Actions
                  const SizedBox(height: 16),
                  _buildQuickActionsCard(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOverallSummaryCard(List<Map<String, dynamic>> students) {
    final totalStudents = students.length;
    final averageAttendance = 94.5; // Mock data
    final totalAbsences = 3; // Mock data
    final upcomingEvents = 2; // Mock data
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.deepPurple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Family Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryMetric('Students', totalStudents.toString(), Icons.people),
              _buildSummaryMetric('Avg Attendance', '${averageAttendance.toStringAsFixed(1)}%', Icons.calendar_today),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryMetric('Total Absences', totalAbsences.toString(), Icons.warning),
              _buildSummaryMetric('Upcoming Events', upcomingEvents.toString(), Icons.event),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentReportCard(Map<String, dynamic> student) {
    // Generate mock performance data
    final subjectScores = {
      'Math': (student['name']?.hashCode ?? 0) % 20 + 80,
      'English': (student['name']?.hashCode ?? 0) % 15 + 85,
      'Science': (student['name']?.hashCode ?? 0) % 25 + 75,
      'History': (student['name']?.hashCode ?? 0) % 18 + 82,
    };
    
    final averageScore = subjectScores.values.reduce((a, b) => a + b) / subjectScores.length;
    final attendanceRate = ((student['name']?.hashCode ?? 0) % 10 + 90).toDouble();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getGradeColor(student['grade']),
                  child: Text(
                    _getInitials(student['name'] ?? ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Grade ${student['grade'] ?? ''} • Overall: ${averageScore.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPerformanceColor(averageScore).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPerformanceGrade(averageScore),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getPerformanceColor(averageScore),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject Performance
                const Text(
                  'Subject Performance',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...subjectScores.entries.map((entry) => 
                  _buildSubjectScore(entry.key, entry.value)
                ),
                
                const SizedBox(height: 16),
                
                // Quick Stats
                Row(
                  children: [
                    _buildQuickReportStat('Attendance', '${attendanceRate.toStringAsFixed(1)}%', 
                      _getAttendanceColor(attendanceRate)),
                    _buildQuickReportStat('Assignments', '12/14', Colors.blue),
                    _buildQuickReportStat('Behavior', 'Good', Colors.green),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.trending_up, size: 16),
                        label: const Text('Detailed Report'),
                        onPressed: () => _showDetailedReport(student),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Share'),
                        onPressed: () => _shareStudentReport(student),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectScore(String subject, int score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              subject,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getPerformanceColor(score.toDouble()),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$score%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getPerformanceColor(score.toDouble()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReportStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
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

  Widget _buildQuickActionsCard() {
    return Container(
      width: double.infinity,
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
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickActionChip('Export All Reports', Icons.file_download, () => _exportAllReports()),
              _buildQuickActionChip('Schedule Meeting', Icons.calendar_today, () => _scheduleMeeting()),
              _buildQuickActionChip('View Calendar', Icons.event, () => _viewCalendar()),
              _buildQuickActionChip('Send Message', Icons.message, () => _sendMessage()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.deepPurple),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.deepPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPerformanceColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.blue;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  String _getPerformanceGrade(double score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  void _showDetailedReport(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${student['name']} - Detailed Report'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Academic Trends', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('• Math: Improving steadily (+5% this month)'),
                const Text('• English: Consistent performance'),
                const Text('• Science: Excellent progress (+8% this month)'),
                const Text('• History: Needs attention (-2% this month)'),
                const SizedBox(height: 16),
                
                const Text('Attendance Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('• Total Days: 180'),
                const Text('• Present: 172 days (95.6%)'),
                const Text('• Absent: 8 days'),
                const Text('• Late: 3 times'),
                const SizedBox(height: 16),
                
                const Text('Teacher Comments', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('"Shows excellent participation in class discussions and demonstrates strong problem-solving skills."'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shareStudentReport(Map<String, dynamic> student) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${student['name']}\'s report...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportAllReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting all student reports...')),
    );
  }

  void _scheduleMeeting() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening meeting scheduler...')),
    );
  }

  void _viewCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening school calendar...')),
    );
  }

  void _sendMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening message composer...')),
    );
  }

  Widget _buildEnhancedStudentCard(Map<String, dynamic> student, int index) {
    final isPresent = index % 2 == 0; // Demo: alternating presence
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Student Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: _getGradeColor(student['grade']),
                      child: Text(
                        _getInitials(student['name'] ?? ''),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isPresent ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Student Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPresent ? Colors.green.shade200 : Colors.red.shade200,
                    ),
                  ),
                  child: Text(
                    isPresent ? 'Present' : 'Absent',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Quick Stats
            Row(
              children: [
                _buildQuickStat('Attendance', '96%', Colors.green),
                _buildQuickStat('Grade', 'A-', Colors.blue),
                _buildQuickStat('Behavior', 'Good', Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: const BorderSide(color: Colors.deepPurple),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _showStudentDetailsDialog(student),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('Contact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _contactTeacher(student),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
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

  Widget _buildEmptyState() {
    return Center(
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

  void _showStudentDetailsDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: Text(
                        _getInitials(student['name'] ?? ''),
                        style: TextStyle(
                          color: Colors.deepPurple,
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
                            student['name'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Grade ${student['grade'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
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
                      // Basic Information
                      _buildDetailSection('Basic Information', [
                        _buildDetailRow('Student ID', student['schoolId'] ?? 'N/A'),
                        _buildDetailRow('Grade', student['grade'] ?? 'N/A'),
                        _buildDetailRow('Status', 'Active'),
                        _buildDetailRow('Enrollment Date', 'Sep 1, 2024'),
                      ]),
                      
                      // Academic Performance
                      _buildDetailSection('Academic Performance', [
                        _buildDetailRow('Overall GPA', '3.8/4.0'),
                        _buildDetailRow('Class Rank', '15/30'),
                        _buildDetailRow('Attendance Rate', '96%'),
                        _buildDetailRow('Behavior Score', 'Excellent'),
                      ]),
                      
                      // Health Information
                      _buildDetailSection('Health Information', [
                        _buildDetailRow('Allergies', 'None reported'),
                        _buildDetailRow('Medical Conditions', 'None'),
                        _buildDetailRow('Emergency Contact', '+1234567890'),
                        _buildDetailRow('Doctor', 'Dr. Smith'),
                      ]),
                      
                      // Recent Activity
                      _buildDetailSection('Recent Activity', [
                        _buildActivityItem('Submitted Math Assignment', '2 hours ago'),
                        _buildActivityItem('Participated in Science Fair', '1 day ago'),
                        _buildActivityItem('Parent-Teacher Conference', '3 days ago'),
                      ]),
                    ],
                  ),
                ),
              ),
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.print),
                        label: const Text('Export Report'),
                        onPressed: () => _exportStudentReport(student),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.message),
                        label: const Text('Contact Teacher'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _contactTeacher(student),
                      ),
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

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActivityItem(String activity, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              activity,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _contactTeacher(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Teacher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose how you\'d like to contact ${student['name']}\'s teacher:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Send Email'),
              subtitle: const Text('teacher@school.edu'),
              onTap: () {
                Navigator.pop(context);
                _sendEmail(student);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call Teacher'),
              subtitle: const Text('+1 (555) 123-4567'),
              onTap: () {
                Navigator.pop(context);
                _callTeacher(student);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('School Messenger'),
              subtitle: const Text('Send via school app'),
              onTap: () {
                Navigator.pop(context);
                _sendSchoolMessage(student);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _sendEmail(Map<String, dynamic> student) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening email for ${student['name']}\'s teacher...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _callTeacher(Map<String, dynamic> student) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${student['name']}\'s teacher...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _sendSchoolMessage(Map<String, dynamic> student) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening school messenger for ${student['name']}...'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  void _exportStudentReport(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Export ${student['name']}\'s report as:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF Report'),
              onTap: () {
                Navigator.pop(context);
                _exportAsPDF(student);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel Spreadsheet'),
              onTap: () {
                Navigator.pop(context);
                _exportAsExcel(student);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _exportAsPDF(Map<String, dynamic> student) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting ${student['name']}\'s report as PDF...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _exportAsExcel(Map<String, dynamic> student) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting ${student['name']}\'s report as Excel...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
