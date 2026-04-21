import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:html' as html;

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class PickupHistoryScreen extends StatefulWidget {
  const PickupHistoryScreen({super.key});

  @override
  State<PickupHistoryScreen> createState() => _PickupHistoryScreenState();
}

class _PickupHistoryScreenState extends State<PickupHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  String _selectedGrade = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Export Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.pickupHistory,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _exportHistory,
                icon: const Icon(Icons.download),
                label: Text(l10n.exportLogs),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Search
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by student name...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    icon: const Icon(Icons.clear),
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value.toLowerCase());
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Grade Filter
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _firestore.collection('students').snapshots(),
                          builder: (context, snapshot) {
                            final grades = <String>{'All'};
                            if (snapshot.hasData) {
                              for (var doc in snapshot.data!.docs) {
                                final student = doc.data() as Map<String, dynamic>;
                                if (student['grade'] != null) {
                                  grades.add(student['grade']);
                                }
                              }
                            }
                            
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Grade',
                                prefixIcon: Icon(Icons.school),
                              ),
                              value: _selectedGrade.isEmpty ? 'All' : _selectedGrade,
                              items: grades.map((grade) => 
                                DropdownMenuItem(value: grade, child: Text(grade))
                              ).toList(),
                              onChanged: (value) {
                                setState(() => _selectedGrade = value == 'All' ? '' : value!);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Range
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectStartDate(),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_startDate != null 
                              ? 'From: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                              : 'Start Date'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectEndDate(),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_endDate != null 
                              ? 'To: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'End Date'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_startDate != null || _endDate != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                          },
                          child: const Text('Clear Dates'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // History List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildHistoryQuery(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var pickups = snapshot.data!.docs.where((doc) {
                  final pickup = doc.data() as Map<String, dynamic>;
                  final studentName = (pickup['studentName'] ?? '').toString().toLowerCase();
                  
                  final matchesSearch = _searchQuery.isEmpty || 
                      studentName.contains(_searchQuery);
                  
                  return matchesSearch;
                }).toList();

                if (pickups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pickup history found',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters or date range.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: pickups.length,
                  itemBuilder: (context, index) {
                    final pickup = pickups[index].data() as Map<String, dynamic>;
                    return _buildHistoryCard(pickup);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _buildHistoryQuery() {
    Query query = _firestore.collection('pickupLogs');
    
    // Apply date filters
    if (_startDate != null) {
      query = query.where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
    }
    if (_endDate != null) {
      final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      query = query.where('completedAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }
    
    return query.orderBy('completedAt', descending: true).snapshots();
  }

  Widget _buildHistoryCard(Map<String, dynamic> pickup) {
    final studentName = pickup['studentName'] ?? 'Unknown Student';
    final studentId = pickup['studentId'] ?? '';
    final completedAt = pickup['completedAt'] as Timestamp?;
    final date = pickup['date'] ?? 'Unknown';
    final completedBy = pickup['completedBy'] ?? 'Unknown';

    final completedTime = completedAt?.toDate();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.successColor.withOpacity(0.1),
          child: Icon(
            Icons.check_circle,
            color: AppTheme.successColor,
          ),
        ),
        title: Text(
          studentName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  completedTime != null 
                      ? '${completedTime.hour.toString().padLeft(2, '0')}:${completedTime.minute.toString().padLeft(2, '0')}'
                      : 'N/A',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Completed by: $completedBy',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
        trailing: FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('students').doc(studentId).get(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              final student = snapshot.data!.data() as Map<String, dynamic>;
              final grade = student['grade'] ?? 'N/A';
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  grade,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _exportHistory() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting history...'),
            ],
          ),
        ),
      );

      // Fetch all history data
      final query = _buildHistoryQuery();
      final snapshot = await query.first;
      
      if (mounted) Navigator.of(context).pop(); // Close loading dialog

      final csvData = <List<String>>[
        ['Student Name', 'Student ID', 'Date', 'Completed Time', 'Completed By'], // Header
      ];

      for (var doc in snapshot.docs) {
        final pickup = doc.data() as Map<String, dynamic>;
        final completedAt = pickup['completedAt'] as Timestamp?;
        final completedTime = completedAt?.toDate();
        
        csvData.add([
          pickup['studentName'] ?? 'Unknown',
          pickup['studentId'] ?? 'Unknown',
          pickup['date'] ?? 'Unknown',
          completedTime != null 
              ? '${completedTime.day}/${completedTime.month}/${completedTime.year} ${completedTime.hour.toString().padLeft(2, '0')}:${completedTime.minute.toString().padLeft(2, '0')}'
              : 'Unknown',
          pickup['completedBy'] ?? 'Unknown',
        ]);
      }

      final csvString = const ListToCsvConverter().convert(csvData);
      final bytes = utf8.encode(csvString);
      
      // Download file
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'pickup_history_${DateTime.now().millisecondsSinceEpoch}.csv';
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('History exported successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
