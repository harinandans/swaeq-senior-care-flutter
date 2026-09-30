import 'package:flutter/material.dart';

import '../game_shell.dart';
import '../../theme/app_theme.dart';

class TubeSortGame extends StatefulWidget {
  const TubeSortGame({super.key});

  @override
  State<TubeSortGame> createState() => _TubeSortGameState();
}

class _TubeSortGameState extends State<TubeSortGame> {
  static const _colors = [Color(0xFFE11D48), Color(0xFF2563EB), Color(0xFF059669)];

  late List<List<int>> _tubes;
  final _history = <List<List<int>>>[];
  int? _from;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    setState(() {
      _from = null;
      _won = false;
      _history.clear();
      _tubes = [
        [0, 1, 0],
        [1, 0, 1],
        [],
        [],
      ];
    });
  }

  void _pushHistory() {
    _history.add(_tubes.map((t) => List<int>.from(t)).toList());
    if (_history.length > 20) _history.removeAt(0);
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _tubes = _history.removeLast();
      _from = null;
      _checkWin();
    });
  }

  void _tapTube(int i) {
    if (_won) return;
    setState(() {
      if (_from == null) {
        if (_tubes[i].isNotEmpty) _from = i;
        return;
      }
      if (_from == i) {
        _from = null;
        return;
      }
      final src = _from!;
      final ball = _tubes[src].last;
      final dst = _tubes[i];
      final canPour = dst.isEmpty ||
          (dst.last == ball && dst.length < 3 && _tubes[src].length <= 3);
      if (canPour && _tubes[src].isNotEmpty) {
        _pushHistory();
        _tubes[i].add(_tubes[src].removeLast());
        _from = null;
        _checkWin();
      } else {
        _from = _tubes[i].isEmpty ? null : i;
      }
    });
  }

  void _checkWin() {
    _won = _tubes.every((t) {
      if (t.isEmpty) return true;
      if (t.length != 3) return false;
      return t.every((c) => c == t.first);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Colour Tube Sort',
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
          if (_won) gameWinBanner('All tubes sorted — lovely work!'),
          if (_won) const SizedBox(height: 12),
          Text(
            _from == null ? 'Tap a tube, then tap where to pour.' : 'Choose destination tube.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, color: AppColors.slate600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_tubes.length, (i) {
                final selected = _from == i;
                return GestureDetector(
                  onTap: () => _tapTube(i),
                  child: Container(
                    width: 64,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected ? AppColors.brand600 : AppColors.slate300,
                        width: selected ? 3 : 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (final c in _tubes[i])
                          Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: _colors[c],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black87, width: 2),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
