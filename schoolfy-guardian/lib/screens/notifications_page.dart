import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      _notificationService.markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textP  = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textS  = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final textM  = isDark ? AppTheme.darkTextTertiary : AppTheme.textTertiary;
    final bgPage = isDark ? AppTheme.darkBackgroundColor : const Color(0xFFF8FAFC);
    final bgBar  = isDark ? AppTheme.darkSurfaceColor : Colors.white;

    return Scaffold(
      backgroundColor: bgPage,
      appBar: AppBar(
        backgroundColor: bgBar,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textP,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: isDark ? AppTheme.dividerColor : const Color(0xFFE2E8F0),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () async {
                await _notificationService.markAllAsRead();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('All notifications marked as read'),
                      backgroundColor: AppTheme.successColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM)),
                    ),
                  );
                }
              },
              icon: Icon(Icons.done_all_rounded, size: 18, color: AppTheme.primaryColor),
              label: Text(
                'Mark all read',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationService.getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 56, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: TextStyle(fontSize: 16, color: textS),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please try again later',
                    style: TextStyle(fontSize: 13, color: textM),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(textP, textS, textM);
          }

          final notifications = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc  = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildNotificationCard(doc.id, data, isDark, textP, textS, textM);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(Color textP, Color textS, Color textM) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(48),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textP,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You'll receive notifications about your children's school activities",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: textS, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    String notificationId,
    Map<String, dynamic> data,
    bool isDark,
    Color textP,
    Color textS,
    Color textM,
  ) {
    final isRead   = data['read'] ?? false;
    final priority = data['priority'] ?? 'normal';
    final type     = data['type']     ?? 'general';
    final timestamp = data['timestamp'] as Timestamp?;
    final grade    = data['grade'];

    // Derive type appearance
    Color typeColor;
    IconData typeIcon;
    switch (type) {
      case 'leave_time':
        typeIcon  = Icons.access_time_rounded;
        typeColor = priority == 'high' ? AppTheme.warningColor : AppTheme.infoColor;
        break;
      case 'emergency':
        typeIcon  = Icons.warning_amber_rounded;
        typeColor = AppTheme.errorColor;
        break;
      case 'announcement':
        typeIcon  = Icons.campaign_rounded;
        typeColor = AppTheme.primaryColor;
        break;
      default:
        typeIcon  = Icons.info_rounded;
        typeColor = AppTheme.primaryColor;
    }

    final cardBg  = isDark
        ? (isRead ? AppTheme.darkCardColor : AppTheme.darkSurfaceColor)
        : (isRead ? Colors.white : const Color(0xFFF0F7FF));
    final cardBdr = isDark
        ? (isRead ? AppTheme.darkDividerColor : AppTheme.primaryColor.withOpacity(0.3))
        : (isRead ? const Color(0xFFE2E8F0) : AppTheme.primaryColor.withOpacity(0.25));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(notificationId),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: AppTheme.errorColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
        ),
        onDismissed: (_) {
          _notificationService.deleteNotification(notificationId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notification deleted'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM)),
            ),
          );
        },
        child: InkWell(
          onTap: () {
            if (!isRead) _notificationService.markAsRead(notificationId);
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(color: cardBdr, width: isRead ? 1 : 1.5),
              boxShadow: isRead
                  ? null
                  : [BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['title'] ?? 'Notification',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                    color: textP,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: typeColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          if (grade != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Grade $grade',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  data['message'] ?? '',
                  style: TextStyle(fontSize: 13, color: textS, height: 1.4),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 13, color: textM),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(fontSize: 12, color: textM),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
