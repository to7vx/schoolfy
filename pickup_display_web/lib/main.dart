import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:async';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PickupDisplayApp());
}

class PickupDisplayApp extends StatelessWidget {
  const PickupDisplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schoolfy Pickup Display',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      debugShowCheckedModeBanner: false,
      home: const PickupDisplayScreen(),
    );
  }
}

class PickupDisplayScreen extends StatefulWidget {
  const PickupDisplayScreen({super.key});

  @override
  State<PickupDisplayScreen> createState() => _PickupDisplayScreenState();
}

class _PickupDisplayScreenState extends State<PickupDisplayScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Map<String, List<PickupEntry>> _pickupsByGrade = {};
  DateTime _lastUpdate = DateTime.now();
  bool _isConnected = true;
  String _todayKey = '';
  
  // Auto-cleanup configuration
  static const Duration _autoCleanupDuration = Duration(minutes: 10);
  Timer? _cleanupTimer;

  @override
  void initState() {
    super.initState();
    _todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _setupPickupListener();
    
    // Auto-refresh every 30 seconds to ensure connection
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          _lastUpdate = DateTime.now();
        });
      }
    });
    
    // Start auto-cleanup timer - runs every minute to check for old entries
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _performAutoCleanup();
      }
    });
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    super.dispose();
  }

  void _setupPickupListener() {
    print('Setting up pickup listener for today: $_todayKey');
    _database.child('pickupQueue').child(_todayKey).onValue.listen(
      (DatabaseEvent event) {
        print('Received database event!');
        if (mounted) {
          setState(() {
            _isConnected = true;
            _lastUpdate = DateTime.now();
            _pickupsByGrade = _processPickupData(event.snapshot);
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isConnected = false;
          });
        }
        print('Firebase connection error: $error');
      },
    );
  }

  Map<String, List<PickupEntry>> _processPickupData(DataSnapshot snapshot) {
    final Map<String, List<PickupEntry>> result = {};
    
    // Debug logging
    print('Processing pickup data...');
    print('Snapshot exists: ${snapshot.exists}');
    print('Snapshot value: ${snapshot.value}');
    
    if (snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      
      print('Data entries count: ${data.length}');
      
      for (final entry in data.entries) {
        print('Processing entry: ${entry.key}');
        final pickupData = Map<String, dynamic>.from(entry.value as Map);
        print('Pickup data: $pickupData');
        
        final pickup = PickupEntry.fromJson(entry.key, pickupData);
        print('Created pickup entry: ${pickup.studentName} in ${pickup.grade}');
        
        if (!result.containsKey(pickup.grade)) {
          result[pickup.grade] = [];
        }
        result[pickup.grade]!.add(pickup);
      }
      
      // Sort each grade's pickups by time (newest first)
      for (final gradePickups in result.values) {
        gradePickups.sort((a, b) => b.time.compareTo(a.time));
      }
    }
    
    print('Final result grades: ${result.keys.toList()}');
    return result;
  }

  Color _getGradeColor(String grade) {
    final gradeColors = {
      '1': Colors.red.shade400,
      '2': Colors.blue.shade400,
      '3': Colors.green.shade400,
      '4': Colors.orange.shade400,
      '5': Colors.purple.shade400,
      '6': Colors.teal.shade400,
    };
    
    final gradeNumber = grade.substring(0, 1);
    return gradeColors[gradeNumber] ?? Colors.grey.shade400;
  }

  String _getTimeAgoText(DateTime pickupTime) {
    final now = DateTime.now();
    final difference = now.difference(pickupTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else {
      return 'At ${DateFormat('HH:mm').format(pickupTime)}';
    }
  }
  
  Color _getTimeAgoColor(DateTime pickupTime) {
    final now = DateTime.now();
    final difference = now.difference(pickupTime);
    
    if (difference.inMinutes < 2) {
      return Colors.green.shade600; // Very recent - green
    } else if (difference.inMinutes < 5) {
      return Colors.orange.shade600; // Recent - orange  
    } else {
      return Colors.red.shade600; // Old - red
    }
  }
  
  bool _isUrgentPickup(DateTime pickupTime) {
    final now = DateTime.now();
    final difference = now.difference(pickupTime);
    return difference.inMinutes >= 5; // Consider 5+ minutes as urgent
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _pickupsByGrade.isEmpty
                  ? _buildEmptyState()
                  : _buildPickupsList(),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.school,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schoolfy Pickup Display',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Students ready for pickup • Auto-cleanup: ${_autoCleanupDuration.inMinutes} min • ${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          _buildConnectionStatus(),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _isConnected ? 'LIVE' : 'OFFLINE',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom,
            size: 120,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No pickup requests yet',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Students will appear here when guardians arrive',
            style: GoogleFonts.inter(
              fontSize: 18,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Debug Info:',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            'Today key: $_todayKey',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            'Connected: $_isConnected',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: _isConnected ? Colors.green : Colors.red,
            ),
          ),
          Text(
            'Last update: ${DateFormat('HH:mm:ss').format(_lastUpdate)}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            'Auto-cleanup: ${_autoCleanupDuration.inMinutes} minutes',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupsList() {
    final grades = _pickupsByGrade.keys.toList()..sort();
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: math.min(grades.length, 3),
          childAspectRatio: 0.8,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
        ),
        itemCount: grades.length,
        itemBuilder: (context, index) {
          final grade = grades[index];
          final pickups = _pickupsByGrade[grade]!;
          return _buildGradeColumn(grade, pickups);
        },
      ),
    );
  }

  Widget _buildGradeColumn(String grade, List<PickupEntry> pickups) {
    final gradeColor = _getGradeColor(grade);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gradeColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: gradeColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Grade Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: gradeColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Text(
              'Grade $grade',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Students List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pickups.length,
              itemBuilder: (context, index) {
                final pickup = pickups[index];
                return _buildStudentCard(pickup, gradeColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(PickupEntry pickup, Color gradeColor) {
    final timeDiff = DateTime.now().difference(pickup.time);
    final isRecent = timeDiff.inMinutes < 5;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRecent ? gradeColor.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecent ? gradeColor : Colors.grey.shade300,
          width: isRecent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: gradeColor,
                radius: 20,
                child: Text(
                  pickup.studentName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pickup.studentName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _getTimeAgoText(pickup.time),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _getTimeAgoColor(pickup.time),
                        fontWeight: _isUrgentPickup(pickup.time) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (isRecent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'NEW',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Last updated: ${DateFormat('HH:mm:ss').format(_lastUpdate)}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            'Total students: ${_pickupsByGrade.values.fold(0, (sum, list) => sum + list.length)}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performAutoCleanup() async {
    try {
      final now = DateTime.now();
      final todayRef = _database.child('pickupQueue').child(_todayKey);
      final snapshot = await todayRef.get();
      
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        for (final entry in data.entries) {
          final pickupData = Map<String, dynamic>.from(entry.value as Map);
          final pickupTime = DateTime.parse(pickupData['time'] ?? now.toIso8601String());
          
          // Remove entries older than the cleanup duration
          if (now.difference(pickupTime) > _autoCleanupDuration) {
            await todayRef.child(entry.key).remove();
            print('Auto-cleaned old pickup entry: ${entry.key} (${pickupData['studentName']})');
          }
        }
      }
    } catch (e) {
      print('Auto-cleanup error: $e');
    }
  }
}

class PickupEntry {
  final String id;
  final String studentId;
  final String studentName;
  final String grade;
  final DateTime time;

  PickupEntry({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.grade,
    required this.time,
  });

  factory PickupEntry.fromJson(String id, Map<String, dynamic> json) {
    return PickupEntry(
      id: id,
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      grade: json['grade'] ?? '',
      time: DateTime.parse(json['time'] ?? DateTime.now().toIso8601String()),
    );
  }
}
