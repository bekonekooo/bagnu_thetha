import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import "../../../data/models/notification_model.dart";
import '../../../data/services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService notificationService = NotificationService();

  late Future<List<NotificationModel>> notificationsFuture;
  RealtimeChannel? notificationChannel;

  @override
  void initState() {
    super.initState();
    loadNotifications();
    subscribeToNotifications();
  }

  void loadNotifications() {
    notificationsFuture = notificationService.fetchMyNotifications();
  }

  void subscribeToNotifications() {
   notificationChannel = notificationService.subscribeToMyNotifications(
  onChange: () {
    if (!mounted) return;

    setState(() {
      loadNotifications();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yeni bildirimin var'),
        duration: Duration(seconds: 3),
      ),
    );
  },
);
  }

  Future<void> refreshNotifications() async {
    setState(() {
      loadNotifications();
    });
  }

  Future<void> markAllAsRead() async {
    await notificationService.markAllAsRead();

    if (!mounted) return;

    setState(() {
      loadNotifications();
    });
  }

  Widget buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead ? Colors.white : const Color(0xFFF3E8FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          notification.isRead
              ? Icons.notifications_none
              : Icons.notifications_active,
          color: notification.isRead ? Colors.grey : Colors.deepPurple,
        ),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(notification.message),
        ),
        trailing: notification.isRead
            ? null
            : const Icon(
                Icons.circle,
                size: 10,
                color: Colors.red,
              ),
        onTap: () async {
          if (!notification.isRead) {
            await notificationService.markAsRead(notification.id);
            refreshNotifications();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    if (notificationChannel != null) {
      notificationService.removeChannel(notificationChannel!);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          TextButton(
            onPressed: markAllAsRead,
            child: const Text('Tümünü Okundu Yap'),
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Bildirimler yüklenemedi:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: refreshNotifications,
              child: ListView(
                children: const [
                  SizedBox(height: 220),
                  Center(child: Text('Henüz bildirimin yok.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refreshNotifications,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return buildNotificationCard(notifications[index]);
              },
            ),
          );
        },
      ),
    );
  }
}