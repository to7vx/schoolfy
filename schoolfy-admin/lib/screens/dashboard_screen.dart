import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'dashboard_home_screen.dart';
import 'student_management_screen.dart';
import 'guardian_linking_screen.dart';
import 'student_leave_time_screen.dart';
import 'attendance_management_screen.dart';
import 'announcement_management_screen.dart';
import 'bus_management_screen.dart';
import 'pickup_queue_screen.dart';
import 'pickup_history_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(Icons.grid_view_rounded,    Icons.grid_view_rounded,       'Dashboard',      'Overview of your school'),
    _NavItem(Icons.school_rounded,       Icons.school_rounded,          'Students',       'Manage student records'),
    _NavItem(Icons.people_alt_rounded,   Icons.people_alt_rounded,      'Guardians',      'Guardian linking'),
    _NavItem(Icons.schedule_send_rounded, Icons.schedule_send_rounded,  'Leave Time',     'Schedule management'),
    _NavItem(Icons.event_note_rounded,   Icons.event_note_rounded,      'Attendance',     'Track attendance'),
    _NavItem(Icons.campaign_rounded,     Icons.campaign_rounded,        'Announcements',  'Send announcements'),
    _NavItem(Icons.directions_bus_rounded, Icons.directions_bus_rounded,'Bus Management', 'Manage routes'),
    _NavItem(Icons.queue_rounded,        Icons.queue_rounded,           'Pickup Queue',   'Live pickup queue'),
    _NavItem(Icons.history_rounded,      Icons.history_rounded,         'History',        'Pickup history'),
    _NavItem(Icons.settings_rounded,     Icons.settings_rounded,        'Settings',       'App configuration'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Provider.of<LocaleProvider>(context).isArabic;
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isWide = MediaQuery.of(context).size.width > 820;
    final isDark = themeProvider.isDarkMode;

    final screens = [
      const DashboardHomeScreen(),
      const StudentManagementScreen(),
      const GuardianLinkingScreen(),
      const StudentLeaveTimeScreen(),
      const AttendanceManagementScreen(),
      const AnnouncementManagementScreen(),
      const BusManagementScreen(),
      const PickupQueueScreen(),
      const PickupHistoryScreen(),
      const SettingsScreen(),
    ];

    // Update l10n labels
    final labels = [
      l10n.home, l10n.students, l10n.guardians, 'Leave Time',
      'Attendance', 'Announcements', 'Bus Management',
      l10n.pickupQueue, l10n.history, l10n.settings,
    ];
    for (int i = 0; i < labels.length; i++) {
      _navItems[i] = _navItems[i].copyWithLabel(labels[i]);
    }

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.bgColor : const Color(0xFFF8FAFC),
        body: Row(
          children: [
            _Sidebar(
              items: _navItems,
              selectedIndex: _selectedIndex,
              isWide: isWide,
              isDark: isDark,
              userName: authProvider.userData?['name'] ?? 'Admin',
              userEmail: authProvider.userData?['email'] ?? '',
              onSelect: (i) => setState(() => _selectedIndex = i),
              onSignOut: _showSignOutDialog,
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    title: _navItems[_selectedIndex].label,
                    isDark: isDark,
                    isArabic: isArabic,
                    themeProvider: themeProvider,
                    l10n: l10n,
                  ),
                  Expanded(child: screens[_selectedIndex]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOut),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar ────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final bool isWide;
  final bool isDark;
  final String userName;
  final String userEmail;
  final ValueChanged<int> onSelect;
  final VoidCallback onSignOut;

  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.isWide,
    required this.isDark,
    required this.userName,
    required this.userEmail,
    required this.onSelect,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final bg    = isDark ? AppTheme.surfaceColor : Colors.white;
    final bdr   = isDark ? AppTheme.borderColor  : const Color(0xFFE2E8F0);
    final width = isWide ? 240.0 : 72.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          right: BorderSide(color: bdr, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo
          _SidebarLogo(isWide: isWide, isDark: isDark),
          const SizedBox(height: 8),
          // Nav items
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 12 : 8,
                vertical: 4,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _NavTile(
                item: items[i],
                isSelected: i == selectedIndex,
                isWide: isWide,
                isDark: isDark,
                onTap: () => onSelect(i),
              ),
            ),
          ),
          // User footer
          _SidebarFooter(
            userName: userName,
            userEmail: userEmail,
            isWide: isWide,
            isDark: isDark,
            onSignOut: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  final bool isWide;
  final bool isDark;
  const _SidebarLogo({required this.isWide, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 16 : 12),
      child: Row(
        mainAxisAlignment: isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (isWide) ...[
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schoolfy',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Admin Portal',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final bool isWide;
  final bool isDark;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.isWide,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = AppTheme.primaryColor.withOpacity(isDark ? 0.15 : 0.08);
    final hoverBg    = AppTheme.primaryColor.withOpacity(0.06);
    final textColor  = isSelected
        ? AppTheme.primaryColor
        : (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Tooltip(
        message: isWide ? '' : item.label,
        preferBelow: false,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          hoverColor: hoverBg,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 12 : 0,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: isSelected
                  ? Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.25),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment:
                  isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: 20,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : (isDark ? AppTheme.textMuted : AppTheme.lightTextMuted),
                ),
                if (isWide) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  final String userName;
  final String userEmail;
  final bool isWide;
  final bool isDark;
  final VoidCallback onSignOut;

  const _SidebarFooter({
    required this.userName,
    required this.userEmail,
    required this.isWide,
    required this.isDark,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final bdr = isDark ? AppTheme.dividerColor : const Color(0xFFE2E8F0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, thickness: 1, color: bdr),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 12 : 8,
            vertical: 12,
          ),
          child: isWide
              ? Row(
                  children: [
                    _Avatar(name: userName),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onSignOut,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                      tooltip: 'Sign Out',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _Avatar(name: userName),
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: onSignOut,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                      tooltip: 'Sign Out',
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : 'A';
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── Top Bar ────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  final bool isDark;
  final bool isArabic;
  final ThemeProvider themeProvider;
  final AppLocalizations l10n;

  const _TopBar({
    required this.title,
    required this.isDark,
    required this.isArabic,
    required this.themeProvider,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final bg  = isDark ? AppTheme.surfaceColor : Colors.white;
    final bdr = isDark ? AppTheme.borderColor  : const Color(0xFFE2E8F0);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: bdr, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
              letterSpacing: 0.1,
            ),
          ),
          const Spacer(),
          // Language toggle
          _TopBarBtn(
            icon: Icons.language_rounded,
            tooltip: l10n.language,
            isDark: isDark,
            onTap: () =>
                Provider.of<LocaleProvider>(context, listen: false).toggleLocale(),
          ),
          const SizedBox(width: 4),
          // Theme toggle
          _TopBarBtn(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            isDark: isDark,
            onTap: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
    );
  }
}

class _TopBarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;

  const _TopBarBtn({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardColor : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
            border: Border.all(
              color: isDark ? AppTheme.borderColor : const Color(0xFFE2E8F0),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Data Models ───────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String subtitle;

  const _NavItem(this.icon, this.selectedIcon, this.label, this.subtitle);

  _NavItem copyWithLabel(String newLabel) =>
      _NavItem(icon, selectedIcon, newLabel, subtitle);
}
