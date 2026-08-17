import 'package:flutter/material.dart';

class SocialAuthButtons extends StatelessWidget {
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final bool isLoading;
  final String? loadingLabel;

  const SocialAuthButtons({
    super.key,
    required this.onGoogle,
    required this.onApple,
    required this.isLoading,
    this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'veya',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 14),
        _SocialButton(
          label: loadingLabel == 'Google ile devam ediliyor...'
              ? loadingLabel!
              : 'Google ile devam et',
          icon: const Text(
            'G',
            style: TextStyle(
              color: Color(0xFF4285F4),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          onPressed: isLoading ? null : onGoogle,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF18202A),
          borderColor: const Color(0xFFE5DED3),
        ),
        const SizedBox(height: 10),
        _SocialButton(
          label: loadingLabel == 'Apple ile devam ediliyor...'
              ? loadingLabel!
              : 'Apple ile devam et',
          icon: const Icon(Icons.apple, size: 22),
          onPressed: isLoading ? null : onApple,
          backgroundColor: const Color(0xFF18202A),
          foregroundColor: Colors.white,
          borderColor: const Color(0xFF18202A),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label),
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
