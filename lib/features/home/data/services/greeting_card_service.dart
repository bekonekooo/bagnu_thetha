import 'package:flutter_application_1/core/services/supabase_service.dart';

class GreetingCardService {
  Future<String?> fetchNextGreetingMessage() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    final response = await supabase.rpc(
      'get_next_greeting_card',
      params: {
        'p_user_id': user.id,
      },
    );

    if (response is List && response.isNotEmpty) {
      final firstItem = response.first;

      if (firstItem is Map && firstItem['message'] != null) {
        return firstItem['message'].toString();
      }
    }

    return null;
  }
}