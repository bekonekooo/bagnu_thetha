import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/core/services/supabase_service.dart';

import '../models/notification_model.dart';

class NotificationService {
  Future<List<NotificationModel>> fetchMyNotifications() async {
    final user = supabase.auth.currentUser;

    // DEBUG:
    // debugPrint('NOTIFICATION CURRENT USER ID: ${user?.id}');
    // debugPrint('NOTIFICATION CURRENT USER EMAIL: ${user?.email}');

    if (user == null) {
      throw Exception('User not logged in');
    }

    final response = await supabase
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    // DEBUG:
    // debugPrint('NOTIFICATION RESPONSE: $response');

    return (response as List)
        .map((item) => NotificationModel.fromMap(item))
        .toList();
  }

  Future<int> fetchUnreadCount() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return 0;
    }

    final response = await supabase
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .eq('is_read', false);

    return (response as List).length;
  }

  Future<void> markAsRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_read', false);
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'info',
  }) async {
    await supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': false,
    });
  }

  RealtimeChannel subscribeToMyNotifications({
    required VoidCallback onChange,
  }) {
    final user = supabase.auth.currentUser;

    // DEBUG:
    // debugPrint('REALTIME NOTIFICATION USER ID: ${user?.id}');
    // debugPrint('REALTIME NOTIFICATION USER EMAIL: ${user?.email}');

    if (user == null) {
      throw Exception('User not logged in');
    }

    final channel = supabase.channel('my-notifications-${user.id}');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: user.id,
      ),
      callback: (payload) {
        // DEBUG:
        // debugPrint('Notification realtime: ${payload.eventType}');
        // debugPrint('Notification payload: ${payload.newRecord}');

        onChange();
      },
    );

    channel.subscribe((status, [error]) {
      // DEBUG:
      // debugPrint('Notification realtime status: $status');
      // if (error != null) {
      //   debugPrint('Notification realtime error: $error');
      // }
    });

    return channel;
  }

  Future<void> removeChannel(RealtimeChannel channel) async {
    await supabase.removeChannel(channel);
  }
}