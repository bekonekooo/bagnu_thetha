import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../../core/services/supabase_service.dart';

class PaymentService {
  Future<Map<String, dynamic>> createPaymentIntent({
    required String teacherId,
    required String teacherName,
    required DateTime sessionDate,
    required String sessionTime,
    required double amount,
    required String currency,
    String? notes,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Ödeme için giriş yapmalısın.');
    }

    final sessionDateForDb = _formatDateForDb(sessionDate);

   final response = await supabase.functions.invoke(
  'dynamic-action',
  body: {
        'teacherId': teacherId,
        'teacherName': teacherName,
        'sessionDate': sessionDateForDb,
        'sessionTime': sessionTime,
        'amount': amount,
        'currency': currency,
        'notes': notes,
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('Ödeme başlatılamadı. Geçersiz cevap alındı.');
    }

    final result = Map<String, dynamic>.from(data);

    if (result['error'] != null) {
      throw Exception(result['error'].toString());
    }

    final clientSecret = result['clientSecret']?.toString();

    if (clientSecret == null || clientSecret.isEmpty) {
      throw Exception('Stripe client secret alınamadı.');
    }

    return result;
  }

  Future<void> openPaymentSheet({
    required String clientSecret,
  }) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'BagnuTheta',
        style: ThemeMode.system,
        allowsDelayedPaymentMethods: false,
      ),
    );

    await Stripe.instance.presentPaymentSheet();
  }

  Future<void> markPaymentSucceeded({
    required String paymentId,
  }) async {
    await supabase
        .from('payments')
        .update({
          'status': 'succeeded',
        })
        .eq('id', paymentId)
        .eq('status', 'pending');
  }

  String _formatDateForDb(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}