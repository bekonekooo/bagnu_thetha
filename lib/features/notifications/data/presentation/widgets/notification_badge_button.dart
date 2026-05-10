import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/services/notification_service.dart';

class NotificationBadgeButton extends StatefulWidget {
  const NotificationBadgeButton({super.key});

  @override
  State<NotificationBadgeButton> createState() =>
      _NotificationBadgeButtonState();
}

class _NotificationBadgeButtonState
    extends State<NotificationBadgeButton> {
  final NotificationService notificationService =
      NotificationService();

  int unreadCount = 0;

  RealtimeChannel? notificationChannel;

  @override
  void initState() {
    super.initState();

    loadUnreadCount();
    subscribeToNotifications();
  }

  Future<void> loadUnreadCount() async {
    final count = await notificationService.fetchUnreadCount();

    if (!mounted) return;

    setState(() {
      unreadCount = count;
    });
  }

  void subscribeToNotifications() {
    notificationChannel =
        notificationService.subscribeToMyNotifications(
      onChange: () async {
        await loadUnreadCount();
      },
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () async {
            await context.push('/notifications');

            loadUnreadCount();
          },
          icon: const Icon(Icons.notifications),
        ),

        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                unreadCount > 99
                    ? '99+'
                    : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}