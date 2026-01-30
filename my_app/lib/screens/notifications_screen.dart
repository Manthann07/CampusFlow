import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => NotificationService().clearAll(),
            child: const Text('Clear All'),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: NotificationService(),
        builder: (context, _) {
          final notifications = NotificationService().notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
                   const SizedBox(height: 16),
                   Text('No new notifications', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return Card(
                elevation: 0,
                color: n.isRead ? Theme.of(context).cardColor : AppTheme.primaryColor.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: n.isRead ? Colors.grey.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: n.isRead ? Colors.grey[100] : AppTheme.primaryColor.withOpacity(0.1),
                    child: Icon(
                      n.title.contains('Approved') ? Icons.check_circle_outline : Icons.info_outline,
                      color: n.title.contains('Approved') ? Colors.green : AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(n.body),
                      const SizedBox(height: 8),
                      Text(
                        '${n.timestamp.hour}:${n.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  onTap: () {
                    NotificationService().markAsRead(n.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
