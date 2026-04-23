import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class AnnouncementManagementScreen extends StatefulWidget {
  const AnnouncementManagementScreen({super.key});

  @override
  State<AnnouncementManagementScreen> createState() => _AnnouncementManagementScreenState();
}

class _AnnouncementManagementScreenState extends State<AnnouncementManagementScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedPriority = 'normal';
  String _selectedRecipientType = 'all';
  List<String> _selectedGrades = [];
  List<String> _availableGrades = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGrades();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGrades() async {
    try {
      final gradesSnapshot = await _firestore.collection('grades').get();
      setState(() {
        _availableGrades = gradesSnapshot.docs
            .map((doc) {
              final data = doc.data();
              final name = data['name'] as String?;
              final id = doc.id;
              
              if (name != null && name.isNotEmpty) {
                return name;
              } else if (_isValidGradeName(id)) {
                return id;
              } else {
                return null;
              }
            })
            .where((grade) => grade != null)
            .cast<String>()
            .toSet()
            .toList()
          ..sort(_compareGrades);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading grades: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  bool _isValidGradeName(String grade) {
    if (grade.length > 20) return false;
    if (grade.contains('-') && grade.length > 10) return false;
    if (RegExp(r'^[a-f0-9]{20,}$').hasMatch(grade)) return false;
    
    if (RegExp(r'^(Grade\s?)?[0-9]{1,2}[A-Z]?$', caseSensitive: false).hasMatch(grade)) return true;
    if (RegExp(r'^[0-9]{1,2}(st|nd|rd|th)?\s?(Grade)?$', caseSensitive: false).hasMatch(grade)) return true;
    if (RegExp(r'^(KG|Kindergarten|Pre-?K)$', caseSensitive: false).hasMatch(grade)) return true;
    
    return false;
  }

  int _compareGrades(String a, String b) {
    final aNum = RegExp(r'(\d+)').firstMatch(a.toLowerCase());
    final bNum = RegExp(r'(\d+)').firstMatch(b.toLowerCase());
    
    if (aNum != null && bNum != null) {
      final aInt = int.tryParse(aNum.group(1)!) ?? 0;
      final bInt = int.tryParse(bNum.group(1)!) ?? 0;
      if (aInt != bInt) return aInt.compareTo(bInt);
    }
    
    return a.compareTo(b);
  }

  @override
  Widget build(BuildContext context) {
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
                      child: Icon(
                        Icons.campaign,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Announcement Management',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Create and manage school announcements',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action Buttons
              ElevatedButton.icon(
                onPressed: _showCreateAnnouncementDialog,
                icon: const Icon(Icons.add),
                label: const Text('New Announcement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search Bar
          Card(
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search announcements...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark 
                      ? AppTheme.cardColor 
                      : const Color(0xFFF8FAFC),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.black.withOpacity(0.3)
                      : AppTheme.textMuted.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(text: 'All Announcements'),
                Tab(text: 'Draft Announcements'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAnnouncementsTab(false), // Published announcements
                _buildAnnouncementsTab(true),  // Draft announcements
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsTab(bool isDraft) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('notifications')
          .where('type', isEqualTo: 'announcement')
          .where('isDraft', isEqualTo: isDraft)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final announcements = snapshot.data?.docs ?? [];
        final filteredAnnouncements = announcements.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          final message = (data['message'] ?? '').toString().toLowerCase();
          
          return title.contains(_searchQuery) || 
                 message.contains(_searchQuery) || 
                 _searchQuery.isEmpty;
        }).toList();

        if (filteredAnnouncements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isDraft ? Icons.drafts_outlined : Icons.campaign_outlined,
                  size: 64,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  isDraft ? 'No draft announcements' : 'No announcements found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isDraft ? 'Draft announcements will appear here' : 'Try adjusting your search',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return Card(
          color: Theme.of(context).cardColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredAnnouncements.length,
            itemBuilder: (context, index) {
              final announcement = filteredAnnouncements[index];
              final data = announcement.data() as Map<String, dynamic>;
              
              return _buildAnnouncementCard(announcement.id, data, isDraft);
            },
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementCard(String id, Map<String, dynamic> data, bool isDraft) {
    final title = data['title'] ?? 'Untitled Announcement';
    final message = data['message'] ?? '';
    final priority = data['priority'] ?? 'normal';
    final timestamp = data['timestamp'] as Timestamp?;
    final recipientType = data['recipientType'] ?? 'all';
    final targetGrades = List<String>.from(data['targetGrades'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF374151) 
              : const Color(0xFFD1D5DB)
        ),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).cardColor,
      ),
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getPriorityColor(priority).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getPriorityIcon(priority),
            color: _getPriorityColor(priority),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message.length > 100 ? '${message.substring(0, 100)}...' : message,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(priority, isDraft),
                const SizedBox(width: 8),
                _buildRecipientChip(recipientType, targetGrades),
                const Spacer(),
                if (timestamp != null)
                  Text(
                    DateFormat('MMM dd, HH:mm').format(timestamp.toDate()),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full Message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.cardColor 
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  children: [
                    if (isDraft) ...[
                      ElevatedButton.icon(
                        onPressed: () => _publishAnnouncement(id, data),
                        icon: const Icon(Icons.publish, size: 16),
                        label: const Text('Publish'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _editAnnouncement(id, data),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: () => _duplicateAnnouncement(data),
                        icon: const Icon(Icons.content_copy, size: 16),
                        label: const Text('Duplicate'),
                      ),
                    ],
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _deleteAnnouncement(id),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String priority, bool isDraft) {
    final color = isDraft ? AppTheme.warningColor : _getPriorityColor(priority);
    final text = isDraft ? 'DRAFT' : priority.toUpperCase();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRecipientChip(String recipientType, List<String> targetGrades) {
    String text;
    Color color = AppTheme.infoColor;
    
    switch (recipientType) {
      case 'grade':
        text = 'Grade: ${targetGrades.join(', ')}';
        break;
      case 'all':
        text = 'All Parents';
        break;
      default:
        text = recipientType.toUpperCase();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'low':
        return AppTheme.infoColor;
      default:
        return AppTheme.successColor;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.warning;
      case 'low':
        return Icons.info;
      default:
        return Icons.campaign;
    }
  }

  void _showCreateAnnouncementDialog() {
    _clearForm();
    showDialog(
      context: context,
      builder: (context) => _buildAnnouncementDialog(),
    );
  }

  void _editAnnouncement(String id, Map<String, dynamic> data) {
    _titleController.text = data['title'] ?? '';
    _messageController.text = data['message'] ?? '';
    _selectedPriority = data['priority'] ?? 'normal';
    _selectedRecipientType = data['recipientType'] ?? 'all';
    _selectedGrades = List<String>.from(data['targetGrades'] ?? []);
    
    showDialog(
      context: context,
      builder: (context) => _buildAnnouncementDialog(editId: id),
    );
  }

  void _duplicateAnnouncement(Map<String, dynamic> data) {
    _titleController.text = '${data['title'] ?? ''} (Copy)';
    _messageController.text = data['message'] ?? '';
    _selectedPriority = data['priority'] ?? 'normal';
    _selectedRecipientType = data['recipientType'] ?? 'all';
    _selectedGrades = List<String>.from(data['targetGrades'] ?? []);
    
    showDialog(
      context: context,
      builder: (context) => _buildAnnouncementDialog(),
    );
  }

  Widget _buildAnnouncementDialog({String? editId}) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(editId != null ? 'Edit Announcement' : 'Create Announcement'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Field
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter announcement title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Message Field
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      hintText: 'Enter announcement message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Priority Selection
                  DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low Priority')),
                      DropdownMenuItem(value: 'normal', child: Text('Normal Priority')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium Priority')),
                      DropdownMenuItem(value: 'high', child: Text('High Priority')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedPriority = value ?? 'normal';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Recipient Type Selection
                  DropdownButtonFormField<String>(
                    value: _selectedRecipientType,
                    decoration: const InputDecoration(
                      labelText: 'Send To',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Parents')),
                      DropdownMenuItem(value: 'grade', child: Text('Specific Grades')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedRecipientType = value ?? 'all';
                        if (value != 'grade') {
                          _selectedGrades.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Grade Selection (if recipient type is 'grade')
                  if (_selectedRecipientType == 'grade') ...[
                    const Text('Select Grades:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableGrades.map((grade) {
                        final isSelected = _selectedGrades.contains(grade);
                        return FilterChip(
                          label: Text(grade),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                _selectedGrades.add(grade);
                              } else {
                                _selectedGrades.remove(grade);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveAnnouncement(editId, true), // Save as draft
              child: const Text('Save Draft'),
            ),
            ElevatedButton(
              onPressed: () => _saveAnnouncement(editId, false), // Publish
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Publish'),
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    _titleController.clear();
    _messageController.clear();
    _selectedPriority = 'normal';
    _selectedRecipientType = 'all';
    _selectedGrades.clear();
  }

  Future<void> _saveAnnouncement(String? editId, bool isDraft) async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_selectedRecipientType == 'grade' && _selectedGrades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one grade'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    try {
      final announcementData = {
        'type': 'announcement',
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'priority': _selectedPriority,
        'recipientType': _selectedRecipientType,
        'targetGrades': _selectedGrades,
        'isDraft': isDraft,
        'timestamp': FieldValue.serverTimestamp(),
        'createdBy': 'admin', // You can get actual admin info here
      };

      if (editId != null) {
        await _firestore.collection('notifications').doc(editId).update(announcementData);
      } else {
        await _firestore.collection('notifications').add(announcementData);
      }

      // If publishing (not draft), send individual notifications to users
      if (!isDraft) {
        await _sendNotificationsToUsers(announcementData);
      }

      Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editId != null 
                  ? 'Announcement updated successfully'
                  : isDraft 
                      ? 'Announcement saved as draft'
                      : 'Announcement published and sent to recipients'
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving announcement: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _sendNotificationsToUsers(Map<String, dynamic> announcementData) async {
    try {
      List<String> recipientIds = [];

      if (announcementData['recipientType'] == 'all') {
        // Get all guardian users (not 'parent' role)
        final usersSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'guardian')
            .get();
        
        recipientIds = usersSnapshot.docs.map((doc) => doc.id).toList();
      } else if (announcementData['recipientType'] == 'grade') {
        // Since students don't have parentId, we'll send to all guardians for now
        // In a proper implementation, you'd need to establish the parent-student relationship
        final usersSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'guardian')
            .get();
        
        recipientIds = usersSnapshot.docs.map((doc) => doc.id).toList();
        
        // TODO: Implement proper parent-student linking in the future
        // For now, all guardians will receive grade-specific announcements
      }

      if (recipientIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No guardian users found to send notifications to'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
        return;
      }

      // Create individual notification documents for each recipient
      final batch = _firestore.batch();
      final timestamp = FieldValue.serverTimestamp();

      for (String recipientId in recipientIds) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'recipientId': recipientId,
          'type': 'announcement',
          'title': announcementData['title'],
          'message': announcementData['message'],
          'priority': announcementData['priority'],
          'timestamp': timestamp,
          'read': false,
          'data': {
            'announcementType': 'school_announcement',
            'recipientType': announcementData['recipientType'],
            'targetGrades': announcementData['targetGrades'],
          },
        });
      }

      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notifications sent to ${recipientIds.length} guardians'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending notifications: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      throw e;
    }
  }

  Future<void> _publishAnnouncement(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('notifications').doc(id).update({
        'isDraft': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Send notifications to users
      final updatedData = Map<String, dynamic>.from(data);
      updatedData['isDraft'] = false;
      await _sendNotificationsToUsers(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement published and sent to recipients'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error publishing announcement: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('notifications').doc(id).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting announcement: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }
}
