import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/profile/data/services/profile_service.dart';

class PlusAccessService {
  final ProfileService _profileService = ProfileService();

  Future<bool> isSubscriptionActive() {
    return _profileService.isMySubscriptionActive();
  }

  Future<bool> ensureAccess(
    BuildContext context, {
    required bool isPlusOnly,
  }) async {
    if (!isPlusOnly) return true;

    try {
      final isActive = await isSubscriptionActive();

      if (isActive) return true;
      if (!context.mounted) return false;

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFFFFFDF9),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7E1D0),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const CircleAvatar(
                    radius: 31,
                    backgroundColor: Color(0xFFEEF3EA),
                    child: Icon(
                      Icons.workspace_premium_outlined,
                      color: Color(0xFF536B4E),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Bu içerik Plus’a özel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF2F3A32),
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bu içeriği açmak için aktif bir Plus aboneliğin olmalı.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF606A61),
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        context.push('/subscription-terms');
                      },
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Plus hakkında bilgi al'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF536B4E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Şimdi değil'),
                  ),
                ],
              ),
            ),
          );
        },
      );

      return false;
    } catch (_) {
      if (!context.mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plus erişimi doğrulanamadı. Lütfen tekrar dene.'),
        ),
      );
      return false;
    }
  }
}
