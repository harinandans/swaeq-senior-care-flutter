import 'package:flutter/material.dart';

import '../game_shell.dart';
import '../../theme/app_theme.dart';

class SudokuEasyGame extends StatefulWidget {
  const SudokuEasyGame({super.key});

  @override
  State<SudokuEasyGame> createState() => _SudokuEasyGameState();
}

class _SudokuEasyGameState extends State<SudokuEasyGame> {
  static const _solution = [
    [1, 2, 3, 4],
    [3, 4, 1, 2],
    [2, 1, 4, 3],
    [4, 3, 2, 1],
  ];

  static const _fixed = {
    '0,0': 1,
    '0,3': 4,
    '1,1': 4,
    '2,2': 4,
    '3,0': 4,
    '3,3': 1,
  };

  late List<List<int>> _board;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = List.generate(4, (_) => List.filled(4, 0));
    _fixed.forEach((k, v) {
      final p = k.split(',');
      _board[int.parse(p[0])][int.parse(p[1])] = v;
    });
    setState(() => _won = false);
  }

  void _tap(int r, int c) {
    if (_won || _fixed.containsKey('$r,$c')) return;
    setState(() {
      final n = (_board[r][c] % 4) + 1;
      _board[r][c] = n;
      _won = _isComplete();
    });
  }

  bool _isComplete() {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (_board[r][c] != _solution[r][c]) return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Sudoku Easy',
      onReset: _reset,
      child: Column(
        children: [
          if (_won) gameWinBanner('Grid complete!'),
          if (_won) const SizedBox(height: 12),
          const Text(
            'Tap a square to cycle 1–4. Fixed numbers stay put.',
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
                  crossAxisCount: 4,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: 16,
                itemBuilder: (_, i) {
                  final r = i ~/ 4, c = i % 4;
                  final fixed = _fixed.containsKey('$r,$c');
                  final v = _board[r][c];
                  return Material(
                    color: fixed ? AppColors.slate200 : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => _tap(r, c),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 56, minWidth: 56),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black87, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          v == 0 ? '' : '$v',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: fixed ? AppColors.slate700 : AppColors.brand700,
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
