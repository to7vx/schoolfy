import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../theme/app_theme.dart';
import 'bus_details_screen.dart';

class BusManagementScreen extends StatefulWidget {
  const BusManagementScreen({super.key});

  @override
  State<BusManagementScreen> createState() => _BusManagementScreenState();
}

class _BusManagementScreenState extends State<BusManagementScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _busNumberController = TextEditingController();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _driverPhoneController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  List<String> _selectedStudents = [];
  Timer? _autoRouteTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startAutoRouteTimer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _busNumberController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _capacityController.dispose();
    _notesController.dispose();
    _tabController.dispose();
    _autoRouteTimer?.cancel();
    super.dispose();
  }

  void _startAutoRouteTimer() {
    // Check every 5 minutes for buses that should auto-end their routes
    _autoRouteTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkAndUpdateExpiredRoutes();
    });
  }

  Future<void> _checkAndUpdateExpiredRoutes() async {
    try {
      final now = Timestamp.now();
      final expiredBuses = await _firestore
          .collection('buses')
          .where('routeStatus', isEqualTo: 'on_route')
          .where('autoEndRouteAt', isLessThanOrEqualTo: now)
          .get();

      for (var doc in expiredBuses.docs) {
        await doc.reference.update({
          'routeStatus': 'idle',
          'autoEndRouteAt': FieldValue.delete(),
          'routeStatusUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error checking expired routes: $e');
    }
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
                        Icons.directions_bus,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bus Management',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Manage school buses and student assignments',
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
                onPressed: _showAddBusDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add New Bus'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search and Filter Bar
          Card(
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Search Field
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by bus number, driver name, or student...',
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
                  const SizedBox(width: 16),
                  // Filter Dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedFilter,
                      decoration: InputDecoration(
                        labelText: 'Filter by Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark 
                            ? AppTheme.cardColor 
                            : const Color(0xFFF8FAFC),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Buses')),
                        DropdownMenuItem(value: 'available', child: Text('Available Capacity')),
                        DropdownMenuItem(value: 'full', child: Text('Full Capacity')),
                        DropdownMenuItem(value: 'active', child: Text('Active Only')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value ?? 'all';
                        });
                      },
                    ),
                  ),
                ],
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
                Tab(text: 'All Buses'),
                Tab(text: 'Student Assignments'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBusesTab(),
                _buildStudentAssignmentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('buses')
          .orderBy('busNumber')
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

        final buses = snapshot.data?.docs ?? [];
        final filteredBuses = buses.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final busNumber = (data['busNumber'] ?? '').toString().toLowerCase();
          final driverName = (data['driverName'] ?? '').toString().toLowerCase();
          final assignedStudents = List<String>.from(data['assignedStudents'] ?? []);
          final capacity = data['capacity'] ?? 0;
          final isActive = data['active'] ?? true;
          
          // Search filter
          final matchesSearch = _searchQuery.isEmpty ||
              busNumber.contains(_searchQuery) ||
              driverName.contains(_searchQuery);
          
          // Status filter
          bool matchesFilter = true;
          switch (_selectedFilter) {
            case 'available':
              matchesFilter = assignedStudents.length < capacity;
              break;
            case 'full':
              matchesFilter = assignedStudents.length >= capacity;
              break;
            case 'active':
              matchesFilter = isActive;
              break;
            default:
              matchesFilter = true;
          }
          
          return matchesSearch && matchesFilter;
        }).toList();

        if (filteredBuses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_bus_outlined,
                  size: 64,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'No buses found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search or add a new bus',
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
            itemCount: filteredBuses.length,
            itemBuilder: (context, index) {
              final bus = filteredBuses[index];
              final data = bus.data() as Map<String, dynamic>;
              
              return _buildBusCardWithStudentCount(bus.id, data);
            },
          ),
        );
      },
    );
  }

  Widget _buildBusCardWithStudentCount(String busId, Map<String, dynamic> data) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('students').where('busId', isEqualTo: busId).snapshots(),
      builder: (context, studentSnapshot) {
        final assignedStudentCount = studentSnapshot.hasData ? studentSnapshot.data!.docs.length : 0;
        
        // Update the data with real student count for display
        final updatedData = Map<String, dynamic>.from(data);
        updatedData['assignedStudents'] = List.generate(assignedStudentCount, (index) => 'student_$index');
        
        return _buildBusCard(busId, updatedData);
      },
    );
  }

  Widget _buildBusCard(String busId, Map<String, dynamic> data) {
    final busNumber = data['busNumber'] ?? 'Unknown';
    final driverName = data['driverName'] ?? 'Unknown Driver';
    final driverPhone = data['driverPhone'] ?? '';
    final capacity = data['capacity'] ?? 0;
    final assignedStudents = List<String>.from(data['assignedStudents'] ?? []);
    final notes = data['notes'] ?? '';
    final isActive = data['active'] ?? true;
    final createdAt = data['createdAt'] as Timestamp?;

    final utilizationPercentage = capacity > 0 ? (assignedStudents.length / capacity * 100) : 0;
    final statusColor = isActive 
        ? (assignedStudents.length >= capacity ? AppTheme.errorColor : AppTheme.successColor)
        : AppTheme.textMuted;

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
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.directions_bus,
            color: statusColor,
            size: 24,
          ),
        ),
        title: Text(
          'Bus $busNumber',
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
              'Driver: $driverName',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(isActive),
                const SizedBox(width: 8),
                _buildRouteStatusChip(data['routeStatus'] ?? 'idle'),
                const SizedBox(width: 8),
                _buildCapacityChip(assignedStudents.length, capacity),
                const Spacer(),
                if (createdAt != null)
                  Text(
                    DateFormat('MMM dd, yyyy').format(createdAt.toDate()),
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
                // Bus Details
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.cardColor 
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Phone:', driverPhone),
                      _buildDetailRow('Capacity:', '$capacity students'),
                      _buildDetailRow('Assigned:', '${assignedStudents.length} students'),
                      _buildDetailRow('Utilization:', '${utilizationPercentage.toStringAsFixed(1)}%'),
                      if (notes.isNotEmpty) _buildDetailRow('Notes:', notes),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Actions
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _navigateToBusDetails(busId),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                    _buildRouteStatusButton(busId, data),
                    OutlinedButton.icon(
                      onPressed: () => _showEditBusDialog(busId, data),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showAssignStudentsDialog(busId, data),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Assign Students'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _deleteBus(busId),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    final color = isActive ? AppTheme.successColor : AppTheme.textMuted;
    final text = isActive ? 'ACTIVE' : 'INACTIVE';
    
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

  Widget _buildCapacityChip(int assigned, int capacity) {
    final isFull = assigned >= capacity;
    final color = isFull ? AppTheme.errorColor : AppTheme.infoColor;
    final text = '$assigned/$capacity';
    
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

  Widget _buildRouteStatusChip(String routeStatus) {
    final isOnRoute = routeStatus == 'on_route';
    final color = isOnRoute ? AppTheme.warningColor : AppTheme.textMuted;
    final text = isOnRoute ? 'ON ROUTE' : 'IDLE';
    final icon = isOnRoute ? Icons.directions_bus : Icons.pause;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentAssignmentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('students')
          .orderBy('name')
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

        final students = snapshot.data?.docs ?? [];
        final filteredStudents = students.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final grade = (data['grade'] ?? '').toString().toLowerCase();
          
          return _searchQuery.isEmpty ||
              name.contains(_searchQuery) ||
              grade.contains(_searchQuery);
        }).toList();

        if (filteredStudents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'No students found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
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
            itemCount: filteredStudents.length,
            itemBuilder: (context, index) {
              final student = filteredStudents[index];
              final data = student.data() as Map<String, dynamic>;
              
              return _buildStudentAssignmentCard(student.id, data);
            },
          ),
        );
      },
    );
  }

  Widget _buildStudentAssignmentCard(String studentId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown Student';
    final grade = data['grade'] ?? 'Unknown Grade';
    final busId = data['busId'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF374151) 
              : const Color(0xFFD1D5DB)
        ),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).cardColor,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.person,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('Grade: $grade'),
        trailing: busId != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('buses').doc(busId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final busData = snapshot.data!.data() as Map<String, dynamic>;
                        return Chip(
                          label: Text('Bus ${busData['busNumber']}'),
                          backgroundColor: AppTheme.successColor.withOpacity(0.1),
                        );
                      }
                      return const Chip(
                        label: Text('Unknown Bus'),
                        backgroundColor: AppTheme.errorColor,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') {
                        _showStudentBusAssignmentDialog(studentId, data);
                      } else if (action == 'unassign') {
                        _unassignStudentFromBus(studentId, data);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Change Bus'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'unassign',
                        child: Row(
                          children: [
                            Icon(Icons.remove_circle, size: 18, color: AppTheme.errorColor),
                            SizedBox(width: 8),
                            Text('Unassign'),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              )
            : OutlinedButton(
                onPressed: () => _showStudentBusAssignmentDialog(studentId, data),
                child: const Text('Assign Bus'),
              ),
      ),
    );
  }

  void _showAddBusDialog() {
    _clearForm();
    showDialog(
      context: context,
      builder: (context) => _buildBusDialog(),
    );
  }

  void _showEditBusDialog(String busId, Map<String, dynamic> data) {
    _busNumberController.text = data['busNumber'] ?? '';
    _driverNameController.text = data['driverName'] ?? '';
    _driverPhoneController.text = data['driverPhone'] ?? '';
    _capacityController.text = (data['capacity'] ?? 0).toString();
    _notesController.text = data['notes'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => _buildBusDialog(editId: busId),
    );
  }

  Widget _buildBusDialog({String? editId}) {
    return AlertDialog(
      title: Text(editId != null ? 'Edit Bus' : 'Add New Bus'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _busNumberController,
                decoration: const InputDecoration(
                  labelText: 'Bus Number *',
                  hintText: 'e.g., 10A, B-01',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _driverNameController,
                decoration: const InputDecoration(
                  labelText: 'Driver Name *',
                  hintText: 'Enter driver full name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _driverPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Driver Phone *',
                  hintText: '+966XXXXXXXXX',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity *',
                  hintText: 'Maximum number of students',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Additional information about the bus',
                  border: OutlineInputBorder(),
                ),
              ),
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
          onPressed: () => _saveBus(editId),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text(editId != null ? 'Update' : 'Add Bus'),
        ),
      ],
    );
  }

  void _clearForm() {
    _busNumberController.clear();
    _driverNameController.clear();
    _driverPhoneController.clear();
    _capacityController.clear();
    _notesController.clear();
    _selectedStudents.clear();
  }

  Future<void> _saveBus(String? editId) async {
    if (_busNumberController.text.trim().isEmpty || 
        _driverNameController.text.trim().isEmpty ||
        _driverPhoneController.text.trim().isEmpty ||
        _capacityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final capacity = int.tryParse(_capacityController.text);
    if (capacity == null || capacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid capacity'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    try {
      final busData = {
        'busNumber': _busNumberController.text.trim(),
        'driverName': _driverNameController.text.trim(),
        'driverPhone': _driverPhoneController.text.trim(),
        'capacity': capacity,
        'notes': _notesController.text.trim(),
        'assignedStudents': editId != null ? null : <String>[], // Keep existing assignments when editing
        'active': true,
        'schoolId': 'SCH_001', // Default school ID
      };

      if (editId != null) {
        busData.remove('assignedStudents'); // Don't overwrite existing assignments
        await _firestore.collection('buses').doc(editId).update(busData);
      } else {
        busData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('buses').add(busData);
      }

      Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(editId != null ? 'Bus updated successfully' : 'Bus added successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving bus: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showAssignStudentsDialog(String busId, Map<String, dynamic> busData) {
    final capacity = busData['capacity'] ?? 0;

    setState(() {
      _selectedStudents = [];
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('students').snapshots(),
            builder: (context, studentsSnapshot) {
              if (!studentsSnapshot.hasData) {
                return const AlertDialog(
                  content: Center(child: CircularProgressIndicator()),
                );
              }

              // Count assigned students and get unassigned students
              int assignedCount = 0;
              final unassignedStudents = <Map<String, dynamic>>[];
              
              for (var doc in studentsSnapshot.data!.docs) {
                final studentData = doc.data() as Map<String, dynamic>;
                final studentBusId = studentData['busId'];
                
                if (studentBusId == busId) {
                  assignedCount++;
                } else if (studentBusId == null) {
                  unassignedStudents.add({
                    'id': doc.id,
                    'name': studentData['name'] ?? 'Unknown',
                    'grade': studentData['grade'] ?? 'Unknown',
                  });
                }
              }

              final availableSlots = capacity - assignedCount;

              return AlertDialog(
                title: Text('Assign Students to Bus ${busData['busNumber']}'),
                content: SizedBox(
                  width: 600,
                  height: 500,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.infoColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: AppTheme.infoColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Capacity: $capacity | Assigned: $assignedCount | Available slots: $availableSlots',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (unassignedStudents.isEmpty) ...[
                        const Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: AppTheme.textMuted),
                                SizedBox(height: 16),
                                Text(
                                  'No unassigned students available',
                                  style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'Select students to assign:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: unassignedStudents.length,
                            itemBuilder: (context, index) {
                              final student = unassignedStudents[index];
                              final isSelected = _selectedStudents.contains(student['id']);
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 4),
                                child: CheckboxListTile(
                                  title: Text(student['name']),
                                  subtitle: Text('Grade: ${student['grade']}'),
                                  value: isSelected,
                                  onChanged: (selected) {
                                    setDialogState(() {
                                      if (selected == true) {
                                        if (_selectedStudents.length < availableSlots) {
                                          _selectedStudents.add(student['id']);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Bus capacity reached'),
                                              backgroundColor: AppTheme.warningColor,
                                            ),
                                          );
                                        }
                                      } else {
                                        _selectedStudents.remove(student['id']);
                                      }
                                    });
                                  },
                                  secondary: CircleAvatar(
                                    backgroundColor: AppTheme.primaryColor,
                                    child: Text(
                                      student['name']?.toString().substring(0, 1).toUpperCase() ?? 'S',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  if (_selectedStudents.isNotEmpty)
                    ElevatedButton(
                      onPressed: () => _assignSelectedStudents(busId, busData),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Assign ${_selectedStudents.length} Students'),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _assignSelectedStudents(String busId, Map<String, dynamic> busData) async {
    try {
      final batch = _firestore.batch();
      
      for (final studentId in _selectedStudents) {
        final studentRef = _firestore.collection('students').doc(studentId);
        batch.update(studentRef, {'busId': busId});
      }
      
      await batch.commit();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully assigned ${_selectedStudents.length} students to Bus #${busData['busNumber']}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
      
      _selectedStudents.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning students: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showStudentBusAssignmentDialog(String studentId, Map<String, dynamic> studentData) {
    final currentBusId = studentData['busId'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${currentBusId != null ? 'Change' : 'Assign'} Bus for ${studentData['name']}'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('buses').where('active', isEqualTo: true).snapshots(),
            builder: (context, busSnapshot) {
              if (busSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!busSnapshot.hasData) {
                return const Center(child: Text('No buses available'));
              }

              return StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('students').snapshots(),
                builder: (context, studentsSnapshot) {
                  if (studentsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Count students per bus
                  final busStudentCounts = <String, int>{};
                  if (studentsSnapshot.hasData) {
                    for (var doc in studentsSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final busId = data['busId'];
                      if (busId != null) {
                        busStudentCounts[busId] = (busStudentCounts[busId] ?? 0) + 1;
                      }
                    }
                  }

                  final buses = busSnapshot.data!.docs;
                  final availableBuses = buses.where((bus) {
                    final busData = bus.data() as Map<String, dynamic>;
                    final capacity = busData['capacity'] ?? 0;
                    final currentCount = busStudentCounts[bus.id] ?? 0;
                    // Allow if bus has space OR it's the student's current bus
                    return currentCount < capacity || bus.id == currentBusId;
                  }).toList();

                  if (availableBuses.isEmpty) {
                    return const Center(
                      child: Text(
                        'No buses with available capacity',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: availableBuses.length,
                    itemBuilder: (context, index) {
                      final bus = availableBuses[index];
                      final busData = bus.data() as Map<String, dynamic>;
                      final capacity = busData['capacity'] ?? 0;
                      final currentCount = busStudentCounts[bus.id] ?? 0;
                      final isCurrentBus = bus.id == currentBusId;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isCurrentBus ? AppTheme.infoColor : AppTheme.textMuted.withOpacity(0.3),
                            width: isCurrentBus ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isCurrentBus ? AppTheme.infoColor.withOpacity(0.05) : null,
                        ),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text('Bus ${busData['busNumber']}'),
                              if (isCurrentBus) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.infoColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Current',
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text('Driver: ${busData['driverName']} • $currentCount/$capacity'),
                          trailing: ElevatedButton(
                            onPressed: () => _assignSingleStudentToBus(studentId, bus.id),
                            child: Text(isCurrentBus ? 'Keep' : 'Assign'),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignSingleStudentToBus(String studentId, String busId) async {
    try {
      // Simply update the student's busId - no need for complex batch operations
      await _firestore.collection('students').doc(studentId).update({
        'busId': busId,
      });
      
      Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student bus assignment updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating assignment: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _unassignStudentFromBus(String studentId, Map<String, dynamic> studentData) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unassign Student'),
        content: Text('Are you sure you want to unassign ${studentData['name']} from their bus?'),
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
            child: const Text('Unassign'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('students').doc(studentId).update({
          'busId': FieldValue.delete(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student unassigned successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
        
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error unassigning student: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteBus(String busId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bus'),
        content: const Text('Are you sure you want to delete this bus? This will also unassign all students from this bus.'),
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
        // Get bus data to find assigned students
        final busDoc = await _firestore.collection('buses').doc(busId).get();
        if (busDoc.exists) {
          final busData = busDoc.data() as Map<String, dynamic>;
          final assignedStudents = List<String>.from(busData['assignedStudents'] ?? []);
          
          final batch = _firestore.batch();
          
          // Unassign students from bus
          for (String studentId in assignedStudents) {
            batch.update(_firestore.collection('students').doc(studentId), {
              'busId': FieldValue.delete(),
            });
          }
          
          // Delete the bus
          batch.delete(_firestore.collection('buses').doc(busId));
          
          await batch.commit();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bus deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
        
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting bus: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Widget _buildRouteStatusButton(String busId, Map<String, dynamic> data) {
    final routeStatus = data['routeStatus'] ?? 'idle'; // 'idle', 'on_route'
    final isOnRoute = routeStatus == 'on_route';
    final isActive = data['active'] ?? true;
    
    // Don't show button if bus is inactive
    if (!isActive) {
      return const SizedBox.shrink();
    }
    
    return ElevatedButton.icon(
      onPressed: () => _toggleRouteStatus(busId, routeStatus),
      icon: Icon(
        isOnRoute ? Icons.stop : Icons.play_arrow,
        size: 16,
      ),
      label: Text(isOnRoute ? 'End Route' : 'Start Route'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isOnRoute ? AppTheme.errorColor : AppTheme.successColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _toggleRouteStatus(String busId, String currentStatus) async {
    try {
      final newStatus = currentStatus == 'on_route' ? 'idle' : 'on_route';
      
      final updateData = {
        'routeStatus': newStatus,
        'routeStatusUpdatedAt': FieldValue.serverTimestamp(),
      };
      
      // If starting route, set auto-end timer
      if (newStatus == 'on_route') {
        // Set to auto-end after 2 hours (7200 seconds)
        final autoEndTime = DateTime.now().add(const Duration(hours: 2));
        updateData['autoEndRouteAt'] = Timestamp.fromDate(autoEndTime);
      } else {
        // Remove auto-end timer when manually ending route
        updateData['autoEndRouteAt'] = FieldValue.delete();
      }
      
      await _firestore.collection('buses').doc(busId).update(updateData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'on_route' 
                  ? 'Bus is now on route' 
                  : 'Bus route ended'
            ),
            backgroundColor: newStatus == 'on_route' ? AppTheme.successColor : AppTheme.infoColor,
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating route status: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _navigateToBusDetails(String busId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BusDetailsScreen(busId: busId),
      ),
    );
  }
}
