import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase  _database  = FirebaseDatabase.instance;

  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final today    = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final results = await Future.wait([
        _firestore.collection('students').get(),
        _firestore.collection('users').where('role', isEqualTo: 'guardian').get(),
        _database.ref('pickupQueue/$todayStr').get(),
        _firestore.collection('pickupLogs')
            .where('timestamp', isGreaterThan: Timestamp.fromDate(DateTime(today.year, today.month, today.day)))
            .get(),
      ]);

      final students  = results[0] as QuerySnapshot;
      final guardians = results[1] as QuerySnapshot;
      final queue     = results[2] as DataSnapshot;
      final logs      = results[3] as QuerySnapshot;

      int activePickups = 0;
      if (queue.exists && queue.value != null) {
        activePickups = (queue.value as Map).length;
      }

      final Map<String, int> gradeDistribution = {};
      for (final doc in students.docs) {
        final g = (doc.data() as Map<String, dynamic>)['grade'] ?? 'Unknown';
        gradeDistribution[g] = (gradeDistribution[g] ?? 0) + 1;
      }

      setState(() {
        _stats = {
          'totalStudents':    students.size,
          'totalGuardians':   guardians.size,
          'activePickups':    activePickups,
          'todayPickups':     logs.size,
          'gradeDistribution': gradeDistribution,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading statistics: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading dashboard…',
              style: TextStyle(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _DashboardHeader(isDark: isDark),
          const SizedBox(height: 28),

          // ── Stat Cards ───────────────────────────────────────────────────
          LayoutBuilder(
            builder: (_, constraints) {
              final cols = constraints.maxWidth > 1100 ? 4
                         : constraints.maxWidth > 700  ? 2
                         : 1;
              return _StatGrid(
                cols: cols,
                cards: [
                  _StatCardData(
                    label:  l10n.students,
                    value:  _stats['totalStudents']?.toString() ?? '0',
                    icon:   Icons.school_rounded,
                    color:  AppTheme.primaryColor,
                    trend:  '+12% this month',
                  ),
                  _StatCardData(
                    label:  l10n.guardians,
                    value:  _stats['totalGuardians']?.toString() ?? '0',
                    icon:   Icons.people_alt_rounded,
                    color:  AppTheme.accentColor,
                    trend:  'Active accounts',
                  ),
                  _StatCardData(
                    label:  'Active Pickups',
                    value:  _stats['activePickups']?.toString() ?? '0',
                    icon:   Icons.directions_bus_rounded,
                    color:  AppTheme.warningColor,
                    trend:  'Right now',
                    pulse:  (_stats['activePickups'] ?? 0) > 0,
                  ),
                  _StatCardData(
                    label:  "Today's Pickups",
                    value:  _stats['todayPickups']?.toString() ?? '0',
                    icon:   Icons.check_circle_rounded,
                    color:  AppTheme.successColor,
                    trend:  'Completed today',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // ── Grade Distribution ───────────────────────────────────────────
          if ((_stats['gradeDistribution'] as Map?)?.isNotEmpty == true)
            _GradeChart(
              distribution: Map<String, int>.from(_stats['gradeDistribution']!),
              isDark: isDark,
            ),
        ],
      ),
    );
  }
}

// ── Dashboard Header ───────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final bool isDark;
  const _DashboardHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary   = isDark ? AppTheme.textPrimary   : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting 👋',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              Text(
                'School Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        _RefreshBtn(isDark: isDark),
      ],
    );
  }
}

class _RefreshBtn extends StatefulWidget {
  final bool isDark;
  const _RefreshBtn({required this.isDark});
  @override
  State<_RefreshBtn> createState() => _RefreshBtnState();
}

class _RefreshBtnState extends State<_RefreshBtn> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final screen = context.findAncestorStateOfType<_DashboardHomeScreenState>();
        screen?._loadStats();
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isDark ? AppTheme.cardColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: Border.all(
            color: widget.isDark ? AppTheme.borderColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh_rounded,
              size: 16,
              color: widget.isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Refresh',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Grid ─────────────────────────────────────────────────────────────
class _StatGrid extends StatelessWidget {
  final int cols;
  final List<_StatCardData> cards;
  const _StatGrid({required this.cols, required this.cards});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _StatCard(data: cards[i]),
    );
  }
}

class _StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool pulse;
  const _StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    this.pulse = false,
  });
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppTheme.cardColor : Colors.white;
    final border = isDark ? AppTheme.borderColor : const Color(0xFFE2E8F0);
    final textP  = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textS  = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: border),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Stack(
        children: [
          // Accent stripe
          Positioned(
            top: 0, left: 0, bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: data.color,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppTheme.radiusL)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: data.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(data.icon, color: data.color, size: 20),
                    ),
                    const Spacer(),
                    if (data.pulse)
                      _PulseDot(color: data.color),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.value,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textP,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textS,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.trend,
                      style: TextStyle(
                        fontSize: 11,
                        color: data.color,
                        fontWeight: FontWeight.w500,
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
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(_anim.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_anim.value * 0.4),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grade Chart ─────────────────────────────────────────────────────────
class _GradeChart extends StatelessWidget {
  final Map<String, int> distribution;
  final bool isDark;
  const _GradeChart({required this.distribution, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? AppTheme.cardColor : Colors.white;
    final border = isDark ? AppTheme.borderColor : const Color(0xFFE2E8F0);
    final textP  = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textS  = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    final sorted = distribution.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxVal = sorted.isEmpty ? 1
        : sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textP,
                    ),
                  ),
                  Text(
                    'Students per grade',
                    style: TextStyle(fontSize: 12, color: textS),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: sorted.map((entry) {
                final pct    = entry.value / maxVal;
                final color  = AppTheme.getGradeColor(entry.key);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: pct * 130,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [color, color.withOpacity(0.7)],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'G${entry.key}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textS,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
