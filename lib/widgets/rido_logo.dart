import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class RidoLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final double fontSize;

  const RidoLogo({
    super.key,
    this.size = 36,
    this.showText = true,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryLight, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: CustomPaint(
            size: Size(size * 0.65, size * 0.65),
            painter: _RidoLogoPainter(),
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.3),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RIDO',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RidoLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Vertical stem of R
    path.moveTo(size.width * 0.28, size.height * 0.85);
    path.lineTo(size.width * 0.28, size.height * 0.15);

    // Loop of R
    path.cubicTo(
      size.width * 0.75,
      size.height * 0.15,
      size.width * 0.75,
      size.height * 0.52,
      size.width * 0.28,
      size.height * 0.52,
    );

    // Dynamic diagonal leg of R pointing like a road/speed line
    path.moveTo(size.width * 0.38, size.height * 0.52);
    path.lineTo(size.width * 0.82, size.height * 0.85);

    canvas.drawPath(path, paint);

    // Speed dot accent
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.24), size.width * 0.08, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
