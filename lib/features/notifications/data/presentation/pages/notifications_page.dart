import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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

  Future<void> deleteAllNotifications() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tüm Bildirimleri Sil'),
          content: const Text(
            'Tüm bildirimlerini silmek istediğine emin misin?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await notificationService.deleteAllMyNotifications();

    if (!mounted) return;

    setState(() {
      loadNotifications();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tüm bildirimler silindi'),
      ),
    );
  }

  IconData getNotificationIcon(String type) {
    switch (type) {
      case 'booking':
        return Icons.event_available;
      case 'cancelled':
        return Icons.event_busy;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'success':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Color getNotificationColor(String type) {
    switch (type) {
      case 'booking':
        return Colors.deepPurple;
      case 'cancelled':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  String formatDate(String createdAt) {
    if (createdAt.isEmpty) return '';

    try {
      final date = DateTime.parse(createdAt).toLocal();
      return DateFormat('dd MMMM yyyy HH:mm', 'tr_TR').format(date);
    } catch (_) {
      return '';
    }
  }

  Widget buildNotificationCard(NotificationModel notification) {
    final color = getNotificationColor(notification.type);
    final icon = getNotificationIcon(notification.type);
    final formattedDate = formatDate(notification.createdAt);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) async {
        await notificationService.deleteNotification(notification.id);

        if (!mounted) return;

        setState(() {
          loadNotifications();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bildirim silindi'),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: notification.isRead ? 1 : 4,
        color: notification.isRead ? Colors.white : const Color(0xFFF3E8FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            if (!notification.isRead) {
              await notificationService.markAsRead(notification.id);
              refreshNotifications();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(
                    icon,
                    color: color,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: notification.isRead
                              ? FontWeight.w600
                              : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                      if (formattedDate.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return RefreshIndicator(
      onRefresh: refreshNotifications,
      child: ListView(
        children: const [
          SizedBox(height: 180),
          Icon(
            Icons.notifications_off_outlined,
            size: 72,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              'Henüz bildirimin yok.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              'Yeni seans ve iptal bildirimleri burada görünecek.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
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
      backgroundColor: const Color(0xFFF8F7FB),
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          IconButton(
            onPressed: deleteAllNotifications,
            icon: const Icon(Icons.delete_sweep),
          ),
          TextButton.icon(
            onPressed: markAllAsRead,
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Okundu Yap'),
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
            return buildEmptyState();
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