import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class StudentAttendancePage extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentAttendancePage({super.key, required this.student});

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedPeriod = 'Week';
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _updateDateRange();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Week':
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = _startDate.add(const Duration(days: 6));
        break;
      case 'Month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'All':
        _startDate = now.subtract(const Duration(days: 365));
        _endDate = now;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Student Avatar and Name
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(widget.student['studentName'] ?? 'S'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.student['studentName'] ?? 'Unknown Student',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Grade ${widget.student['grade'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Attendance History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Period Selector
                  _buildPeriodSelector(),
                  const SizedBox(height: 24),

                  // Attendance Summary
                  _buildAttendanceSummary(),
                  const SizedBox(height: 24),

                  // Attendance Records
                  _buildAttendanceRecords(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: ['Week', 'Month', 'All'].map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                  _updateDateRange();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: widget.student['studentId'])
          .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(_startDate))
          .where('date', isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(_endDate))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data!.docs;
        final totalDays = records.length;
        final presentDays = records.where((doc) => 
          (doc.data() as Map<String, dynamic>)['status'] == 'present').length;
        final lateDays = records.where((doc) => 
          (doc.data() as Map<String, dynamic>)['status'] == 'late').length;
        final absentDays = records.where((doc) => 
          (doc.data() as Map<String, dynamic>)['status'] == 'absent').length;

        final attendanceRate = totalDays > 0 ? (presentDays + lateDays) / totalDays : 0.0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            children: [
              // Attendance Rate Circle
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getAttendanceRateColor(attendanceRate).withOpacity(0.1),
                    ),
                    child: Center(
                      child: Text(
                        '${(attendanceRate * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getAttendanceRateColor(attendanceRate),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Rate',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getAttendanceRateText(attendanceRate),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Statistics Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Present',
                      presentDays.toString(),
                      AppTheme.successColor,
                      Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Late',
                      lateDays.toString(),
                      AppTheme.warningColor,
                      Icons.schedule,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Absent',
                      absentDays.toString(),
                      AppTheme.errorColor,
                      Icons.cancel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecords() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: widget.student['studentId'])
          .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(_startDate))
          .where('date', isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(_endDate))
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data!.docs;

        if (records.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No attendance records',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Attendance records will appear here',
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Recent Records',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: AppTheme.dividerColor,
                ),
                itemBuilder: (context, index) {
                  final record = records[index].data() as Map<String, dynamic>;
                  return _buildAttendanceRecordTile(record);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceRecordTile(Map<String, dynamic> record) {
    final status = record['status'] ?? 'unmarked';
    final date = record['date'] ?? '';
    final markedAt = record['markedAt'] as Timestamp?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Status Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(status),
              color: _getStatusColor(status),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Date and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Time
          if (markedAt != null)
            Text(
              DateFormat('HH:mm').format(markedAt.toDate()),
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _getAttendanceRateColor(double rate) {
    if (rate >= 0.9) return AppTheme.successColor;
    if (rate >= 0.7) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _getAttendanceRateText(double rate) {
    if (rate >= 0.9) return 'Excellent';
    if (rate >= 0.7) return 'Good';
    return 'Needs Improvement';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return AppTheme.successColor;
      case 'absent':
        return AppTheme.errorColor;
      case 'late':
        return AppTheme.warningColor;
      case 'excused':
        return AppTheme.infoColor;
      default:
        return AppTheme.textTertiary;
    }
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('EEEE, MMM dd').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
