import 'package:flutter/material.dart';

import '../game_shell.dart';
import '../../theme/app_theme.dart';

class TangramGame extends StatefulWidget {
  const TangramGame({super.key});

  @override
  State<TangramGame> createState() => _TangramGameState();
}

class _TangramGameState extends State<TangramGame> {
  Offset _tri = const Offset(24, 220);
  Offset _sq = const Offset(24, 320);
  bool _triPlaced = false;
  bool _sqPlaced = false;

  bool get _won => _triPlaced && _sqPlaced;

  void _reset() {
    setState(() {
      _tri = const Offset(24, 220);
      _sq = const Offset(24, 320);
      _triPlaced = false;
      _sqPlaced = false;
    });
  }

  void _dragTri(DragUpdateDetails d) {
    if (_triPlaced) return;
    setState(() => _tri += d.delta);
  }

  void _endTri() {
    if (_triPlaced) return;
    const target = Offset(120, 80);
    if ((_tri - target).distance < 50) {
      setState(() {
        _tri = target;
        _triPlaced = true;
      });
    }
  }

  void _dragSq(DragUpdateDetails d) {
    if (_sqPlaced) return;
    setState(() => _sq += d.delta);
  }

  void _endSq() {
    if (_sqPlaced) return;
    const target = Offset(200, 140);
    if ((_sq - target).distance < 50) {
      setState(() {
        _sq = target;
        _sqPlaced = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Shape Fit',
      onReset: _reset,
      child: Column(
        children: [
          if (_won) gameWinBanner('Shapes fit the outline!'),
          if (_won) const SizedBox(height: 12),
          const Text(
            'Drag each shape into the dashed outline.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: AppColors.slate600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 100,
                  top: 60,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.slate400, width: 2, strokeAlign: BorderSide.strokeAlignInside),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    foregroundDecoration: BoxDecoration(
                      border: Border.all(color: AppColors.slate300, width: 2, style: BorderStyle.solid),
                    ),
                  ),
                ),
                Positioned(
                  left: 108,
                  top: 68,
                  child: CustomPaint(
                    size: const Size(100, 100),
                    painter: _OutlinePainter(),
                  ),
                ),
                Positioned(
                  left: _tri.dx,
                  top: _tri.dy,
                  child: GestureDetector(
                    onPanUpdate: _dragTri,
                    onPanEnd: (_) => _endTri(),
                    child: CustomPaint(
                      size: const Size(80, 70),
                      painter: _TriPainter(AppColors.brand600),
                    ),
                  ),
                ),
                Positioned(
                  left: _sq.dx,
                  top: _sq.dy,
                  child: GestureDetector(
                    onPanUpdate: _dragSq,
                    onPanEnd: (_) => _endSq(),
                    child: Container(
                      width: 72,
                      height: 72,
                      color: const Color(0xFF14B8A6),
                      foregroundDecoration: BoxDecoration(
                        border: Border.all(color: Colors.black87, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TriPainter extends CustomPainter {
  _TriPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(path, Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.slate400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(8, 8, 44, 44), paint);
    final tri = Path()
      ..moveTo(60, 52)
      ..lineTo(92, 92)
      ..lineTo(28, 92)
      ..close();
    canvas.drawPath(tri, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
