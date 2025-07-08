import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final void Function(Map<String, dynamic>) onPickup;

  const HomePage({super.key, required this.students, required this.onPickup});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('My Students')),
      body: Column(
        children: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Welcome, ${user.uid}'),
            ),
          Expanded(
            child: students.isEmpty
                ? const Center(child: Text('No students linked.'))
                : ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(student['studentName'] ?? ''),
                          subtitle: Text('Grade: ${student['grade'] ?? ''}'),
                          trailing: ElevatedButton(
                            onPressed: () => onPickup(student),
                            child: const Text('Send Pickup Alert'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
