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
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Provider.of<LocaleProvider>(context).isArabic;
    final authProvider = Provider.of<AuthProvider>(context);

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

    final navigationItems = [
      NavigationItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: l10n.home,
      ),
      NavigationItem(
        icon: Icons.school_outlined,
        selectedIcon: Icons.school,
        label: l10n.students,
      ),
      NavigationItem(
        icon: Icons.people_outlined,
        selectedIcon: Icons.people,
        label: l10n.guardians,
      ),
      NavigationItem(
        icon: Icons.schedule_send_outlined,
        selectedIcon: Icons.schedule_send,
        label: 'Leave Time',
      ),
      NavigationItem(
        icon: Icons.calendar_today_outlined,
        selectedIcon: Icons.calendar_today,
        label: 'Attendance',
      ),
      NavigationItem(
        icon: Icons.campaign_outlined,
        selectedIcon: Icons.campaign,
        label: 'Announcements',
      ),
      NavigationItem(
        icon: Icons.directions_bus_outlined,
        selectedIcon: Icons.directions_bus,
        label: 'Bus Management',
      ),
      NavigationItem(
        icon: Icons.queue_outlined,
        selectedIcon: Icons.queue,
        label: l10n.pickupQueue,
      ),
      NavigationItem(
        icon: Icons.history_outlined,
        selectedIcon: Icons.history,
        label: l10n.history,
      ),
      NavigationItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.settings,
      ),
    ];

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Row(
          children: [
            // Navigation Rail
            NavigationRail(
              extended: MediaQuery.of(context).size.width > 800,
              destinations: navigationItems
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: Text(item.label),
                      ))
                  .toList(),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 2,
              leading: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (MediaQuery.of(context).size.width > 800) ...[
                    Text(
                      'Schoolfy',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      'Admin',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  // User Info
                  if (MediaQuery.of(context).size.width > 800) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              authProvider.userData?['name']?.substring(0, 1).toUpperCase() ?? 'A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            authProvider.userData?['name'] ?? 'Admin',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            authProvider.userData?['email'] ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Sign Out Button
                  IconButton(
                    onPressed: () => _showSignOutDialog(),
                    icon: const Icon(Icons.logout),
                    tooltip: l10n.signOut,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            
            // Main Content
            Expanded(
              child: Column(
                children: [
                  // App Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AppBar(
                      title: Text(navigationItems[_selectedIndex].label),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      automaticallyImplyLeading: false,
                      actions: [
                        // Language Toggle
                        IconButton(
                          onPressed: () {
                            Provider.of<LocaleProvider>(context, listen: false)
                                .toggleLocale();
                          },
                          icon: const Icon(Icons.language),
                          tooltip: l10n.language,
                        ),
                        // Theme Toggle
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, child) {
                            return IconButton(
                              onPressed: () {
                                themeProvider.toggleTheme();
                              },
                              icon: Icon(
                                themeProvider.isDarkMode 
                                  ? Icons.light_mode 
                                  : Icons.dark_mode,
                              ),
                              tooltip: themeProvider.isDarkMode 
                                ? 'Switch to Light Mode' 
                                : 'Switch to Dark Mode',
                            );
                          },
                        ),
                        // Refresh Button
                        IconButton(
                          onPressed: () {
                            // Trigger refresh for current screen
                          },
                          icon: const Icon(Icons.refresh),
                          tooltip: l10n.refresh,
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                  
                  // Screen Content
                  Expanded(
                    child: screens[_selectedIndex],
                  ),
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
      builder: (context) => AlertDialog(
        title: Text(l10n.signOut),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
