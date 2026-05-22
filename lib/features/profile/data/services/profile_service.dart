import 'package:flutter_application_1/core/services/supabase_service.dart';

class ProfileService {
  Future<Map<String, dynamic>> fetchMyProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return response;
  }

  Future<Map<String, dynamic>> fetchMySubscriptionInfo() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final response = await supabase
        .from('profiles')
        .select(
          'is_subscribed, subscription_plan, subscription_started_at, subscription_ends_at',
        )
        .eq('id', user.id)
        .single();

    return response;
  }

  Future<bool> isMySubscriptionActive() async {
    final profile = await fetchMySubscriptionInfo();

    final isSubscribed = profile['is_subscribed'] == true;
    final endsAtValue = profile['subscription_ends_at'];

    if (!isSubscribed) {
      return false;
    }

    if (endsAtValue == null) {
      return true;
    }

    final endsAt = DateTime.tryParse(endsAtValue.toString());

    if (endsAt == null) {
      return false;
    }

    return endsAt.isAfter(DateTime.now());
  }

  Future<String> fetchMySubscriptionPlan() async {
    final profile = await fetchMySubscriptionInfo();

    final plan = profile['subscription_plan'];

    if (plan == null || plan.toString().trim().isEmpty) {
      return 'free';
    }

    return plan.toString();
  }

  Future<void> updateMyProfile({
    required String fullName,
    required String phone,
    required String bio,
    required String imageUrl,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    await supabase
        .from('profiles')
        .update({
          'full_name': fullName,
          'phone': phone,
          'bio': bio,
          'image_url': imageUrl,
        })
        .eq('id', user.id);
  }
}