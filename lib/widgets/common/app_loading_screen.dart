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
    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo officiel My Doctor
              Image.asset(
                'assets/images/my_doctor_logo.png',
                width: 220,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 40),

              // Barre de chargement onde cardiaque (ECG) turquoise
              const EcgLoadingBar(
                width: 220,
                height: 46,
                strokeWidth: 3.5,
                color: AppColors.brandTurquoise,
              ),
              const SizedBox(height: 20),

              // Libellé "Chargement..."
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barre de chargement animée en onde cardiaque (ECG) My Doctor
class EcgLoadingBar extends StatefulWidget {
  final double width;
  final double height;
  final double strokeWidth;
  final Color color;
  final Duration duration;

  const EcgLoadingBar({
    super.key,
    this.width = 220,
    this.height = 46,
    this.strokeWidth = 3.5,
    this.color = AppColors.brandTurquoise,
    this.duration = const Duration(milliseconds: 1600),
  });

  @override
  State<EcgLoadingBar> createState() => _EcgLoadingBarState();
}

class _EcgLoadingBarState extends State<EcgLoadingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.width),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: AnimatedBuilder(
            animation: _animCtrl,
            builder: (_, __) {
              return CustomPaint(
                size: Size(widget.width, widget.height),
                painter: _EcgLoadingPainter(
                  progress: _animCtrl.value,
                  color: widget.color,
                  strokeWidth: widget.strokeWidth,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EcgLoadingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _EcgLoadingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h / 2;

    // Tracé de l'onde ECG fidèle à l'image de référence
    final fullPath = Path();
    fullPath.moveTo(0, midY);
    fullPath.lineTo(w * 0.39, midY);
    fullPath.lineTo(w * 0.42, midY + (h * 0.14)); // Creux Q
    fullPath.lineTo(w * 0.47, midY - (h * 0.41)); // Pic R élevé
    fullPath.lineTo(w * 0.52, midY + (h * 0.41)); // Creux S profond
    fullPath.lineTo(w * 0.56, midY - (h * 0.18)); // Onde T de rappel
    fullPath.lineTo(w * 0.595, midY); // Retour baseline
    fullPath.lineTo(w, midY); // Ligne droite de fin

    // 1. Ligne de fond estompée (track)
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.20)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(fullPath, trackPaint);

    // 2. Onde active animée (pulse beam)
    final pulsePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final metric in fullPath.computeMetrics()) {
      final totalLen = metric.length;
      final pulseLen = totalLen * 0.38;
      final currentHead = progress * totalLen;
      final currentTail = currentHead - pulseLen;

      if (currentTail >= 0) {
        // Faisceau principal contenu dans le tracé
        final segment = metric.extractPath(currentTail, currentHead);
        canvas.drawPath(segment, pulsePaint);
      } else {
        // Enroulement continu sans rupture : la tête avance à gauche pendant que la queue termine à droite
        final headSegment = metric.extractPath(0.0, currentHead);
        canvas.drawPath(headSegment, pulsePaint);

        final tailSegment = metric.extractPath(totalLen + currentTail, totalLen);
        canvas.drawPath(tailSegment, pulsePaint);
      }

      // Halo lumineux continu à la tête de pulsation
      final tangent = metric.getTangentForOffset(currentHead);
      if (tangent != null) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.8);
        canvas.drawCircle(tangent.position, strokeWidth * 1.15, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EcgLoadingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
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
