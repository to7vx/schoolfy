import 'package:flutter/material.dart';

class AuthorizedGuardiansPage extends StatefulWidget {
  const AuthorizedGuardiansPage({super.key});

  @override
  State<AuthorizedGuardiansPage> createState() => _AuthorizedGuardiansPageState();
}

class _AuthorizedGuardiansPageState extends State<AuthorizedGuardiansPage> {
  // Dummy data for UI only
  String selectedStudentId = 'stu_001';
  final List<Map<String, String>> students = [
    {'studentId': 'stu_001', 'name': 'Sara'},
    {'studentId': 'stu_002', 'name': 'Omar'},
  ];
  final List<Map<String, String>> guardians = [
    {'guardianId': 'GDN_001', 'name': 'You (Primary)', 'phone': '+966500000001'},
    {'guardianId': 'GDN_002', 'name': 'Uncle Ali', 'phone': '+966500000002'},
    {'guardianId': 'GDN_003', 'name': 'Aunt Maryam', 'phone': '+966500000003'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authorized Guardians'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student selector
            Row(
              children: [
                const Text('Student:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: selectedStudentId,
                  items: students.map((student) {
                    return DropdownMenuItem<String>(
                      value: student['studentId'],
                      child: Text(student['name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => selectedStudentId = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Authorized Guardians:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: guardians.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final guardian = guardians[index];
                  final isPrimary = guardian['guardianId'] == 'GDN_001';
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(guardian['name']!.substring(0, 1)),
                    ),
                    title: Text(guardian['name'] ?? ''),
                    subtitle: Text(guardian['phone'] ?? ''),
                    trailing: isPrimary
                        ? const Chip(label: Text('Primary'))
                        : IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // TODO: Remove guardian logic
                            },
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Guardian'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const _AddGuardianDialog(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddGuardianDialog extends StatelessWidget {
  const _AddGuardianDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Authorized Guardian'),
      content: TextField(
        decoration: const InputDecoration(
          labelText: 'Guardian Phone Number',
          hintText: '+9665XXXXXXX',
        ),
        keyboardType: TextInputType.phone,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Add guardian logic
            Navigator.pop(context);
          },
          child: const Text('Send Authorization'),
        ),
      ],
    );
  }
}
