import 'package:flutter/material.dart';

class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy student details UI
    return Scaffold(
      appBar: AppBar(title: const Text('Student Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.deepPurple.shade100,
                child: Icon(Icons.person, size: 32, color: Colors.deepPurple.shade700),
              ),
              title: const Text('Sara Al-Zanbaqi', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Grade: 2A'),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Present'),
            subtitle: const Text('2025-07-09'),
          ),
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: const Text('Absent'),
            subtitle: const Text('2025-07-08'),
          ),
          // Add more details as needed
        ],
      ),
    );
  }
}
