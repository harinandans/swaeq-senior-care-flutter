import 'package:flutter/material.dart';

import '../game_shell.dart';
import '../../theme/app_theme.dart';

class CalmColoringGame extends StatefulWidget {
  const CalmColoringGame({super.key});

  @override
  State<CalmColoringGame> createState() => _CalmColoringGameState();
}

class _CalmColoringGameState extends State<CalmColoringGame> {
  static const _palette = [
    Color(0xFFF472B6),
    Color(0xFF60A5FA),
    Color(0xFF4ADE80),
    Color(0xFFFBBF24),
  ];

  int _brush = 0;
  final _regions = List<int>.filled(4, -1);

  bool get _won => _regions.every((c) => c >= 0);

  void _reset() {
    setState(() {
      _brush = 0;
      for (var i = 0; i < _regions.length; i++) {
        _regions[i] = -1;
      }
    });
  }

  void _paintRegion(int i) {
    setState(() => _regions[i] = _brush);
  }

  Color _regionColor(int i) {
    if (_regions[i] >= 0) return _palette[_regions[i]];
    return AppColors.slate100;
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Calm Coloring',
      onReset: _reset,
      child: Column(
        children: [
          if (_won) gameWinBanner('Your flower is complete!'),
          if (_won) const SizedBox(height: 12),
          const Text(
            'Pick a colour, then tap each petal.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: AppColors.slate600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(_palette.length, (i) {
              final sel = _brush == i;
              return Material(
                color: _palette[i],
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _brush = i),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? Colors.black : Colors.white,
                        width: sel ? 4 : 2,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Transform.rotate(
                        angle: i * 1.5708,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: _Petal(
                            color: _regionColor(i),
                            onTap: () => _paintRegion(i),
                          ),
                        ),
                      ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brand100,
                        border: Border.all(color: Colors.black87, width: 2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Petal extends StatelessWidget {
  const _Petal({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 88,
          height: 88,
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.black87, width: 2),
          ),
        ),
      ),
    );
  }
}
