import 'dart:math';

import 'package:flutter/material.dart';

import '../game_shell.dart';
import '../../theme/app_theme.dart';

class MemoryMatchGame extends StatefulWidget {
  const MemoryMatchGame({super.key});

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  static const _icons = [
    Icons.local_florist,
    Icons.eco,
    Icons.wb_sunny,
    Icons.water_drop,
  ];

  late List<int> _deck;
  final _revealed = <int>{};
  int? _first;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    final pairs = [...List.generate(4, (i) => i), ...List.generate(4, (i) => i)];
    pairs.shuffle(Random());
    setState(() {
      _deck = pairs;
      _revealed.clear();
      _first = null;
      _won = false;
    });
  }

  void _tap(int i) {
    if (_won || _revealed.contains(i) || _first == i) return;
    setState(() {
      if (_first == null) {
        _first = i;
        return;
      }
      final a = _first!;
      _first = null;
      if (_deck[a] == _deck[i]) {
        _revealed.add(a);
        _revealed.add(i);
        if (_revealed.length == _deck.length) _won = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Memory Match',
      onReset: _reset,
      child: Column(
        children: [
          if (_won) gameWinBanner('Every pair found!'),
          if (_won) const SizedBox(height: 12),
          const Text(
            'Tap two cards to find matching flowers.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: AppColors.slate600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: _deck.length,
              itemBuilder: (_, i) {
                final show = _revealed.contains(i) || _first == i;
                return Material(
                  color: show ? Colors.white : AppColors.brand100,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => _tap(i),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56, minWidth: 56),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.brand600, width: 2),
                      ),
                      child: Center(
                        child: show
                            ? Icon(_icons[_deck[i]], size: 36, color: AppColors.brand700)
                            : const Icon(Icons.help_outline, size: 32, color: AppColors.slate500),
                      ),
                    ),
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
