import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
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
                      child: const Icon(
                        Icons.school,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.studentManagement,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddStudentDialog(),
                icon: const Icon(Icons.add),
                label: Text(l10n.addStudent),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _importStudentsFromCSV,
                icon: const Icon(Icons.upload_file),
                label: const Text('Import CSV'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search and Filter
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search students...',
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
          const SizedBox(height: 24),

          // Students Table
          Expanded(
            child: Card(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('students').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var students = snapshot.data!.docs.where((doc) {
                    final student = doc.data() as Map<String, dynamic>;
                    final name = (student['name'] ?? '').toString().toLowerCase();
                    final grade = student['grade'] ?? '';
                    
                    final matchesSearch = _searchQuery.isEmpty || 
                        name.contains(_searchQuery) ||
                        grade.toLowerCase().contains(_searchQuery);
                    
                    final matchesGrade = _selectedGrade.isEmpty || 
                        grade == _selectedGrade;
                    
                    return matchesSearch && matchesGrade;
                  }).toList();

                  return SingleChildScrollView(
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text(l10n.studentName)),
                        DataColumn(label: Text(l10n.grade)),
                        DataColumn(label: Text(l10n.guardianPhone)),
                        DataColumn(label: Text(l10n.status)),
                        const DataColumn(label: Text('Actions')),
                      ],
                      rows: students.map((doc) {
                        final student = doc.data() as Map<String, dynamic>;
                        final hasGuardian = student['primaryGuardianId'] != null;
                        
                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                    child: Text(
                                      (student['name'] ?? '?').toString().substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(student['name'] ?? 'Unknown'),
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  student['grade'] ?? 'N/A',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(student['guardianPhone'] ?? 'N/A')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: hasGuardian 
                                      ? AppTheme.successColor.withOpacity(0.1)
                                      : AppTheme.warningColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  hasGuardian ? 'Linked' : 'Pending',
                                  style: TextStyle(
                                    color: hasGuardian 
                                        ? AppTheme.successColor
                                        : AppTheme.warningColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _showEditStudentDialog(doc.id, student),
                                    icon: const Icon(Icons.edit, size: 18),
                                    tooltip: l10n.edit,
                                  ),
                                  IconButton(
                                    onPressed: () => _showDeleteStudentDialog(doc.id, student['name']),
                                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                    tooltip: l10n.delete,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog() {
    _showStudentDialog();
  }

  void _showEditStudentDialog(String studentId, Map<String, dynamic> student) {
    _showStudentDialog(studentId: studentId, initialData: student);
  }

  void _showStudentDialog({String? studentId, Map<String, dynamic>? initialData}) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: initialData?['name'] ?? '');
    final gradeController = TextEditingController(text: initialData?['grade'] ?? '');
    final phoneController = TextEditingController(text: initialData?['guardianPhone'] ?? '');
    final schoolIdController = TextEditingController(text: initialData?['schoolId'] ?? 'SCH_001');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(studentId == null ? l10n.addStudent : l10n.editStudent),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.studentName,
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: gradeController,
                  decoration: InputDecoration(
                    labelText: l10n.grade,
                    prefixIcon: const Icon(Icons.school),
                    hintText: 'e.g., 1A, 2B, 3C',
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Grade is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: l10n.guardianPhone,
                    prefixIcon: const Icon(Icons.phone),
                    hintText: '+966xxxxxxxxx',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Phone is required';
                    if (!RegExp(r'^\+966\d{9}$').hasMatch(value!)) {
                      return 'Enter valid Saudi phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: schoolIdController,
                  decoration: InputDecoration(
                    labelText: l10n.schoolId,
                    prefixIcon: const Icon(Icons.location_city),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'School ID is required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final studentData = {
                    'name': nameController.text.trim(),
                    'grade': gradeController.text.trim(),
                    'guardianPhone': phoneController.text.trim(),
                    'schoolId': schoolIdController.text.trim(),
                    'primaryGuardianId': initialData?['primaryGuardianId'],
                    'authorizedGuardianIds': initialData?['authorizedGuardianIds'] ?? [],
                    'status': 'pending',
                    'createdAt': studentId == null ? FieldValue.serverTimestamp() : initialData?['createdAt'],
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  if (studentId == null) {
                    await _firestore.collection('students').add(studentData);
                  } else {
                    await _firestore.collection('students').doc(studentId).update(studentData);
                  }

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(studentId == null ? 'Student added successfully' : 'Student updated successfully'),
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
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showDeleteStudentDialog(String studentId, String? studentName) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteStudent),
        content: Text('Are you sure you want to delete ${studentName ?? "this student"}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('students').doc(studentId).delete();
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student deleted successfully'),
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _importStudentsFromCSV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.bytes != null) {
        final csvData = utf8.decode(result.files.single.bytes!);
        final csvTable = const CsvToListConverter().convert(csvData);
        
        if (csvTable.isEmpty) return;
        
        // Assuming CSV format: name, grade, guardianPhone, schoolId
        final students = <Map<String, dynamic>>[];
        for (int i = 1; i < csvTable.length; i++) { // Skip header row
          final row = csvTable[i];
          if (row.length >= 4) {
            students.add({
              'name': row[0].toString().trim(),
              'grade': row[1].toString().trim(),
              'guardianPhone': row[2].toString().trim(),
              'schoolId': row[3].toString().trim(),
              'primaryGuardianId': null,
              'authorizedGuardianIds': [],
              'status': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        if (students.isNotEmpty) {
          // Import in batches
          final batch = _firestore.batch();
          for (var student in students) {
            final docRef = _firestore.collection('students').doc();
            batch.set(docRef, student);
          }
          
          await batch.commit();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Imported ${students.length} students successfully'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
