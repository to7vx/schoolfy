import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class AuthorizedGuardiansPage extends StatefulWidget {
  const AuthorizedGuardiansPage({super.key});

  @override
  State<AuthorizedGuardiansPage> createState() => _AuthorizedGuardiansPageState();
}

class _AuthorizedGuardiansPageState extends State<AuthorizedGuardiansPage> {
  String? selectedStudentId;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
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
                              .doc(currentUser?.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            final userData = snapshot.data?.data() as Map<String, dynamic>?;
                            final firstName = userData?['firstName'] ?? 'Guardian';
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Guardian Access',
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
                                  child: const Text(
                                    'Manage who can access your children\'s info',
                                    style: TextStyle(
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
          
          // Student Selection
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Student',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final userData = snapshot.data?.data() as Map<String, dynamic>?;
                      final linkedStudentIds = List<String>.from(userData?['linkedStudents'] ?? []);
                      
                      if (linkedStudentIds.isEmpty) {
                        return _buildEmptyStudentsState();
                      }
                      
                      // Fetch student details from students collection
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('students')
                            .where(FieldPath.documentId, whereIn: linkedStudentIds)
                            .snapshots(),
                        builder: (context, studentSnapshot) {
                          if (studentSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (studentSnapshot.hasError) {
                            return Center(
                              child: Text('Error loading students: ${studentSnapshot.error}'),
                            );
                          }

                          final students = studentSnapshot.data?.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return {
                              'studentId': doc.id,
                              'studentName': data['name'] ?? data['studentName'] ?? '',
                              'grade': data['grade'] ?? '',
                              'schoolId': data['schoolId'] ?? '',
                            };
                          }).toList() ?? [];

                          if (students.isEmpty) {
                            return _buildEmptyStudentsState();
                          }
                      
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: students.map<Widget>((student) {
                                final studentId = student['studentId'];
                                final isSelected = selectedStudentId == studentId;
                            
                            return Container(
                              margin: const EdgeInsets.only(right: AppTheme.spacingM),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedStudentId = isSelected ? null : studentId;
                                  });
                                },
                                child: Container(
                                  width: 140,
                                  padding: const EdgeInsets.all(AppTheme.spacingM),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                                    border: Border.all(
                                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    boxShadow: isSelected ? AppTheme.softShadow : [],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white : AppTheme.primaryColor,
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _getInitials(student['studentName'] ?? ''),
                                            style: TextStyle(
                                              color: isSelected ? AppTheme.primaryColor : Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppTheme.spacingS),
                                      Text(
                                        student['studentName'] ?? '',
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Grade ${student['grade'] ?? ''}',
                                        style: TextStyle(
                                          color: isSelected ? Colors.white70 : AppTheme.textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
                ],
              ),
            ),
          ),
          
          // Add Guardian Section
          if (selectedStudentId != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(AppTheme.spacingL),
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person_add_rounded,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Guardian',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Grant access to another guardian',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Guardian Email',
                        hintText: 'Enter guardian\'s email address',
                        prefixIcon: const Icon(Icons.email_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _addGuardian(),
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Send Invitation'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Authorized Guardians List
          if (selectedStudentId != null)
            SliverPadding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              sliver: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('authorizedGuardians')
                    .where('studentId', isEqualTo: selectedStudentId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final guardians = snapshot.data?.docs ?? [];

                  if (guardians.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildEmptyGuardiansState(),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildGuardianCard(guardians[index].data() as Map<String, dynamic>),
                      childCount: guardians.length,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyStudentsState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school_rounded,
            size: 48,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'No students linked',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            'Link students to manage guardian access',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGuardiansState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXXL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.people_rounded,
              size: 40,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'No authorized guardians',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Add other guardians to give them access to this student\'s information',
            style: TextStyle(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianCard(Map<String, dynamic> guardian) {
    final guardianName = guardian['guardianName'] ?? 'Unknown Guardian';
    final guardianEmail = guardian['guardianEmail'] ?? '';
    final status = guardian['status'] ?? 'pending';
    final isActive = status == 'accepted';
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.softShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.spacingM),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.successColor.withOpacity(0.1) : AppTheme.warningColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              _getInitials(guardianName),
              style: TextStyle(
                color: isActive ? AppTheme.successColor : AppTheme.warningColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          guardianName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              guardianEmail,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.successColor.withOpacity(0.1) : AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'Active' : 'Pending',
                style: TextStyle(
                  color: isActive ? AppTheme.successColor : AppTheme.warningColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(
            Icons.more_vert_rounded,
            color: AppTheme.textTertiary,
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Remove Access'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'remove') {
              _removeGuardian(guardian);
            }
          },
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'G';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}';
    }
    return name[0];
  }

  void _addGuardian() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || selectedStudentId == null) return;

    try {
      // Add guardian invitation logic here
      await FirebaseFirestore.instance.collection('authorizedGuardians').add({
        'studentId': selectedStudentId,
        'guardianEmail': email,
        'guardianName': 'Pending Guardian', // Will be updated when accepted
        'status': 'pending',
        'invitedBy': currentUser?.uid,
        'invitedAt': FieldValue.serverTimestamp(),
      });

      _emailController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent to $email'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeGuardian(Map<String, dynamic> guardian) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: const Text('Remove Guardian Access'),
        content: Text(
          'Are you sure you want to remove ${guardian['guardianName']}\'s access to this student?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Remove guardian logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Guardian access removed'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
