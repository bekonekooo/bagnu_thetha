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

  bool isProcessing = false;

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

    await notificationsFuture;
  }

  Future<void> markSingleAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await notificationService.markAsRead(notification.id);

      if (!mounted) return;

      setState(() {
        loadNotifications();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bildirim okundu yapılamadı: $e')),
      );
    }
  }

  Future<void> markAllAsRead() async {
    if (isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tümünü okundu yap'),
          content: const Text(
            'Tüm okunmamış bildirimleri okundu olarak işaretlemek istiyor musun?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Vazgeç'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.done_all),
              label: const Text('Okundu Yap'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      isProcessing = true;
    });

    try {
      await notificationService.markAllAsRead();

      if (!mounted) return;

      setState(() {
        loadNotifications();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tüm bildirimler okundu yapıldı'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem başarısız: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> deleteAllNotifications() async {
    if (isProcessing) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tüm bildirimleri sil'),
          content: const Text(
            'Tüm bildirimlerini kalıcı olarak silmek istediğine emin misin?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Vazgeç'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Sil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      isProcessing = true;
    });

    try {
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
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bildirimler silinemedi: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> deleteSingleNotification(NotificationModel notification) async {
    try {
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
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bildirim silinemedi: $e')),
      );
    }
  }

  IconData getNotificationIcon(String type) {
    switch (type) {
      case 'booking':
        return Icons.event_available;
      case 'cancelled':
        return Icons.event_busy;
      case 'student_cancelled':
        return Icons.person_off_outlined;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'success':
        return Icons.check_circle_outline;
      case 'info':
        return Icons.info_outline;
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
      case 'student_cancelled':
        return Colors.orange;
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'info':
        return Colors.blueGrey;
      default:
        return Colors.blueGrey;
    }
  }

  String getNotificationTypeText(String type) {
    switch (type) {
      case 'booking':
        return 'Yeni seans';
      case 'cancelled':
        return 'İptal';
      case 'student_cancelled':
        return 'Öğrenci iptali';
      case 'warning':
        return 'Uyarı';
      case 'success':
        return 'Başarılı';
      case 'info':
        return 'Bilgi';
      default:
        return 'Bildirim';
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

  int unreadCount(List<NotificationModel> notifications) {
    return notifications.where((notification) => !notification.isRead).length;
  }

  Widget buildHeaderCard(List<NotificationModel> notifications) {
    final total = notifications.length;
    final unread = unreadCount(notifications);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade400,
            Colors.deepPurple.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.notifications_active_outlined,
              color: Colors.deepPurple,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bildirimler',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  unread > 0
                      ? '$unread okunmamış, toplam $total bildirim var.'
                      : total > 0
                          ? 'Tüm bildirimlerin okundu.'
                          : 'Henüz bildirimin yok.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (_) async {
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Bildirimi sil'),
              content: const Text(
                'Bu bildirimi silmek istediğine emin misin?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Sil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );

        return shouldDelete == true;
      },
      onDismissed: (_) async {
        await deleteSingleNotification(notification);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade200
                : Colors.deepPurple.shade100,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: notification.isRead ? 8 : 14,
              color: Colors.black.withOpacity(notification.isRead ? 0.05 : 0.08),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            markSingleAsRead(notification);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            notification.title.isEmpty
                                ? 'Bildirim'
                                : notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.w700
                                  : FontWeight.bold,
                              height: 1.25,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              getNotificationTypeText(notification.type),
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.message.isEmpty
                            ? 'Bildirim detayı bulunmuyor.'
                            : notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.grey.shade800,
                          fontWeight: notification.isRead
                              ? FontWeight.w400
                              : FontWeight.w600,
                        ),
                      ),
                      if (formattedDate.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 15,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!notification.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: Colors.grey.shade400,
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.62,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.deepPurple.shade50,
                  child: const Icon(
                    Icons.notifications_off_outlined,
                    size: 44,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Henüz bildirimin yok',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Yeni seans, iptal ve sistem bildirimleri burada görünecek.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildErrorState(Object? error) {
    return RefreshIndicator(
      onRefresh: refreshNotifications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.62,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 56,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bildirimler yüklenemedi',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: refreshNotifications,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildNotificationsList(List<NotificationModel> notifications) {
    return RefreshIndicator(
      onRefresh: refreshNotifications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          buildHeaderCard(notifications),
          const SizedBox(height: 8),
          ...notifications.map(buildNotificationCard),
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
            onPressed: isProcessing ? null : markAllAsRead,
            tooltip: 'Tümünü okundu yap',
            icon: const Icon(Icons.done_all),
          ),
          IconButton(
            onPressed: isProcessing ? null : deleteAllNotifications,
            tooltip: 'Tümünü sil',
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return buildErrorState(snapshot.error);
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return buildEmptyState();
          }

          return buildNotificationsList(notifications);
        },
      ),
    );
  }
}