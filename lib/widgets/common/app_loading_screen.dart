import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Écran de chargement officiel My Doctor fidèle à la maquette de référence :
/// - Fond blanc épuré
/// - Logo officiel My Doctor (icône cercle de soin + typographie "my doctor")
/// - Spinner rotatif à 12 pétales arrondi (bleu azur médical)
/// - Libellé "Chargement..."
/// - Ligne de rythme cardiaque (ECG) turquoise en bas
class AppLoadingScreen extends StatelessWidget {
  final String message;

  const AppLoadingScreen({
    super.key,
    this.message = 'Chargement...',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AppLoadingView(message: message),
      ),
    );
  }
}

/// Vue de chargement réutilisable (pour Scaffold, modals ou overlays)
class AppLoadingView extends StatelessWidget {
  final String message;

  const AppLoadingView({
    super.key,
    this.message = 'Chargement...',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Contenu central : Logo + Spinner + Texte
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo officiel My Doctor
              Image.asset(
                'assets/images/my_doctor_logo.png',
                width: 220,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 52),

              // Spinner rotatif à pétales rayonnants (couleur azur #00A0E9)
              const PetalSpinner(
                size: 46,
                color: Color(0xFF009EE2),
              ),
              const SizedBox(height: 18),

              // Libellé "Chargement..."
              Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),

        // Ligne de pouls / pulsation cardiaque (ECG) en bas
        const Positioned(
          left: 0,
          right: 0,
          bottom: 28,
          child: Center(
            child: HeartbeatLine(
              width: 110,
              height: 24,
              color: Color(0xFF00A896),
            ),
          ),
        ),
      ],
    );
  }
}

/// Spinner rotatif à 12 pétales arrondies avec dégradé d'opacité dynamique
class PetalSpinner extends StatefulWidget {
  final double size;
  final Color color;

  const PetalSpinner({
    super.key,
    this.size = 46,
    this.color = const Color(0xFF009EE2),
  });

  @override
  State<PetalSpinner> createState() => _PetalSpinnerState();
}

class _PetalSpinnerState extends State<PetalSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (_, __) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _PetalSpinnerPainter(
            progress: _animCtrl.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _PetalSpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _PetalSpinnerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const count = 12;
    final radius = size.width / 2;
    final innerR = radius * 0.54;
    final outerR = radius * 0.94;
    final strokeWidth = size.width * 0.095;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final currentStep = (progress * count).floor();

    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi / count) - (math.pi / 2);
      final stepDiff = (i - currentStep + count) % count;
      final opacity = ((count - stepDiff) / count).clamp(0.15, 1.0);

      paint.color = color.withValues(alpha: opacity);

      final p1 = Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );

      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PetalSpinnerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Ligne de pulsation cardiaque (ECG) turquoise
class HeartbeatLine extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const HeartbeatLine({
    super.key,
    this.width = 110,
    this.height = 24,
    this.color = const Color(0xFF00A896),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _HeartbeatLinePainter(color: color),
    );
  }
}

class _HeartbeatLinePainter extends CustomPainter {
  final Color color;
  const _HeartbeatLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final midY = size.height / 2;
    final w = size.width;

    // Ligne plate gauche
    path.moveTo(0, midY);
    path.lineTo(w * 0.43, midY);
    // Creux Q
    path.lineTo(w * 0.46, midY + 3.2);
    // Pic R
    path.lineTo(w * 0.50, midY - 11.5);
    // Creux S
    path.lineTo(w * 0.54, midY + 11.5);
    // Onde T
    path.lineTo(w * 0.57, midY - 3.0);
    // Retour baseline
    path.lineTo(w * 0.60, midY);
    // Ligne plate droite
    path.lineTo(w, midY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
