import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      // Get today's date for pickup queue
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      // Load statistics
      final results = await Future.wait([
        _firestore.collection('students').get(),
        _firestore.collection('users').where('role', isEqualTo: 'guardian').get(),
        _database.ref('pickupQueue/$todayStr').get(),
        _firestore.collection('pickupLogs').where('timestamp', isGreaterThan: Timestamp.fromDate(DateTime(today.year, today.month, today.day))).get(),
      ]);
      
      final studentsSnapshot = results[0] as QuerySnapshot;
      final guardiansSnapshot = results[1] as QuerySnapshot;
      final pickupQueueSnapshot = results[2] as DataSnapshot;
      final todayPickupsSnapshot = results[3] as QuerySnapshot;
      
      // Calculate active pickups in queue
      int activePickups = 0;
      if (pickupQueueSnapshot.exists && pickupQueueSnapshot.value != null) {
        final queueData = pickupQueueSnapshot.value as Map<dynamic, dynamic>;
        activePickups = queueData.length;
      }
      
      // Calculate grade distribution
      Map<String, int> gradeDistribution = {};
      for (var doc in studentsSnapshot.docs) {
        final grade = doc.data() as Map<String, dynamic>;
        final gradeLevel = grade['grade'] ?? 'Unknown';
        gradeDistribution[gradeLevel] = (gradeDistribution[gradeLevel] ?? 0) + 1;
      }
      
      setState(() {
        _stats = {
          'totalStudents': studentsSnapshot.size,
          'totalGuardians': guardiansSnapshot.size,
          'activePickups': activePickups,
          'todayPickups': todayPickupsSnapshot.size,
          'gradeDistribution': gradeDistribution,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading statistics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.dashboard,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Schoolfy Admin Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Monitor and manage your school\'s pickup system',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Statistics Cards
          Expanded(
            child: GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  title: l10n.students,
                  value: _stats['totalStudents']?.toString() ?? '0',
                  icon: Icons.school,
                  color: AppTheme.primaryColor,
                ),
                _buildStatCard(
                  title: l10n.guardians,
                  value: _stats['totalGuardians']?.toString() ?? '0',
                  icon: Icons.people,
                  color: AppTheme.secondaryColor,
                ),
                _buildStatCard(
                  title: 'Active Pickups',
                  value: _stats['activePickups']?.toString() ?? '0',
                  icon: Icons.queue,
                  color: AppTheme.warningColor,
                ),
                _buildStatCard(
                  title: 'Today\'s Pickups',
                  value: _stats['todayPickups']?.toString() ?? '0',
                  icon: Icons.today,
                  color: AppTheme.successColor,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Grade Distribution Chart
          if (_stats['gradeDistribution'] != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bar_chart, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Student Distribution by Grade',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildGradeChart(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeChart() {
    final gradeDistribution = _stats['gradeDistribution'] as Map<String, int>? ?? {};
    
    if (gradeDistribution.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    final maxValue = gradeDistribution.values.reduce((a, b) => a > b ? a : b);
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      AppTheme.warningColor,
      AppTheme.successColor,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: gradeDistribution.entries.map((entry) {
        final index = gradeDistribution.keys.toList().indexOf(entry.key);
        final color = colors[index % colors.length];
        final height = (entry.value / maxValue) * 150;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              entry.value.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 40,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.key,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }
}
