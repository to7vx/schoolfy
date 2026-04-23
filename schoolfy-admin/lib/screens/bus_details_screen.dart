import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';

class BusDetailsScreen extends StatefulWidget {
  final String busId;

  const BusDetailsScreen({
    super.key,
    required this.busId,
  });

  @override
  State<BusDetailsScreen> createState() => _BusDetailsScreenState();
}

class _BusDetailsScreenState extends State<BusDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isEditing = false;
  
  final TextEditingController _busNumberController = TextEditingController();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _driverPhoneController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String _selectedStatus = 'Active';

  @override
  void dispose() {
    _busNumberController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _licensePlateController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateControllers(Map<String, dynamic> data) {
    _busNumberController.text = data['busNumber'] ?? '';
    _driverNameController.text = data['driverName'] ?? '';
    _driverPhoneController.text = data['driverPhone'] ?? '';
    _licensePlateController.text = data['licensePlate'] ?? '';
    _modelController.text = data['model'] ?? '';
    _yearController.text = (data['year'] ?? '').toString();
    _capacityController.text = (data['capacity'] ?? '').toString();
    _notesController.text = data['notes'] ?? '';
    
    // Convert active boolean to status string
    final isActive = data['active'] ?? true;
    _selectedStatus = isActive ? 'Active' : 'Inactive';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Bus Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Bus Details',
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('buses').doc(widget.busId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading bus details',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
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
                    'Bus not found',
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

          final busData = snapshot.data!.data() as Map<String, dynamic>;
          
          // Populate controllers if not editing (to show current data)
          if (!_isEditing) {
            _populateControllers(busData);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.directions_bus,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bus #${busData['busNumber'] ?? 'Unknown'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    busData['model'] ?? 'Unknown Model',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: (busData['active'] ?? true)
                                    ? AppTheme.successColor.withOpacity(0.2)
                                    : AppTheme.errorColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: (busData['active'] ?? true)
                                      ? AppTheme.successColor.withOpacity(0.5)
                                      : AppTheme.errorColor.withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                (busData['active'] ?? true) ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: (busData['active'] ?? true)
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bus Information Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Bus Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        _buildDetailRow(
                          'Bus Number',
                          _busNumberController,
                          Icons.confirmation_number,
                          required: true,
                        ),
                        const SizedBox(height: 16),
                        
                        _buildDetailRow(
                          'License Plate',
                          _licensePlateController,
                          Icons.credit_card,
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailRow(
                                'Model',
                                _modelController,
                                Icons.directions_bus,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDetailRow(
                                'Year',
                                _yearController,
                                Icons.calendar_today,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailRow(
                                'Capacity',
                                _capacityController,
                                Icons.people,
                                keyboardType: TextInputType.number,
                                required: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatusDropdown(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Driver Information Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Driver Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        _buildDetailRow(
                          'Driver Name',
                          _driverNameController,
                          Icons.person_outline,
                          required: true,
                        ),
                        const SizedBox(height: 16),
                        
                        _buildDetailRow(
                          'Driver Phone',
                          _driverPhoneController,
                          Icons.phone,
                          keyboardType: TextInputType.phone,
                          required: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Notes Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.note,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Additional Notes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        _buildNotesField(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                if (_isEditing) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveBusDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _isEditing = false);
                            _populateControllers(busData);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
            ),
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: _isEditing,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: _isEditing 
                ? (Theme.of(context).brightness == Brightness.dark ? AppTheme.cardColor : Colors.white)
                : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111827) : const Color(0xFFF3F4F6)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondary : const Color(0xFFD1D5DB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondary : const Color(0xFFD1D5DB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
              ),
            ),
          ),
          style: TextStyle(
            color: _isEditing 
                ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFD1D5DB) : const Color(0xFF374151)),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        _isEditing
            ? DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.traffic, size: 20),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.cardColor : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondary : const Color(0xFFD1D5DB),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondary : const Color(0xFFD1D5DB),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                items: ['Active', 'Inactive'].map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              )
            : TextFormField(
                initialValue: _selectedStatus,
                enabled: false,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.traffic, size: 20),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                    ),
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                  fontWeight: FontWeight.w500,
                ),
              ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      enabled: _isEditing,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Enter any additional notes or comments...',
        filled: true,
        fillColor: _isEditing 
            ? (Theme.of(context).brightness == Brightness.dark ? AppTheme.cardColor : Colors.white)
            : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111827) : const Color(0xFFF3F4F6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondary : const Color(0xFFD1D5DB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondary : const Color(0xFFD1D5DB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      style: TextStyle(
        color: _isEditing 
            ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
            : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFD1D5DB) : const Color(0xFF374151)),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Future<void> _saveBusDetails() async {
    // Validate required fields
    if (_busNumberController.text.trim().isEmpty) {
      _showErrorSnackBar('Bus number is required');
      return;
    }
    
    if (_driverNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Driver name is required');
      return;
    }
    
    if (_driverPhoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Driver phone is required');
      return;
    }
    
    if (_capacityController.text.trim().isEmpty) {
      _showErrorSnackBar('Capacity is required');
      return;
    }

    try {
      final capacity = int.tryParse(_capacityController.text.trim());
      if (capacity == null || capacity <= 0) {
        _showErrorSnackBar('Please enter a valid capacity');
        return;
      }

      final year = _yearController.text.trim().isNotEmpty 
          ? int.tryParse(_yearController.text.trim()) 
          : null;
      
      if (year != null && (year < 1950 || year > DateTime.now().year + 5)) {
        _showErrorSnackBar('Please enter a valid year');
        return;
      }

      await _firestore.collection('buses').doc(widget.busId).update({
        'busNumber': _busNumberController.text.trim(),
        'driverName': _driverNameController.text.trim(),
        'driverPhone': _driverPhoneController.text.trim(),
        'licensePlate': _licensePlateController.text.trim(),
        'model': _modelController.text.trim(),
        'year': year,
        'capacity': capacity,
        'active': _selectedStatus == 'Active',
        'notes': _notesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bus details updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error updating bus details: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
