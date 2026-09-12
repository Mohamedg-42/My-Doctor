import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Widget affichant le logo officiel My Doctor avec support de capsule blanche,
/// ombre douce identique à l'écran d'accueil/choix de profil et solution de secours élégante.
class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final bool showCard;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final bool hasShadow;
  final List<BoxShadow>? customShadow;

  const AppLogo({
    super.key,
    this.width,
    this.height = 36,
    this.showCard = true,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.hasShadow = true,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isLarge = (height != null && height! >= 70) || (width != null && width! >= 200);

    final imageWidget = Image.asset(
      'assets/images/my_doctor_logo.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        if (isLarge) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_hospital_rounded,
                size: 64,
                color: AppColors.brandBlue,
              ),
              const SizedBox(height: 8),
              Text(
                'my doctor',
                style: AppTextStyles.display.copyWith(color: AppColors.brandBlue),
              ),
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_hospital_rounded,
              size: (height ?? 30) * 0.8,
              color: AppColors.logoBlue,
            ),
            const SizedBox(width: 6),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: (height ?? 30) * 0.45,
                ),
                children: const [
                  TextSpan(
                    text: 'my ',
                    style: TextStyle(color: AppColors.logoBlue),
                  ),
                  TextSpan(
                    text: 'doctor',
                    style: TextStyle(color: AppColors.logoTurquoise),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (!showCard) {
      return imageWidget;
    }

    final effectivePadding = padding ??
        (isLarge
            ? const EdgeInsets.all(16)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 6));
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(isLarge ? 28 : 18);
    final effectiveShadow = customShadow ??
        (hasShadow
            ? [
                BoxShadow(
                  color: AppColors.brandNavy.withValues(alpha: isLarge ? 0.05 : 0.08),
                  blurRadius: isLarge ? 24 : 12,
                  offset: Offset(0, isLarge ? 8 : 3),
                ),
              ]
            : null);

    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceCard,
        borderRadius: effectiveBorderRadius,
        boxShadow: effectiveShadow,
      ),
      child: imageWidget,
    );
  }
}
