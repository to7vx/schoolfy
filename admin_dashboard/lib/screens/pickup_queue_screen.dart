import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class PickupQueueScreen extends StatefulWidget {
  const PickupQueueScreen({super.key});

  @override
  State<PickupQueueScreen> createState() => _PickupQueueScreenState();
}

class _PickupQueueScreenState extends State<PickupQueueScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _selectedDate = '';
  String _filterGrade = '';
  late DatabaseReference _queueRef;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    _queueRef = _database.ref('pickupQueue/$_selectedDate');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Controls
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.queue,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.livePickupQueue,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Date Picker
              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(_selectedDate),
              ),
              const SizedBox(width: 8),
              // Clear All Button
              ElevatedButton.icon(
                onPressed: _showClearAllDialog,
                icon: const Icon(Icons.clear_all),
                label: Text(l10n.clearAll),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filter by Grade
          Row(
            children: [
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
                        labelText: 'Filter by Grade',
                        prefixIcon: Icon(Icons.filter_list),
                      ),
                      value: _filterGrade.isEmpty ? 'All' : _filterGrade,
                      items: grades.map((grade) => 
                        DropdownMenuItem(value: grade, child: Text(grade))
                      ).toList(),
                      onChanged: (value) {
                        setState(() => _filterGrade = value == 'All' ? '' : value!);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Real-time indicator
              StreamBuilder<DatabaseEvent>(
                stream: _queueRef.onValue,
                builder: (context, snapshot) {
                  final count = snapshot.hasData && snapshot.data!.snapshot.exists
                      ? (snapshot.data!.snapshot.value as Map<dynamic, dynamic>).length
                      : 0;
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: count > 0 ? AppTheme.warningColor.withOpacity(0.1) : AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: count > 0 ? AppTheme.warningColor : AppTheme.successColor,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: count > 0 ? AppTheme.warningColor : AppTheme.successColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Live: $count in queue',
                          style: TextStyle(
                            color: count > 0 ? AppTheme.warningColor : AppTheme.successColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pickup Queue List
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _queueRef.onValue,
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

                if (!snapshot.hasData || !snapshot.data!.snapshot.exists) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: AppTheme.successColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pickup requests for $_selectedDate',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All students have been picked up or no requests made.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final queueData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                var pickupRequests = queueData.entries.toList();

                // Sort by timestamp (newest first)
                pickupRequests.sort((a, b) {
                  final aTime = a.value['timestamp'] ?? 0;
                  final bTime = b.value['timestamp'] ?? 0;
                  return bTime.compareTo(aTime);
                });

                // Filter by grade if selected
                if (_filterGrade.isNotEmpty) {
                  pickupRequests = pickupRequests.where((entry) {
                    final grade = entry.value['grade'] ?? '';
                    return grade == _filterGrade;
                  }).toList();
                }

                if (pickupRequests.isEmpty && _filterGrade.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_list_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No pickup requests for grade $_filterGrade'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: pickupRequests.length,
                  itemBuilder: (context, index) {
                    final entry = pickupRequests[index];
                    final studentId = entry.key;
                    final pickupData = entry.value as Map<dynamic, dynamic>;
                    
                    return _buildPickupCard(studentId, pickupData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupCard(String studentId, Map<dynamic, dynamic> pickupData) {
    final studentName = pickupData['studentName'] ?? 'Unknown Student';
    final grade = pickupData['grade'] ?? 'N/A';
    final guardianName = pickupData['guardianName'] ?? 'Unknown Guardian';
    final guardianPhone = pickupData['guardianPhone'] ?? 'N/A';
    final timestamp = pickupData['timestamp'] ?? 0;
    final requestTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final waitingTime = DateTime.now().difference(requestTime);

    // Color coding based on waiting time
    Color cardColor = AppTheme.successColor;
    Color textColor = AppTheme.successColor;
    String priorityLabel = 'Normal';
    
    if (waitingTime.inMinutes > 15) {
      cardColor = AppTheme.errorColor;
      textColor = AppTheme.errorColor;
      priorityLabel = 'High Priority';
    } else if (waitingTime.inMinutes > 10) {
      cardColor = AppTheme.warningColor;
      textColor = AppTheme.warningColor;
      priorityLabel = 'Medium Priority';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardColor.withOpacity(0.3), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor.withOpacity(0.05),
              cardColor.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cardColor.withOpacity(0.2),
                    child: Text(
                      studentName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              studentName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Guardian: $guardianName',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      priorityLabel,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Details Row
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.access_time,
                      'Requested',
                      '${requestTime.hour.toString().padLeft(2, '0')}:${requestTime.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.timer,
                      'Waiting',
                      _formatDuration(waitingTime),
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.phone,
                      'Contact',
                      guardianPhone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _clearPickupEntry(studentId, studentName),
                      icon: const Icon(Icons.done, size: 18),
                      label: const Text('Mark as Picked Up'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showContactDialog(guardianName, guardianPhone),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Contact'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_selectedDate.replaceAll('-', '')),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        _queueRef = _database.ref('pickupQueue/$_selectedDate');
      });
    }
  }

  void _showClearAllDialog() {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearAll),
        content: const Text('Are you sure you want to clear all pickup entries for this date? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearAllPickupEntries();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.clearAll),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(String guardianName, String guardianPhone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Guardian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Guardian: $guardianName'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 16),
                const SizedBox(width: 8),
                SelectableText(guardianPhone),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearPickupEntry(String studentId, String studentName) async {
    try {
      // Remove from pickup queue
      await _queueRef.child(studentId).remove();
      
      // Log the pickup completion
      await _firestore.collection('pickupLogs').add({
        'studentId': studentId,
        'studentName': studentName,
        'completedAt': FieldValue.serverTimestamp(),
        'date': _selectedDate,
        'completedBy': 'admin', // In real app, use actual admin ID
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$studentName marked as picked up'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllPickupEntries() async {
    try {
      await _queueRef.remove();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All pickup entries cleared'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
