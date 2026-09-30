import 'dart:math';

import 'package:flutter/material.dart';

import '../game_shell.dart';
import '../../theme/app_theme.dart';

class SlidingPuzzleGame extends StatefulWidget {
  const SlidingPuzzleGame({super.key});

  @override
  State<SlidingPuzzleGame> createState() => _SlidingPuzzleGameState();
}

class _SlidingPuzzleGameState extends State<SlidingPuzzleGame> {
  static const _size = 3;
  late List<int> _tiles;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _tiles = List.generate(9, (i) => i);
    final rng = Random();
    for (var n = 0; n < 40; n++) {
      final empty = _tiles.indexOf(0);
      final er = empty ~/ _size, ec = empty % _size;
      final moves = <int>[];
      if (er > 0) moves.add(_tiles[empty - _size]);
      if (er < _size - 1) moves.add(_tiles[empty + _size]);
      if (ec > 0) moves.add(_tiles[empty - 1]);
      if (ec < _size - 1) moves.add(_tiles[empty + 1]);
      final pick = moves[rng.nextInt(moves.length)];
      _tap(_tiles.indexOf(pick), silent: true);
    }
    setState(() => _won = false);
  }

  void _tap(int i, {bool silent = false}) {
    if (_won) return;
    final empty = _tiles.indexOf(0);
    final r = i ~/ _size, c = i % _size;
    final er = empty ~/ _size, ec = empty % _size;
    final adj = (r - er).abs() + (c - ec).abs() == 1;
    if (!adj) return;
    setState(() {
      _tiles[empty] = _tiles[i];
      _tiles[i] = 0;
      if (!silent) _won = listEquals(_tiles, List.generate(9, (i) => i));
    });
  }

  bool listEquals(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Sliding Puzzle',
      onReset: _reset,
      child: Column(
        children: [
          if (_won) gameWinBanner('Tiles in order — well done!'),
          if (_won) const SizedBox(height: 12),
          const Text(
            'Slide tiles into the empty space to order 1–8.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.slate600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _size,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: 9,
                itemBuilder: (_, i) {
                  final v = _tiles[i];
                  if (v == 0) {
                    return Container(color: AppColors.slate100);
                  }
                  return FilledButton(
                    onPressed: () => _tap(i),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(64, 64),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      '$v',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
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
