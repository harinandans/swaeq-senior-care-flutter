import 'package:flutter/material.dart';

import '../game_shell.dart';
import '../../theme/app_theme.dart';

class WordSearchGame extends StatefulWidget {
  const WordSearchGame({super.key});

  @override
  State<WordSearchGame> createState() => _WordSearchGameState();
}

class _WordSearchGameState extends State<WordSearchGame> {
  static const _size = 6;
  static const _words = ['CALM', 'REST', 'SUN'];
  static const _gridLetters = [
    ['C', 'A', 'L', 'M', 'X', 'P'],
    ['Q', 'R', 'E', 'S', 'T', 'L'],
    ['S', 'U', 'N', 'Z', 'Y', 'K'],
    ['M', 'N', 'B', 'V', 'C', 'J'],
    ['H', 'G', 'F', 'D', 'S', 'A'],
    ['W', 'E', 'R', 'T', 'Y', 'U'],
  ];

  final _found = <String>{};
  int? _start;
  int? _end;

  bool get _won => _found.length == _words.length;

  void _reset() {
    setState(() {
      _found.clear();
      _start = null;
      _end = null;
    });
  }

  int _idx(int r, int c) => r * _size + c;

  void _tap(int r, int c) {
    if (_won) return;
    final i = _idx(r, c);
    setState(() {
      if (_start == null) {
        _start = i;
        _end = i;
      } else {
        _end = i;
        _checkSelection();
        _start = null;
        _end = null;
      }
    });
  }

  void _checkSelection() {
    if (_start == null || _end == null) return;
    final sr = _start! ~/ _size, sc = _start! % _size;
    final er = _end! ~/ _size, ec = _end! % _size;
    if (sr != er && sc != ec) return;
    final letters = <String>[];
    if (sr == er) {
      final lo = sc < ec ? sc : ec;
      final hi = sc < ec ? ec : sc;
      for (var c = lo; c <= hi; c++) letters.add(_gridLetters[sr][c]);
    } else {
      final lo = sr < er ? sr : er;
      final hi = sr < er ? er : sr;
      for (var r = lo; r <= hi; r++) letters.add(_gridLetters[r][sc]);
    }
    final word = letters.join();
    final rev = letters.reversed.join();
    for (final w in _words) {
      if ((word == w || rev == w) && !_found.contains(w)) _found.add(w);
    }
  }

  bool _cellHighlighted(int r, int c) {
    if (_start == null || _end == null) return false;
    final sr = _start! ~/ _size, sc = _start! % _size;
    final er = _end! ~/ _size, ec = _end! % _size;
    if (sr == er && r == sr) {
      final lo = sc < ec ? sc : ec;
      final hi = sc < ec ? ec : sc;
      return c >= lo && c <= hi;
    }
    if (sc == ec && c == sc) {
      final lo = sr < er ? sr : er;
      final hi = sr < er ? er : sr;
      return r >= lo && r <= hi;
    }
    return _start == _idx(r, c);
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Word Search',
      onReset: _reset,
      child: Column(
        children: [
          if (_won) gameWinBanner('All calm words found!'),
          if (_won) const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.center,
            children: _words.map((w) {
              final done = _found.contains(w);
              return Chip(
                label: Text(w, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                backgroundColor: done ? AppColors.brand100 : AppColors.slate100,
                side: BorderSide(color: done ? AppColors.brand600 : AppColors.slate300, width: 2),
              );
            }).toList(),
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
                  final hi = _cellHighlighted(r, c);
                  return Material(
                    color: hi ? AppColors.brand200 : Colors.white,
                    child: InkWell(
                      onTap: () => _tap(r, c),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.slate400),
                        ),
                        child: Text(
                          _gridLetters[r][c],
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
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
