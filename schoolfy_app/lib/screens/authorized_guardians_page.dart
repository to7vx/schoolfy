import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthorizedGuardiansPage extends StatefulWidget {
  const AuthorizedGuardiansPage({super.key});

  @override
  State<AuthorizedGuardiansPage> createState() => _AuthorizedGuardiansPageState();
}

class _AuthorizedGuardiansPageState extends State<AuthorizedGuardiansPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String? selectedStudentId;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
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
                                .doc(currentUser?.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final userData = snapshot.data?.data() as Map<String, dynamic>?;
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
                                    'Manage Guardian Access',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Control who can access your children\'s information',
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
            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.deepPurple,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.deepPurple,
                tabs: const [
                  Tab(text: 'My Students'),
                  Tab(text: 'Authorizations'),
                  Tab(text: 'Requests'),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMyStudentsTab(),
                  _buildAuthorizationsTab(),
                  _buildRequestsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyStudentsTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final linkedStudentIds = List<String>.from(userData?['linkedStudents'] ?? []);

        if (linkedStudentIds.isEmpty) {
          return _buildEmptyState(
            icon: Icons.school_outlined,
            title: 'No Students Linked',
            subtitle: 'Contact your school to link your children',
          );
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

            final students = studentsSnapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final studentData = student.data() as Map<String, dynamic>;
                return _buildStudentCard(student.id, studentData);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStudentCard(String studentId, Map<String, dynamic> studentData) {
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
            // Student Header
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _getGradeColor(studentData['grade']),
                  child: Text(
                    _getInitials(studentData['name'] ?? ''),
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
                        studentData['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Grade ${studentData['grade'] ?? ''}',
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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Primary',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Authorized Guardians Count
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('guardian_authorizations')
                  .where('studentId', isEqualTo: studentId)
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, authSnapshot) {
                final authCount = authSnapshot.data?.docs.length ?? 0;
                
                return Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$authCount Authorized Guardian${authCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Guardians'),
                    onPressed: () => _showStudentGuardians(studentId, studentData),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Add Guardian'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showAddGuardianDialog(studentId, studentData),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorizationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('guardian_authorizations')
          .where('primaryGuardianId', isEqualTo: currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final authorizations = snapshot.data!.docs;

        if (authorizations.isEmpty) {
          return _buildEmptyState(
            icon: Icons.security,
            title: 'No Authorizations',
            subtitle: 'You haven\'t authorized any guardians yet',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: authorizations.length,
          itemBuilder: (context, index) {
            final auth = authorizations[index];
            final authData = auth.data() as Map<String, dynamic>;
            return _buildAuthorizationCard(auth.id, authData);
          },
        );
      },
    );
  }

  Widget _buildAuthorizationCard(String authId, Map<String, dynamic> authData) {
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
            // Authorization Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getStatusColor(authData['status']),
                  child: Text(
                    _getInitials(authData['guardianName'] ?? ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
                        authData['guardianName'] ?? 'Unknown Guardian',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        authData['guardianPhone'] ?? '',
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
                    color: _getStatusColor(authData['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(authData['status']),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(authData['status']),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Student Info
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('students')
                  .doc(authData['studentId'])
                  .get(),
              builder: (context, studentSnapshot) {
                if (!studentSnapshot.hasData) {
                  return const SizedBox();
                }

                final studentData = studentSnapshot.data?.data() as Map<String, dynamic>?;
                if (studentData == null) return const SizedBox();

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.school, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Student: ${studentData['name']} (${studentData['grade']})',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Permissions
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildPermissionChip('View Attendance', authData['permissions']?['viewAttendance'] ?? false),
                _buildPermissionChip('View Grades', authData['permissions']?['viewGrades'] ?? false),
                _buildPermissionChip('Pickup Student', authData['permissions']?['pickupStudent'] ?? false),
                _buildPermissionChip('Emergency Contact', authData['permissions']?['emergencyContact'] ?? false),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Permissions'),
                    onPressed: () => _editPermissions(authId, authData),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Revoke Access'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _revokeAuthorization(authId, authData),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('guardian_authorizations')
          .where('primaryGuardianId', isEqualTo: currentUser?.uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inbox,
            title: 'No Pending Requests',
            subtitle: 'All authorization requests have been handled',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final requestData = request.data() as Map<String, dynamic>;
            return _buildRequestCard(request.id, requestData);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(String requestId, Map<String, dynamic> requestData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
            // Request Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.orange,
                  child: Text(
                    _getInitials(requestData['guardianName'] ?? ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
                        requestData['guardianName'] ?? 'Unknown Guardian',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        requestData['guardianPhone'] ?? '',
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
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Request Message
            if (requestData['message'] != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.message, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        requestData['message'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Student Info
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('students')
                  .doc(requestData['studentId'])
                  .get(),
              builder: (context, studentSnapshot) {
                if (!studentSnapshot.hasData) {
                  return const SizedBox();
                }

                final studentData = studentSnapshot.data?.data() as Map<String, dynamic>?;
                if (studentData == null) return const SizedBox();

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.school, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'For: ${studentData['name']} (${studentData['grade']})',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () => _handleRequest(requestId, 'declined'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showPermissionSelectionDialog(requestId, requestData),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionChip(String label, bool granted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: granted ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: granted ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: granted ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Color _getGradeColor(String? grade) {
    if (grade == null) return Colors.grey;
    final gradeNum = int.tryParse(grade.substring(0, 1)) ?? 0;
    switch (gradeNum) {
      case 1: return Colors.purple;
      case 2: return Colors.blue;
      case 3: return Colors.green;
      case 4: return Colors.orange;
      default: return Colors.deepPurple;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'declined': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'approved': return 'APPROVED';
      case 'pending': return 'PENDING';
      case 'declined': return 'DECLINED';
      default: return 'UNKNOWN';
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'G';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}';
    }
    return name[0];
  }

  // Action Methods
  void _showStudentGuardians(String studentId, Map<String, dynamic> studentData) {
    showDialog(
      context: context,
      builder: (context) => _StudentGuardiansDialog(
        studentId: studentId,
        studentData: studentData,
      ),
    );
  }

  void _showAddGuardianDialog(String studentId, Map<String, dynamic> studentData) {
    showDialog(
      context: context,
      builder: (context) => _AddGuardianDialog(
        studentId: studentId,
        studentData: studentData,
      ),
    );
  }

  void _editPermissions(String authId, Map<String, dynamic> authData) {
    showDialog(
      context: context,
      builder: (context) => _EditPermissionsDialog(
        authId: authId,
        authData: authData,
      ),
    );
  }

  void _revokeAuthorization(String authId, Map<String, dynamic> authData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Authorization'),
        content: Text(
          'Are you sure you want to revoke access for ${authData['guardianName']}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('guardian_authorizations')
                    .doc(authId)
                    .update({
                  'status': 'revoked',
                  'revokedAt': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Authorization revoked successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  void _handleRequest(String requestId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('guardian_authorizations')
          .doc(requestId)
          .update({
        'status': status,
        'processedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request ${status} successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showPermissionSelectionDialog(String requestId, Map<String, dynamic> requestData) {
    showDialog(
      context: context,
      builder: (context) => _PermissionSelectionDialog(
        requestId: requestId,
        requestData: requestData,
      ),
    );
  }
}

// Dialog Classes
class _StudentGuardiansDialog extends StatelessWidget {
  final String studentId;
  final Map<String, dynamic> studentData;

  const _StudentGuardiansDialog({
    required this.studentId,
    required this.studentData,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          children: [
            // Header
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
                      '${studentData['name']} - Guardians',
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
            
            // Primary Guardian
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Primary Guardian',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final userData = snapshot.data?.data() as Map<String, dynamic>?;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: const Icon(Icons.star, color: Colors.white),
                        ),
                        title: Text(userData?['fullName'] ?? 'You'),
                        subtitle: Text(userData?['phoneNumber'] ?? ''),
                        trailing: const Chip(
                          label: Text('Primary'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Authorized Guardians
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Authorized Guardians',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('guardian_authorizations')
                          .where('studentId', isEqualTo: studentId)
                          .where('status', isEqualTo: 'approved')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final guardians = snapshot.data!.docs;
                        
                        if (guardians.isEmpty) {
                          return const Center(
                            child: Text('No authorized guardians'),
                          );
                        }
                        
                        return ListView.builder(
                          itemCount: guardians.length,
                          itemBuilder: (context, index) {
                            final guardian = guardians[index];
                            final guardianData = guardian.data() as Map<String, dynamic>;
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  _getInitials(guardianData['guardianName'] ?? ''),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(guardianData['guardianName'] ?? ''),
                              subtitle: Text(guardianData['guardianPhone'] ?? ''),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () {
                                  // Show guardian options
                                },
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
          ],
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
}

class _AddGuardianDialog extends StatefulWidget {
  final String studentId;
  final Map<String, dynamic> studentData;

  const _AddGuardianDialog({
    required this.studentId,
    required this.studentData,
  });

  @override
  State<_AddGuardianDialog> createState() => _AddGuardianDialogState();
}

class _AddGuardianDialogState extends State<_AddGuardianDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  // Permissions
  bool _viewAttendance = true;
  bool _viewGrades = true;
  bool _pickupStudent = false;
  bool _emergencyContact = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 700),
        child: Column(
          children: [
            // Header
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
                  const Expanded(
                    child: Text(
                      'Add Guardian',
                      style: TextStyle(
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
            
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.school, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'For: ${widget.studentData['name']} (${widget.studentData['grade']})',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Guardian Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Guardian Name *',
                          hintText: 'Enter guardian full name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter guardian name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Phone Number
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          hintText: '+966XXXXXXXXX',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (!value.startsWith('+966')) {
                            return 'Please enter a valid Saudi phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Message
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Message (Optional)',
                          hintText: 'Add a personal message',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // Permissions
                      const Text(
                        'Permissions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      SwitchListTile(
                        title: const Text('View Attendance'),
                        subtitle: const Text('Allow viewing attendance records'),
                        value: _viewAttendance,
                        onChanged: (value) => setState(() => _viewAttendance = value),
                      ),
                      SwitchListTile(
                        title: const Text('View Grades'),
                        subtitle: const Text('Allow viewing grades and reports'),
                        value: _viewGrades,
                        onChanged: (value) => setState(() => _viewGrades = value),
                      ),
                      SwitchListTile(
                        title: const Text('Pickup Student'),
                        subtitle: const Text('Allow picking up student from school'),
                        value: _pickupStudent,
                        onChanged: (value) => setState(() => _pickupStudent = value),
                      ),
                      SwitchListTile(
                        title: const Text('Emergency Contact'),
                        subtitle: const Text('Receive emergency notifications'),
                        value: _emergencyContact,
                        onChanged: (value) => setState(() => _emergencyContact = value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendAuthorization,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Send Request'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendAuthorization() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create authorization request
      await FirebaseFirestore.instance
          .collection('guardian_authorizations')
          .add({
        'studentId': widget.studentId,
        'primaryGuardianId': FirebaseAuth.instance.currentUser?.uid,
        'guardianName': _nameController.text.trim(),
        'guardianPhone': _phoneController.text.trim(),
        'message': _messageController.text.trim(),
        'permissions': {
          'viewAttendance': _viewAttendance,
          'viewGrades': _viewGrades,
          'pickupStudent': _pickupStudent,
          'emergencyContact': _emergencyContact,
        },
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authorization request sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _EditPermissionsDialog extends StatefulWidget {
  final String authId;
  final Map<String, dynamic> authData;

  const _EditPermissionsDialog({
    required this.authId,
    required this.authData,
  });

  @override
  State<_EditPermissionsDialog> createState() => _EditPermissionsDialogState();
}

class _EditPermissionsDialogState extends State<_EditPermissionsDialog> {
  bool _isLoading = false;
  late bool _viewAttendance;
  late bool _viewGrades;
  late bool _pickupStudent;
  late bool _emergencyContact;

  @override
  void initState() {
    super.initState();
    final permissions = widget.authData['permissions'] as Map<String, dynamic>? ?? {};
    _viewAttendance = permissions['viewAttendance'] ?? false;
    _viewGrades = permissions['viewGrades'] ?? false;
    _pickupStudent = permissions['pickupStudent'] ?? false;
    _emergencyContact = permissions['emergencyContact'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Permissions - ${widget.authData['guardianName']}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('View Attendance'),
            value: _viewAttendance,
            onChanged: (value) => setState(() => _viewAttendance = value),
          ),
          SwitchListTile(
            title: const Text('View Grades'),
            value: _viewGrades,
            onChanged: (value) => setState(() => _viewGrades = value),
          ),
          SwitchListTile(
            title: const Text('Pickup Student'),
            value: _pickupStudent,
            onChanged: (value) => setState(() => _pickupStudent = value),
          ),
          SwitchListTile(
            title: const Text('Emergency Contact'),
            value: _emergencyContact,
            onChanged: (value) => setState(() => _emergencyContact = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updatePermissions,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _updatePermissions() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('guardian_authorizations')
          .doc(widget.authId)
          .update({
        'permissions': {
          'viewAttendance': _viewAttendance,
          'viewGrades': _viewGrades,
          'pickupStudent': _pickupStudent,
          'emergencyContact': _emergencyContact,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _PermissionSelectionDialog extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const _PermissionSelectionDialog({
    required this.requestId,
    required this.requestData,
  });

  @override
  State<_PermissionSelectionDialog> createState() => _PermissionSelectionDialogState();
}

class _PermissionSelectionDialogState extends State<_PermissionSelectionDialog> {
  bool _isLoading = false;
  bool _viewAttendance = true;
  bool _viewGrades = true;
  bool _pickupStudent = false;
  bool _emergencyContact = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Approve Request - ${widget.requestData['guardianName']}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select permissions to grant:'),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('View Attendance'),
            value: _viewAttendance,
            onChanged: (value) => setState(() => _viewAttendance = value),
          ),
          SwitchListTile(
            title: const Text('View Grades'),
            value: _viewGrades,
            onChanged: (value) => setState(() => _viewGrades = value),
          ),
          SwitchListTile(
            title: const Text('Pickup Student'),
            value: _pickupStudent,
            onChanged: (value) => setState(() => _pickupStudent = value),
          ),
          SwitchListTile(
            title: const Text('Emergency Contact'),
            value: _emergencyContact,
            onChanged: (value) => setState(() => _emergencyContact = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _approveWithPermissions,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Approve'),
        ),
      ],
    );
  }

  Future<void> _approveWithPermissions() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('guardian_authorizations')
          .doc(widget.requestId)
          .update({
        'status': 'approved',
        'permissions': {
          'viewAttendance': _viewAttendance,
          'viewGrades': _viewGrades,
          'pickupStudent': _pickupStudent,
          'emergencyContact': _emergencyContact,
        },
        'approvedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
