import 'dart:math';

import 'package:flutter/material.dart';

import '../game_shell.dart';

class PatternRepeatGame extends StatefulWidget {
  const PatternRepeatGame({super.key});

  @override
  State<PatternRepeatGame> createState() => _PatternRepeatGameState();
}

class _PatternRepeatGameState extends State<PatternRepeatGame> {
  static const _btnColors = [
    Color(0xFFEF4444),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
  ];

  final _rng = Random();
  final _sequence = <int>[];
  final _input = <int>[];
  int _round = 0;
  bool _showing = false;
  int? _lit;
  bool _won = false;
  String _hint = 'Watch the lights, then repeat.';

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    setState(() {
      _sequence.clear();
      _input.clear();
      _round = 0;
      _showing = false;
      _lit = null;
      _won = false;
      _hint = 'Watch the lights, then repeat.';
    });
    _nextRound();
  }

  Future<void> _nextRound() async {
    if (_won || !mounted) return;
    setState(() {
      _input.clear();
      _sequence.add(_rng.nextInt(4));
      _showing = true;
      _hint = 'Watch…';
    });
    for (final idx in _sequence) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _lit = idx);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _lit = null);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    if (!mounted) return;
    setState(() {
      _showing = false;
      _hint = 'Your turn — tap the same pattern.';
    });
  }

  void _tapBtn(int i) {
    if (_showing || _won) return;
    setState(() {
      _input.add(i);
      _lit = i;
    });
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _lit = null);
    });
    if (_input[_input.length - 1] != _sequence[_input.length - 1]) {
      setState(() => _hint = 'Not quite — resetting this round.');
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _nextRound();
      });
      return;
    }
    if (_input.length == _sequence.length) {
      _round++;
      if (_round >= 3) {
        setState(() {
          _won = true;
          _hint = 'Lovely memory!';
        });
      } else {
        _nextRound();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Pattern Repeat',
      onReset: _reset,
      child: Column(
        children: [
          if (_won) gameWinBanner('Three rounds complete!'),
          if (_won) const SizedBox(height: 12),
          Text(_hint, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 8),
          Text('Round $_round / 3', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(4, (i) {
              final bright = _lit == i;
              return Material(
                color: _btnColors[i].withOpacity(bright ? 1 : 0.55),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => _tapBtn(i),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black87, width: bright ? 4 : 2),
                    ),
                  ),
                ),
              );
            }),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
