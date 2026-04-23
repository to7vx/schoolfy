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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PickupDisplayApp());
}

// ── Brand Colors ────────────────────────────────────────────────────────────
const _kBg       = Color(0xFF020617);
const _kSurface  = Color(0xFF0D1526);
const _kCard     = Color(0xFF111B2E);
const _kBorder   = Color(0xFF1E3A5F);
const _kPrimary  = Color(0xFF3B82F6);
const _kTextP    = Color(0xFFF1F5F9);
const _kTextS    = Color(0xFF94A3B8);
const _kTextM    = Color(0xFF64748B);
const _kSuccess  = Color(0xFF22C55E);
const _kWarning  = Color(0xFFF59E0B);
const _kError    = Color(0xFFEF4444);

const _kGradeColors = [
  Color(0xFFEF4444), // 1 – red
  Color(0xFF3B82F6), // 2 – blue
  Color(0xFF22C55E), // 3 – green
  Color(0xFFF59E0B), // 4 – amber
  Color(0xFF8B5CF6), // 5 – violet
  Color(0xFF06B6D4), // 6 – cyan
];

class PickupDisplayApp extends StatelessWidget {
  const PickupDisplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schoolfy Pickup Display',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary:    _kPrimary,
          surface:    _kSurface,
          background: _kBg,
        ),
        scaffoldBackgroundColor: _kBg,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      debugShowCheckedModeBanner: false,
      home: const PickupDisplayScreen(),
    );
  }
}

// ── Main Screen ──────────────────────────────────────────────────────────────
class PickupDisplayScreen extends StatefulWidget {
  const PickupDisplayScreen({super.key});

  @override
  State<PickupDisplayScreen> createState() => _PickupDisplayScreenState();
}

class _PickupDisplayScreenState extends State<PickupDisplayScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Map<String, List<PickupEntry>> _pickupsByGrade = {};
  DateTime _lastUpdate = DateTime.now();
  bool _isConnected = true;
  String _todayKey = '';

  static const _autoCleanup = Duration(minutes: 1);
  Timer? _cleanupTimer;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _setupPickupListener();

    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _lastUpdate = DateTime.now());
    });

    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _performAutoCleanup();
    });
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _setupPickupListener() {
    _db.child('pickupQueue').child(_todayKey).onValue.listen(
      (event) {
        if (mounted) {
          setState(() {
            _isConnected = true;
            _lastUpdate  = DateTime.now();
            _pickupsByGrade = _processPickupData(event.snapshot);
          });
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isConnected = false);
      },
    );
  }

  Map<String, List<PickupEntry>> _processPickupData(DataSnapshot snapshot) {
    final Map<String, List<PickupEntry>> result = {};
    if (snapshot.value == null) return result;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    for (final entry in data.entries) {
      final raw    = Map<String, dynamic>.from(entry.value as Map);
      final pickup = PickupEntry.fromJson(entry.key, raw);
      result.putIfAbsent(pickup.grade, () => []).add(pickup);
    }

    for (final list in result.values) {
      list.sort((a, b) => b.time.compareTo(a.time));
    }
    return result;
  }

  Color _gradeColor(String grade) {
    final n = int.tryParse(grade.substring(0, 1).trim()) ?? 1;
    return _kGradeColors[(n - 1).clamp(0, _kGradeColors.length - 1)];
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just arrived';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return 'At ${DateFormat('HH:mm').format(t)}';
  }

  Color _timeAgoColor(DateTime t) {
    final s = DateTime.now().difference(t).inSeconds;
    if (s < 30) return _kSuccess;
    if (s < 45) return _kWarning;
    return _kError;
  }

  bool _isUrgent(DateTime t) => DateTime.now().difference(t).inSeconds >= 45;
  bool _isRecent(DateTime t) => DateTime.now().difference(t).inMinutes < 5;

  int get _totalStudents =>
      _pickupsByGrade.values.fold(0, (s, l) => s + l.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _Header(
            isConnected: _isConnected,
            lastUpdate:  _lastUpdate,
            total:       _totalStudents,
          ),
          Expanded(
            child: _pickupsByGrade.isEmpty
                ? const _EmptyState()
                : _PickupGrid(
                    grades:        _pickupsByGrade.keys.toList()..sort(),
                    pickupsByGrade: _pickupsByGrade,
                    gradeColor:    _gradeColor,
                    timeAgo:       _timeAgo,
                    timeAgoColor:  _timeAgoColor,
                    isUrgent:      _isUrgent,
                    isRecent:      _isRecent,
                  ),
          ),
          _Footer(lastUpdate: _lastUpdate, total: _totalStudents),
        ],
      ),
    );
  }

  Future<void> _performAutoCleanup() async {
    try {
      final ref  = _db.child('pickupQueue').child(_todayKey);
      final snap = await ref.get();
      if (!snap.exists || snap.value == null) return;

      final data = Map<String, dynamic>.from(snap.value as Map);
      final now  = DateTime.now();

      for (final entry in data.entries) {
        try {
          final raw = Map<String, dynamic>.from(entry.value as Map);
          final rt  = raw['requestTime'];
          if (rt == null) continue;

          final t = rt is num
              ? DateTime.fromMillisecondsSinceEpoch(rt.toInt())
              : DateTime.parse(rt as String);

          if (now.difference(t) > _autoCleanup) {
            await ref.child(entry.key).remove();
          }
        } catch (_) {}
      }
    } catch (_) {}
  }
}

// ── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isConnected;
  final DateTime lastUpdate;
  final int total;

  const _Header({
    required this.isConnected,
    required this.lastUpdate,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        children: [
          // Logo + title
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1D4ED8), _kPrimary],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schoolfy — Pickup Display',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _kTextP,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                  style: GoogleFonts.inter(fontSize: 14, color: _kTextS),
                ),
              ],
            ),
          ),
          // Stats pills
          if (total > 0) ...[
            _Pill(
              label: '$total waiting',
              icon: Icons.people_rounded,
              color: _kPrimary,
            ),
            const SizedBox(width: 8),
          ],
          // Connection status
          _ConnectionBadge(isConnected: isConnected),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Pill({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionBadge extends StatefulWidget {
  final bool isConnected;
  const _ConnectionBadge({required this.isConnected});
  @override
  State<_ConnectionBadge> createState() => _ConnectionBadgeState();
}

class _ConnectionBadgeState extends State<_ConnectionBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.isConnected ? _kSuccess : _kError;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(widget.isConnected ? _pulse.value * 0.5 : 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(widget.isConnected ? _pulse.value : 0.8),
                boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.isConnected ? 'LIVE' : 'OFFLINE',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatefulWidget {
  const _EmptyState();
  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: _kBorder),
              ),
              child: Icon(
                Icons.family_restroom_rounded,
                size: 60,
                color: _kPrimary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No Pickup Requests',
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: _kTextP,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Students will appear here when guardians arrive',
              style: GoogleFonts.inter(fontSize: 18, color: _kTextS),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pickup Grid ───────────────────────────────────────────────────────────────
class _PickupGrid extends StatelessWidget {
  final List<String> grades;
  final Map<String, List<PickupEntry>> pickupsByGrade;
  final Color Function(String) gradeColor;
  final String Function(DateTime) timeAgo;
  final Color Function(DateTime) timeAgoColor;
  final bool Function(DateTime) isUrgent;
  final bool Function(DateTime) isRecent;

  const _PickupGrid({
    required this.grades,
    required this.pickupsByGrade,
    required this.gradeColor,
    required this.timeAgo,
    required this.timeAgoColor,
    required this.isUrgent,
    required this.isRecent,
  });

  @override
  Widget build(BuildContext context) {
    final cols = math.min(grades.length, 4);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: grades.length,
        itemBuilder: (_, i) {
          final grade   = grades[i];
          final pickups = pickupsByGrade[grade]!;
          return _GradeColumn(
            grade:        grade,
            pickups:      pickups,
            color:        gradeColor(grade),
            timeAgo:      timeAgo,
            timeAgoColor: timeAgoColor,
            isUrgent:     isUrgent,
            isRecent:     isRecent,
          );
        },
      ),
    );
  }
}

// ── Grade Column ──────────────────────────────────────────────────────────────
class _GradeColumn extends StatelessWidget {
  final String grade;
  final List<PickupEntry> pickups;
  final Color color;
  final String Function(DateTime) timeAgo;
  final Color Function(DateTime) timeAgoColor;
  final bool Function(DateTime) isUrgent;
  final bool Function(DateTime) isRecent;

  const _GradeColumn({
    required this.grade,
    required this.pickups,
    required this.color,
    required this.timeAgo,
    required this.timeAgoColor,
    required this.isUrgent,
    required this.isRecent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: -2,
          ),
          const BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Grade header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: color.withOpacity(0.3))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.4), blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Grade $grade',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${pickups.length}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Student list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: pickups.length,
              itemBuilder: (_, i) => _StudentCard(
                pickup:       pickups[i],
                gradeColor:   color,
                timeAgo:      timeAgo,
                timeAgoColor: timeAgoColor,
                isUrgent:     isUrgent,
                isRecent:     isRecent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Student Card ─────────────────────────────────────────────────────────────
class _StudentCard extends StatelessWidget {
  final PickupEntry pickup;
  final Color gradeColor;
  final String Function(DateTime) timeAgo;
  final Color Function(DateTime) timeAgoColor;
  final bool Function(DateTime) isUrgent;
  final bool Function(DateTime) isRecent;

  const _StudentCard({
    required this.pickup,
    required this.gradeColor,
    required this.timeAgo,
    required this.timeAgoColor,
    required this.isUrgent,
    required this.isRecent,
  });

  @override
  Widget build(BuildContext context) {
    final urgent = isUrgent(pickup.time);
    final recent = isRecent(pickup.time);
    final tColor = timeAgoColor(pickup.time);

    final cardBg = urgent
        ? _kError.withOpacity(0.08)
        : recent
            ? gradeColor.withOpacity(0.08)
            : _kSurface;
    final cardBdr = urgent
        ? _kError.withOpacity(0.4)
        : recent
            ? gradeColor.withOpacity(0.3)
            : _kBorder;

    final initials = pickup.studentName.isNotEmpty
        ? pickup.studentName.trim().split(' ').take(2)
            .map((w) => w[0].toUpperCase()).join()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBdr, width: urgent || recent ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: gradeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: gradeColor.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  color: gradeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pickup.studentName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kTextP,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo(pickup.time),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: tColor,
                    fontWeight: urgent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (recent && !urgent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _kSuccess.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kSuccess.withOpacity(0.3)),
              ),
              child: Text(
                'NEW',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _kSuccess,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          if (urgent)
            Icon(Icons.priority_high_rounded, size: 18, color: _kError),
        ],
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final DateTime lastUpdate;
  final int total;
  const _Footer({required this.lastUpdate, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.update_rounded, size: 14, color: _kTextM),
          const SizedBox(width: 6),
          Text(
            'Last updated: ${DateFormat('HH:mm:ss').format(lastUpdate)}',
            style: GoogleFonts.inter(fontSize: 13, color: _kTextM),
          ),
          const Spacer(),
          Text(
            'Total in queue: ',
            style: GoogleFonts.inter(fontSize: 13, color: _kTextM),
          ),
          Text(
            '$total students',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kTextS,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            'Schoolfy',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _kPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data Model ────────────────────────────────────────────────────────────────
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
    DateTime time;
    final rt = json['requestTime'];
    if (rt is num) {
      time = DateTime.fromMillisecondsSinceEpoch(rt.toInt());
    } else if (rt is String) {
      try {
        time = DateTime.parse(rt);
      } catch (_) {
        time = DateTime.now();
      }
    } else {
      time = DateTime.now();
    }
    return PickupEntry(
      id:          id,
      studentId:   json['studentId']   ?? '',
      studentName: json['studentName'] ?? '',
      grade:       json['grade']       ?? '',
      time:        time,
    );
  }
}
