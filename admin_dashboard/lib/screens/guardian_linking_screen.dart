import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class GuardianLinkingScreen extends StatefulWidget {
  const GuardianLinkingScreen({super.key});

  @override
  State<GuardianLinkingScreen> createState() => _GuardianLinkingScreenState();
}

class _GuardianLinkingScreenState extends State<GuardianLinkingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';

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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.guardianLinking,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search students or guardians...',
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
          const SizedBox(height: 24),

          // Students with Guardian Status
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('students').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var students = snapshot.data!.docs.where((doc) {
                  final student = doc.data() as Map<String, dynamic>;
                  final name = (student['name'] ?? '').toString().toLowerCase();
                  final phone = (student['guardianPhone'] ?? '').toString().toLowerCase();
                  
                  return _searchQuery.isEmpty || 
                      name.contains(_searchQuery) ||
                      phone.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final doc = students[index];
                    final student = doc.data() as Map<String, dynamic>;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: Text(
                            (student['name'] ?? '?').toString().substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          student['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Grade: ${student['grade'] ?? 'N/A'} | Phone: ${student['guardianPhone'] ?? 'N/A'}',
                        ),
                        trailing: _buildGuardianStatus(student),
                        children: [
                          _buildGuardianDetails(doc.id, student),
                        ],
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

  Widget _buildGuardianStatus(Map<String, dynamic> student) {
    final hasGuardian = student['primaryGuardianId'] != null;
    final authorizedCount = (student['authorizedGuardianIds'] as List?)?.length ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
              color: hasGuardian ? AppTheme.successColor : AppTheme.warningColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        if (authorizedCount > 0)
          Text(
            '+$authorizedCount auth',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildGuardianDetails(String studentId, Map<String, dynamic> student) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Guardian
          _buildPrimaryGuardianSection(studentId, student),
          
          const Divider(height: 24),
          
          // Authorized Guardians
          _buildAuthorizedGuardiansSection(studentId, student),
        ],
      ),
    );
  }

  Widget _buildPrimaryGuardianSection(String studentId, Map<String, dynamic> student) {
    final primaryGuardianId = student['primaryGuardianId'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Primary Guardian',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (primaryGuardianId == null)
              ElevatedButton.icon(
                onPressed: () => _showLinkGuardianDialog(studentId, student),
                icon: const Icon(Icons.link, size: 16),
                label: const Text('Link Guardian'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (primaryGuardianId != null)
          FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(primaryGuardianId).get(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                final guardian = snapshot.data!.data() as Map<String, dynamic>;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.successColor.withOpacity(0.2),
                        child: Text(
                          (guardian['name'] ?? '?').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.successColor,
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
                              guardian['name'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              guardian['phone'] ?? guardian['email'] ?? 'No contact',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _unlinkPrimaryGuardian(studentId),
                        icon: const Icon(Icons.link_off, color: Colors.red),
                        tooltip: 'Unlink Guardian',
                      ),
                    ],
                  ),
                );
              }
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Guardian not found'),
              );
            },
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: AppTheme.warningColor),
                SizedBox(width: 8),
                Text('No primary guardian linked'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAuthorizedGuardiansSection(String studentId, Map<String, dynamic> student) {
    final authorizedIds = List<String>.from(student['authorizedGuardianIds'] ?? []);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people_outline, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Authorized Guardians',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => _showAddAuthorizedGuardianDialog(studentId, student),
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Add Guardian'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (authorizedIds.isNotEmpty)
          ...authorizedIds.map((guardianId) => 
            FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(guardianId).get(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final guardian = snapshot.data!.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                          child: Text(
                            (guardian['name'] ?? '?').substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                guardian['name'] ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              Text(
                                guardian['phone'] ?? guardian['email'] ?? 'No contact',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeAuthorizedGuardian(studentId, guardianId),
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                          tooltip: 'Remove Guardian',
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ).toList()
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey),
                SizedBox(width: 8),
                Text('No authorized guardians', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
      ],
    );
  }

  void _showLinkGuardianDialog(String studentId, Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link Primary Guardian'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').where('role', isEqualTo: 'guardian').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final guardians = snapshot.data!.docs;
              
              return ListView.builder(
                itemCount: guardians.length,
                itemBuilder: (context, index) {
                  final guardian = guardians[index].data() as Map<String, dynamic>;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text((guardian['name'] ?? '?').substring(0, 1).toUpperCase()),
                    ),
                    title: Text(guardian['name'] ?? 'Unknown'),
                    subtitle: Text(guardian['phone'] ?? guardian['email'] ?? 'No contact'),
                    onTap: () async {
                      await _linkPrimaryGuardian(studentId, guardians[index].id);
                      if (mounted) Navigator.of(context).pop();
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddAuthorizedGuardianDialog(String studentId, Map<String, dynamic> student) {
    final currentAuthorized = List<String>.from(student['authorizedGuardianIds'] ?? []);
    final primaryGuardianId = student['primaryGuardianId'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Authorized Guardian'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').where('role', isEqualTo: 'guardian').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final guardians = snapshot.data!.docs.where((doc) => 
                doc.id != primaryGuardianId && !currentAuthorized.contains(doc.id)
              ).toList();
              
              return ListView.builder(
                itemCount: guardians.length,
                itemBuilder: (context, index) {
                  final guardian = guardians[index].data() as Map<String, dynamic>;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text((guardian['name'] ?? '?').substring(0, 1).toUpperCase()),
                    ),
                    title: Text(guardian['name'] ?? 'Unknown'),
                    subtitle: Text(guardian['phone'] ?? guardian['email'] ?? 'No contact'),
                    onTap: () async {
                      await _addAuthorizedGuardian(studentId, guardians[index].id);
                      if (mounted) Navigator.of(context).pop();
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _linkPrimaryGuardian(String studentId, String guardianId) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'primaryGuardianId': guardianId,
        'status': 'linked',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primary guardian linked successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error linking guardian: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unlinkPrimaryGuardian(String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'primaryGuardianId': null,
        'status': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primary guardian unlinked'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error unlinking guardian: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addAuthorizedGuardian(String studentId, String guardianId) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'authorizedGuardianIds': FieldValue.arrayUnion([guardianId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authorized guardian added successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding guardian: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeAuthorizedGuardian(String studentId, String guardianId) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'authorizedGuardianIds': FieldValue.arrayRemove([guardianId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authorized guardian removed'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing guardian: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
