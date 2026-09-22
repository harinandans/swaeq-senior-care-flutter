import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

void showAppToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

class LeafBackground extends StatelessWidget {
  const LeafBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F4FF),
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.2,
          colors: [Color(0xFFEDE4FF), Color(0xFFF8F4FF)],
        ),
      ),
      // Force full device width — DecoratedBox otherwise shrinks to the child.
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Swa',
            style: GoogleFonts.dmSans(
              fontSize: size,
              fontWeight: FontWeight.w800,
              color: AppColors.brand900,
            ),
          ),
          TextSpan(
            text: 'EQ',
            style: GoogleFonts.dmSans(
              fontSize: size,
              fontWeight: FontWeight.w800,
              color: AppColors.brand600,
            ),
          ),
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand500.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return box;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: box,
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Text(label),
    );
  }
}

class LoadingBody extends StatelessWidget {
  const LoadingBody({super.key, this.message = 'Loading…'});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.brand600),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.slate400)),
        ],
      ),
    );
  }
}

class ErrorBody extends StatelessWidget {
  const ErrorBody({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

String todayIstDate() {
  final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

String fmtHeight(dynamic h) {
  if (h is! Map) return '—';
  final unit = h['unit'];
  final value = h['value'];
  if (value == null) return '—';
  if (unit == 'ft_in') {
    final total = (value as num).round();
    return '${total ~/ 12} ft ${total % 12} in';
  }
  return '$value ${unit ?? 'cm'}';
}

Map<String, dynamic>? heightFromFtIn(String ft, String inch) {
  final f = int.tryParse(ft);
  final i = int.tryParse(inch) ?? 0;
  if (f == null || f < 1) return null;
  return {'value': f * 12 + i, 'unit': 'ft_in'};
}

/// Color-coded icons used across Tracker / Reminders (matches design mockups).
({IconData icon, Color bg, Color fg}) categoryStyle(String? type) {
  switch (type) {
    case 'water':
      return (
        icon: Icons.water_drop,
        bg: const Color(0xFFE0F2FE),
        fg: const Color(0xFF0284C7),
      );
    case 'medicine':
      return (
        icon: Icons.medication,
        bg: const Color(0xFFF3E8FF),
        fg: AppColors.brand700,
      );
    case 'food':
      return (
        icon: Icons.restaurant,
        bg: const Color(0xFFFFEDD5),
        fg: const Color(0xFFEA580C),
      );
    case 'exercise':
      return (
        icon: Icons.directions_walk,
        bg: const Color(0xFFDCFCE7),
        fg: const Color(0xFF16A34A),
      );
    case 'custom':
      return (
        icon: Icons.notifications_active_outlined,
        bg: AppColors.brand100,
        fg: AppColors.brand700,
      );
    default:
      return (
        icon: Icons.favorite_outline,
        bg: AppColors.brand100,
        fg: AppColors.brand700,
      );
  }
}

class PrivacyBanner extends StatelessWidget {
  const PrivacyBanner({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brand50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined,
              color: AppColors.brand600, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.slate600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
