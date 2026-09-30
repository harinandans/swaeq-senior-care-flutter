import 'package:flutter/material.dart';

import '../game_shell.dart';
import '../../theme/app_theme.dart';

class BubblePopGame extends StatefulWidget {
  const BubblePopGame({super.key});

  @override
  State<BubblePopGame> createState() => _BubblePopGameState();
}

class _BubblePopGameState extends State<BubblePopGame> {
  static const _size = 5;
  static const _palette = [
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
  ];

  late List<List<int>> _grid;
  final _history = <List<List<int>>>[];
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    // Fixed gentle board with clear pop groups (winnable in a few taps).
    _grid = [
      [0, 0, 1, 1, 2],
      [0, 0, 1, 3, 2],
      [3, 3, 3, 2, 2],
      [1, 1, 0, 0, 3],
      [2, 2, 1, 3, 3],
    ];
    setState(() {
      _history.clear();
      _won = false;
    });
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _grid = _history.removeLast();
      _won = _isCleared();
    });
  }

  bool _isCleared() => _grid.every((row) => row.every((c) => c < 0));

  void _pop(int r, int c) {
    if (_won || _grid[r][c] < 0) return;
    final color = _grid[r][c];
    final stack = <Point>[Point(r, c)];
    final cluster = <Point>[];
    final seen = <String>{};
    while (stack.isNotEmpty) {
      final p = stack.removeLast();
      if (!seen.add('${p.row},${p.col}')) continue;
      if (_grid[p.row][p.col] != color) continue;
      cluster.add(p);
      for (final d in const [Point(0, 1), Point(0, -1), Point(1, 0), Point(-1, 0)]) {
        final nr = p.row + d.row, nc = p.col + d.col;
        if (nr >= 0 && nr < _size && nc >= 0 && nc < _size) {
          stack.add(Point(nr, nc));
        }
      }
    }
    if (cluster.length < 2) return;
    _history.add(_grid.map((row) => List<int>.from(row)).toList());
    setState(() {
      for (final p in cluster) {
        _grid[p.row][p.col] = -1;
      }
      _won = _isCleared();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Bubble Pop',
      onReset: _reset,
      footer: _history.isNotEmpty
          ? TextButton.icon(
              onPressed: _undo,
              icon: const Icon(Icons.undo_rounded, size: 26),
              label: const Text('Undo', style: TextStyle(fontSize: 17)),
            )
          : null,
      child: Column(
        children: [
          if (_won) gameWinBanner('Board cleared!'),
          if (_won) const SizedBox(height: 12),
          const Text(
            'Tap a group of 2+ matching colours to pop them.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.slate600),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _size,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: _size * _size,
                itemBuilder: (_, i) {
                  final r = i ~/ _size, c = i % _size;
                  final v = _grid[r][c];
                  return Material(
                    color: v < 0 ? AppColors.slate100 : _palette[v],
                    child: InkWell(
                      onTap: () => _pop(r, c),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.slate500),
                          shape: BoxShape.circle,
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

class Point {
  const Point(this.row, this.col);
  final int row;
  final int col;
}
