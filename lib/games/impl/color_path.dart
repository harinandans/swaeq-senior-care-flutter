import 'package:flutter/material.dart';

import '../game_shell.dart';
import '../../theme/app_theme.dart';

class ColorPathGame extends StatefulWidget {
  const ColorPathGame({super.key});

  @override
  State<ColorPathGame> createState() => _ColorPathGameState();
}

class _ColorPathGameState extends State<ColorPathGame> {
  static const _size = 5;
  static const _pairs = {
    1: Color(0xFFE11D48),
    2: Color(0xFF2563EB),
  };

  // cell -> color id (0 empty)
  late List<List<int>> _grid;
  int? _activeColor;
  Point? _cursor;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _grid = List.generate(_size, (_) => List.filled(_size, 0));
    // endpoints
    _grid[0][0] = 1;
    _grid[4][4] = 1;
    _grid[0][4] = 2;
    _grid[4][0] = 2;
    setState(() {
      _activeColor = null;
      _cursor = null;
      _won = false;
    });
  }

  bool _connected(int color) {
    final start = _findEndpoint(color);
    if (start == null) return false;
    final target = color == 1 ? const Point(4, 4) : const Point(4, 0);
    final seen = <String>{};
    void dfs(int r, int c) {
      seen.add('$r,$c');
      if (r == target.row && c == target.col) return;
      for (final d in const [Point(0, 1), Point(0, -1), Point(1, 0), Point(-1, 0)]) {
        final nr = r + d.row, nc = c + d.col;
        if (nr < 0 || nr >= _size || nc < 0 || nc >= _size) continue;
        if (_grid[nr][nc] != color) continue;
        if (seen.contains('$nr,$nc')) continue;
        dfs(nr, nc);
      }
    }

    dfs(start.row, start.col);
    return seen.contains('${target.row},${target.col}');
  }

  Point? _findEndpoint(int color) {
    for (var r = 0; r < _size; r++) {
      for (var c = 0; c < _size; c++) {
        if (_grid[r][c] == color && (r + c == 0 || (color == 2 && r == 0 && c == 4))) {
          return Point(r, c);
        }
      }
    }
    if (color == 1) return const Point(0, 0);
    return const Point(0, 4);
  }

  void _tap(int r, int c) {
    if (_won) return;
    final cell = _grid[r][c];
    setState(() {
      if (cell == 1 || cell == 2) {
        _activeColor = cell;
        _cursor = Point(r, c);
        _clearPath(cell, keepEndpoints: true);
        return;
      }
      if (_activeColor == null) return;
      if (_cursor == null) return;
      if (!_isAdjacent(_cursor!, Point(r, c))) return;
      if (cell != 0 && cell != _activeColor) return;
      _grid[r][c] = _activeColor!;
      _cursor = Point(r, c);
      if (_connected(1) && _connected(2)) _won = true;
    });
  }

  void _clearPath(int color, {required bool keepEndpoints}) {
    for (var r = 0; r < _size; r++) {
      for (var c = 0; c < _size; c++) {
        if (_grid[r][c] != color) continue;
        final isEnd = (color == 1 && r == 0 && c == 0) ||
            (color == 1 && r == 4 && c == 4) ||
            (color == 2 && r == 0 && c == 4) ||
            (color == 2 && r == 4 && c == 0);
        if (keepEndpoints && isEnd) continue;
        _grid[r][c] = 0;
      }
    }
  }

  bool _isAdjacent(Point a, Point b) =>
      (a.row - b.row).abs() + (a.col - b.col).abs() == 1;

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Colour Path',
      onReset: _reset,
      child: Column(
        children: [
          if (_won) gameWinBanner('Both paths connected!'),
          if (_won) const SizedBox(height: 12),
          const Text(
            'Tap a dot, then tap neighbouring squares to draw each path.',
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
                  Color bg = Colors.white;
                  if (v == 1) bg = _pairs[1]!;
                  if (v == 2) bg = _pairs[2]!;
                  return Material(
                    color: bg,
                    child: InkWell(
                      onTap: () => _tap(r, c),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.slate400, width: 1.5),
                        ),
                        child: v == 0
                            ? null
                            : Center(
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black87, width: 2),
                                  ),
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

class Point {
  const Point(this.row, this.col);
  final int row;
  final int col;
}
