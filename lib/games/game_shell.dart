import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// Shared chrome for senior games: large back, reset, calm background.
class GameShell extends StatelessWidget {
  const GameShell({
    super.key,
    required this.title,
    required this.child,
    this.onReset,
    this.footer,
  });

  final String title;
  final Widget child;
  final VoidCallback? onReset;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        actions: [
          if (onReset != null)
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, size: 26),
              label: const Text('Reset', style: TextStyle(fontSize: 17)),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: child),
              if (footer != null) ...[
                const SizedBox(height: 12),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Widget gameWinBanner(String message) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.brand50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.brand600, width: 2),
    ),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.brand900,
      ),
    ),
  );
}
