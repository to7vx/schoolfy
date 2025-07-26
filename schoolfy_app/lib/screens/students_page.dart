import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _sortBy = 'Name';
  bool _sortAscending = true;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
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
                    padding: const EdgeInsets.all(AppTheme.spacingXXL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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
                                const Text(
                                  'Students',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hi $firstName!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${linkedStudents.length} student${linkedStudents.length != 1 ? 's' : ''} linked',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
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
          
          // Search and Filter Section
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                children: [
                  // Search Bar with Sort Button
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search students...',
                              hintStyle: TextStyle(color: AppTheme.textTertiary),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: AppTheme.textTertiary,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear_rounded,
                                        color: AppTheme.textTertiary,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingM,
                                vertical: AppTheme.spacingM,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: PopupMenuButton<String>(
                          icon: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                            child: Icon(
                              Icons.sort_rounded,
                              color: AppTheme.primaryColor,
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
                                  const Icon(Icons.person_rounded),
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
                                  const Icon(Icons.school_rounded),
                                  const SizedBox(width: 8),
                                  const Text('Sort by Grade'),
                                  if (_sortBy == 'Grade') ...[
                                    const Spacer(),
                                    Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  // Dynamic Filter Chips
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('grades')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final grades = <String>[];
                      
                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          final gradeData = doc.data() as Map<String, dynamic>;
                          final gradeName = gradeData['name'] as String?;
                          if (gradeName != null && gradeName.isNotEmpty) {
                            grades.add(gradeName);
                          }
                        }
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildModernFilterChip('All'),
                            ...grades.map((grade) => _buildModernFilterChip(grade)),
                            _buildModernFilterChip('Present'),
                            _buildModernFilterChip('Absent'),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Students List
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            sliver: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                final linkedStudentIds = List<String>.from(userData?['linkedStudents'] ?? []);

                if (linkedStudentIds.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(),
                  );
                }

                // Fetch student details from students collection
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('students')
                      .where(FieldPath.documentId, whereIn: linkedStudentIds)
                      .snapshots(),
                  builder: (context, studentSnapshot) {
                    if (studentSnapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (studentSnapshot.hasError) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Error loading students: ${studentSnapshot.error}'),
                            ],
                          ),
                        ),
                      );
                    }

                    final allStudents = studentSnapshot.data?.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {
                        'studentId': doc.id,
                        'studentName': data['name'] ?? data['studentName'] ?? '',
                        'grade': data['grade'] ?? '',
                        'schoolId': data['schoolId'] ?? '',
                      };
                    }).toList() ?? [];

                    // Apply filtering
                    List<Map<String, dynamic>> filteredStudents = allStudents.where((student) {
                      // Search filter
                      if (_searchQuery.isNotEmpty) {
                        final studentName = (student['studentName'] as String).toLowerCase();
                        if (!studentName.contains(_searchQuery.toLowerCase())) {
                          return false;
                        }
                      }

                      // Grade filter
                      if (_selectedFilter != 'All' && _selectedFilter != 'Present' && _selectedFilter != 'Absent') {
                        final studentGrade = student['grade'] as String;
                        if (studentGrade != _selectedFilter) {
                          return false;
                        }
                      }

                      // Status filters (Present/Absent) can be implemented later with actual status data
                      
                      return true;
                    }).toList();

                    // Apply sorting
                    if (_sortBy == 'Name') {
                      filteredStudents.sort((a, b) {
                        final nameA = (a['studentName'] as String).toLowerCase();
                        final nameB = (b['studentName'] as String).toLowerCase();
                        return _sortAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
                      });
                    } else if (_sortBy == 'Grade') {
                      filteredStudents.sort((a, b) {
                        final gradeA = a['grade'] as String;
                        final gradeB = b['grade'] as String;
                        return _sortAscending ? gradeA.compareTo(gradeB) : gradeB.compareTo(gradeA);
                      });
                    }

                    if (filteredStudents.isEmpty) {
                      return SliverFillRemaining(
                        child: _buildEmptyState(),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildModernStudentCard(filteredStudents[index], index),
                        childCount: filteredStudents.length,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Container(
      margin: const EdgeInsets.only(right: AppTheme.spacingS),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? label : 'All';
          });
        },
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryColor,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.3),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.school_rounded,
                size: 60,
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXXL),
            Text(
              'No students linked yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Contact your school to link your children to your account',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStudentCard(Map<String, dynamic> student, int index) {
    final studentName = student['studentName'] ?? 'Unknown Student';
    final grade = student['grade'] ?? 'N/A';
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          onTap: () => _showStudentDetails(context, student),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                // Modern Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getModernAvatarColor(index),
                        _getModernAvatarColor(index).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(studentName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingL),
                
                // Student Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              grade,
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Al-Noor Elementary',
                              style: TextStyle(
                                color: AppTheme.textTertiary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status and Action
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.successColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppTheme.textTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getModernAvatarColor(int index) {
    const colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.infoColor,
    ];
    return colors[index % colors.length];
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(student['studentName'] ?? ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
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
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
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
                      _buildDetailItem('Today', 'Present'),
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
                color: AppTheme.textSecondary,
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
}
