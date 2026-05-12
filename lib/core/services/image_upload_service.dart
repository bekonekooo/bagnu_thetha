import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class ImageUploadService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndUploadAvatar({
    required String folderName,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 900,
    );

    if (pickedImage == null) {
      return null;
    }

    final bytes = await pickedImage.readAsBytes();

    final extension = pickedImage.name.split('.').last.toLowerCase();

    final safeExtension = extension == 'png' ||
            extension == 'jpg' ||
            extension == 'jpeg' ||
            extension == 'webp'
        ? extension
        : 'jpg';

    final contentType = safeExtension == 'png'
        ? 'image/png'
        : safeExtension == 'webp'
            ? 'image/webp'
            : 'image/jpeg';

    final filePath =
        '$folderName/${user.id}-${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

    await supabase.storage.from('avatars').uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

    final publicUrl = supabase.storage.from('avatars').getPublicUrl(filePath);

    return publicUrl;
  }
}