import 'dart:math';

import 'package:flutter/material.dart';

import '../game_shell.dart';
import '../../theme/app_theme.dart';

class NumberOrderGame extends StatefulWidget {
  const NumberOrderGame({super.key});

  @override
  State<NumberOrderGame> createState() => _NumberOrderGameState();
}

class _NumberOrderGameState extends State<NumberOrderGame> {
  late List<int> _nums;
  int _next = 1;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _nums = List.generate(9, (i) => i + 1)..shuffle(Random());
    setState(() {
      _next = 1;
      _won = false;
    });
  }

  void _tap(int n) {
    if (_won || n != _next) return;
    setState(() {
      _next++;
      if (_next > 9) _won = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Number Order',
      onReset: _reset,
      child: Column(
        children: [
          if (_won) gameWinBanner('1 through 9 — perfect!'),
          if (_won) const SizedBox(height: 12),
          Text(
            'Tap numbers in order. Next: $_next',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: 9,
              itemBuilder: (_, i) {
                final n = _nums[i];
                final done = n < _next;
                return FilledButton(
                  onPressed: done ? null : () => _tap(n),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(72, 72),
                    backgroundColor: done ? AppColors.slate300 : AppColors.brand600,
                    disabledBackgroundColor: AppColors.slate200,
                  ),
                  child: Text(
                    '$n',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
