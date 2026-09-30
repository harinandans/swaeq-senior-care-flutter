import 'dart:math';

import 'package:flutter/material.dart';

import '../game_shell.dart';
import '../../theme/app_theme.dart';

class MahjongLiteGame extends StatefulWidget {
  const MahjongLiteGame({super.key});

  @override
  State<MahjongLiteGame> createState() => _MahjongLiteGameState();
}

class _MahjongLiteGameState extends State<MahjongLiteGame> {
  static const _symbols = ['🌸', '🍃', '☀️'];

  late List<int> _tiles;
  final _gone = <int>{};
  int? _first;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _tiles = [0, 0, 1, 1, 2, 2]..shuffle(Random());
    setState(() {
      _gone.clear();
      _first = null;
      _won = false;
    });
  }

  void _tap(int i) {
    if (_won || _gone.contains(i)) return;
    setState(() {
      if (_first == null) {
        _first = i;
        return;
      }
      if (_first == i) {
        _first = null;
        return;
      }
      if (_tiles[_first!] == _tiles[i]) {
        _gone.add(_first!);
        _gone.add(i);
        if (_gone.length == _tiles.length) _won = true;
      }
      _first = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Mahjong Lite',
      onReset: _reset,
      child: Column(
        children: [
          if (_won) gameWinBanner('All pairs cleared!'),
          if (_won) const SizedBox(height: 12),
          const Text(
            'Tap two matching tiles to remove them.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: AppColors.slate600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: _tiles.length,
              itemBuilder: (_, i) {
                if (_gone.contains(i)) {
                  return const SizedBox.shrink();
                }
                final sel = _first == i;
                return Material(
                  color: AppColors.brand50,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => _tap(i),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 72, minWidth: 72),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sel ? AppColors.brand600 : AppColors.slate400,
                          width: sel ? 3 : 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(_symbols[_tiles[i]], style: const TextStyle(fontSize: 36)),
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
