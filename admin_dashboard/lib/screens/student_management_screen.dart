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
  final TextEditingController _gradeNameController = TextEditingController();
  
  String _searchQuery = '';
  String _selectedGrade = '';

  @override
  void dispose() {
    _searchController.dispose();
    _gradeNameController.dispose();
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
                onPressed: _showGradeManagementDialog,
                icon: const Icon(Icons.grade),
                label: const Text('Manage Grades'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
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
                // Grade Dropdown with grades from Firestore
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('grades').orderBy('name').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return TextFormField(
                        controller: gradeController,
                        decoration: InputDecoration(
                          labelText: l10n.grade,
                          prefixIcon: const Icon(Icons.school),
                          hintText: 'Error loading grades',
                          errorText: 'Failed to load grades',
                        ),
                      );
                    }

                    List<String> availableGrades = [];
                    if (snapshot.hasData) {
                      availableGrades = snapshot.data!.docs
                          .map((doc) => (doc.data() as Map<String, dynamic>)['name'] as String)
                          .toList();
                    }

                    // If no grades exist, show text field with button to manage grades
                    if (availableGrades.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: gradeController,
                            decoration: InputDecoration(
                              labelText: l10n.grade,
                              prefixIcon: const Icon(Icons.school),
                              hintText: 'No grades available',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.settings),
                                onPressed: () {
                                  Navigator.of(context).pop(); // Close current dialog
                                  _showGradeManagementDialog(); // Open grade management
                                },
                                tooltip: 'Manage Grades',
                              ),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Grade is required' : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Click the settings icon to add grades first',
                            style: TextStyle(
                              color: Colors.orange[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    }

                    // Ensure current grade is in the list (for editing existing students)
                    String? selectedGrade = gradeController.text.isNotEmpty ? gradeController.text : null;
                    if (selectedGrade != null && !availableGrades.contains(selectedGrade)) {
                      availableGrades.add(selectedGrade);
                    }

                    return DropdownButtonFormField<String>(
                      value: selectedGrade,
                      decoration: InputDecoration(
                        labelText: l10n.grade,
                        prefixIcon: const Icon(Icons.school),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.settings, size: 18),
                          onPressed: () {
                            Navigator.of(context).pop(); // Close current dialog
                            _showGradeManagementDialog(); // Open grade management
                          },
                          tooltip: 'Manage Grades',
                        ),
                      ),
                      items: availableGrades.map((grade) => DropdownMenuItem(
                        value: grade,
                        child: Text(grade),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          gradeController.text = value ?? '';
                        });
                      },
                      validator: (value) => value?.isEmpty ?? true ? 'Please select a grade' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
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

  // Grade Management Dialog
  void _showGradeManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.grade, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Manage Grades'),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: Column(
            children: [
              // Add new grade section
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gradeNameController,
                      decoration: const InputDecoration(
                        labelText: 'New Grade Name',
                        hintText: 'e.g., Grade 1A, Grade 2B',
                        prefixIcon: Icon(Icons.school),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _addGradeFromTextField(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              // Existing grades list
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Existing Grades:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('grades').orderBy('name').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.school, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No grades available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add your first grade above',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final gradeData = doc.data() as Map<String, dynamic>;
                        final gradeName = gradeData['name'] ?? '';
                        final gradeDescription = gradeData['description'] ?? '';
                        final createdAt = gradeData['createdAt'] as Timestamp?;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              child: Text(
                                gradeName.isNotEmpty ? gradeName[0].toUpperCase() : 'G',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              gradeName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (gradeDescription.isNotEmpty)
                                  Text(gradeDescription),
                                if (createdAt != null)
                                  Text(
                                    'Created: ${createdAt.toDate().toString().split(' ')[0]}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => _editGrade(doc.id, gradeData),
                                  tooltip: 'Edit Grade',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                  onPressed: () => _deleteGrade(doc.id, gradeName),
                                  tooltip: 'Delete Grade',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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

  Future<void> _addGradeFromTextField() async {
    final gradeName = _gradeNameController.text.trim();
    if (gradeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a grade name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await _addGradeToFirestore(gradeName, '');
    _gradeNameController.clear(); // Clear the text field after adding
  }

  Future<void> _addGradeToFirestore(String name, String description) async {
    try {
      await _firestore.collection('grades').add({
        'name': name,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Grade "$name" added successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add grade: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editGrade(String gradeId, Map<String, dynamic> gradeData) {
    final nameController = TextEditingController(text: gradeData['name'] ?? '');
    final descriptionController = TextEditingController(text: gradeData['description'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Grade'),
        content: SizedBox(
          width: 300,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Grade Name *',
                    prefixIcon: Icon(Icons.school),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Grade name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _firestore.collection('grades').doc(gradeId).update({
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Grade "${nameController.text}" updated successfully'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update grade: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGrade(String gradeId, String gradeName) async {
    // Check if grade is being used by any students
    final studentsUsingGrade = await _firestore
        .collection('students')
        .where('grade', isEqualTo: gradeName)
        .get();

    if (!mounted) return;

    if (studentsUsingGrade.docs.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete Grade'),
          content: Text(
            'This grade is currently assigned to ${studentsUsingGrade.docs.length} student(s). '
            'Please reassign or remove these students first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the grade "$gradeName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('grades').doc(gradeId).delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Grade "$gradeName" deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete grade: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
