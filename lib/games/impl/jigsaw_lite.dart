import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../game_shell.dart';
import '../../theme/app_theme.dart';

class JigsawLiteGame extends StatefulWidget {
  const JigsawLiteGame({super.key});

  @override
  State<JigsawLiteGame> createState() => _JigsawLiteGameState();
}

class _JigsawLiteGameState extends State<JigsawLiteGame> {
  static const _solution = [0, 1, 2, 3];
  late List<int> _slots;
  int? _held;
  bool _won = false;

  static const _tints = [
    Color(0xFFFECACA),
    Color(0xFFBFDBFE),
    Color(0xFFBBF7D0),
    Color(0xFFFDE68A),
  ];

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _slots = List.from(_solution)..shuffle(Random());
    setState(() {
      _held = null;
      _won = false;
    });
  }

  void _tap(int i) {
    if (_won) return;
    setState(() {
      if (_held == null) {
        _held = i;
      } else {
        final t = _slots[_held!];
        _slots[_held!] = _slots[i];
        _slots[i] = t;
        _held = null;
        _won = listEquals(_slots, _solution);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Jigsaw Lite',
      onReset: _reset,
      child: Column(
        children: [
          if (_won) gameWinBanner('Picture complete!'),
          if (_won) const SizedBox(height: 12),
          Text(
            _held == null ? 'Tap two pieces to swap them.' : 'Tap another piece to swap.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, color: AppColors.slate600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: 4,
                itemBuilder: (_, i) {
                  final piece = _slots[i];
                  final selected = _held == i;
                  return Material(
                    color: _tints[piece],
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _tap(i),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppColors.brand600 : Colors.black87,
                            width: selected ? 4 : 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${piece + 1}',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
