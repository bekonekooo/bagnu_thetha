import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final String fullName;
  final String email;

  const HomeHeader({
    super.key,
    required this.fullName,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}