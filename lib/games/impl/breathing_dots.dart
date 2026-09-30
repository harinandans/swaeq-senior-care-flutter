import 'dart:async';

import 'package:flutter/material.dart';

import '../game_shell.dart';
import '../../theme/app_theme.dart';

class BreathingDotsGame extends StatefulWidget {
  const BreathingDotsGame({super.key});

  @override
  State<BreathingDotsGame> createState() => _BreathingDotsGameState();
}

class _BreathingDotsGameState extends State<BreathingDotsGame> {
  static const _targetBreaths = 5;

  double _scale = 0.6;
  bool _inhale = true;
  int _breaths = 0;
  bool _won = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCycle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _scale = 0.6;
      _inhale = true;
      _breaths = 0;
      _won = false;
    });
    _startCycle();
  }

  void _startCycle() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (_won || !mounted) return;
      setState(() {
        if (_inhale) {
          _scale += 0.012;
          if (_scale >= 1.0) _inhale = false;
        } else {
          _scale -= 0.012;
          if (_scale <= 0.6) _inhale = true;
        }
      });
    });
  }

  void _tap() {
    if (_won) return;
    if (_scale < 0.92) return;
    setState(() {
      _breaths++;
      if (_breaths >= _targetBreaths) _won = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hint = _won
        ? 'Session complete'
        : _scale > 0.85
            ? 'Tap when the circle feels full'
            : 'Breathe in… circle growing';
    return GameShell(
      title: 'Focus Dots',
      onReset: _reset,
      child: Column(
        children: [
          if (_won) gameWinBanner('Five gentle breaths — nice and calm.'),
          if (_won) const SizedBox(height: 12),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Breaths: $_breaths / $_targetBreaths',
            style: const TextStyle(fontSize: 17, color: AppColors.slate600),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _tap,
            child: Transform.scale(
              scale: _scale,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brand200,
                  border: Border.all(color: AppColors.brand700, width: 4),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.spa_outlined, size: 56, color: AppColors.brand700),
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'No rush — tap only when the circle is large.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.slate500),
          ),
        ],
      ),
    );
  }
}
