import 'package:flutter/material.dart';
import 'home_page.dart';
import 'students_page.dart';
import 'authorized_guardians_page.dart';
import 'settings_page.dart';

class MainNavScreen extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  const MainNavScreen({super.key, required this.students});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        students: widget.students,
        onPickup: (student) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pickup alert sent for ${student['studentName']}')),
          );
        },
      ),
      const StudentsPage(),
      const AuthorizedGuardiansPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Guardians'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
