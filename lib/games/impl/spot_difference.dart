import 'package:flutter/material.dart';

import '../game_shell.dart';
import '../../theme/app_theme.dart';

class SpotDifferenceGame extends StatefulWidget {
  const SpotDifferenceGame({super.key});

  @override
  State<SpotDifferenceGame> createState() => _SpotDifferenceGameState();
}

class _SpotDifferenceGameState extends State<SpotDifferenceGame> {
  bool _found = false;

  void _reset() {
    setState(() => _found = false);
  }

  void _tapDiff() {
    if (_found) return;
    setState(() => _found = true);
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Spot the Difference',
      onReset: _reset,
      child: Column(
        children: [
          if (_found) gameWinBanner('You spotted the blue bird!'),
          if (_found) const SizedBox(height: 12),
          const Text(
            'The right picture has one extra item. Tap it.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: AppColors.slate600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _Scene(showBird: false, onWrong: () {})),
                const SizedBox(width: 8),
                Expanded(child: _Scene(showBird: true, onBird: _tapDiff)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Scene extends StatelessWidget {
  const _Scene({this.showBird = false, this.onBird, this.onWrong});

  final bool showBird;
  final VoidCallback? onBird;
  final VoidCallback? onWrong;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate400, width: 2),
      ),
      child: Stack(
        children: [
          const Positioned(left: 12, bottom: 20, child: Icon(Icons.park, size: 48, color: Color(0xFF166534))),
          const Positioned(right: 16, bottom: 24, child: Icon(Icons.home, size: 44, color: Color(0xFF92400E))),
          const Positioned(left: 40, top: 30, child: Icon(Icons.wb_sunny, size: 40, color: Color(0xFFF59E0B))),
          Positioned.fill(
            child: GestureDetector(
              onTap: onWrong,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          if (showBird)
            Positioned(
              right: 24,
              top: 36,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBird,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    child: const Icon(Icons.flutter_dash, size: 36, color: Color(0xFF2563EB)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
