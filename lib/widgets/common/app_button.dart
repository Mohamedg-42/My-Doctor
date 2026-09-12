import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum AppButtonStyle { primary, secondary, outline, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? height;
  final double? fontSize;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = AppButtonStyle.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.height,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    const defaultRadius = 12.0; // --radius-control: 12px
    final buttonHeight = height ?? 52.0; // Min 52px

    Widget content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _getTextColor(),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: _getTextColor()),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: _getTextColor(),
                  fontSize: fontSize ?? 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    Widget button;

    switch (style) {
      case AppButtonStyle.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandBlue,
            foregroundColor: AppColors.textOnColor,
            disabledBackgroundColor: const Color(0xFFEDF2F7),
            disabledForegroundColor: const Color(0xFFA0AEC0),
            elevation: 0,
            minimumSize: Size(isFullWidth ? double.infinity : 120, buttonHeight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
          ),
          child: content,
        );
        break;

      case AppButtonStyle.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.surfaceCard,
            foregroundColor: AppColors.brandBlue,
            side: const BorderSide(color: AppColors.brandBlue, width: 1.2),
            elevation: 0,
            minimumSize: Size(isFullWidth ? double.infinity : 120, buttonHeight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
          ),
          child: content,
        );
        break;

      case AppButtonStyle.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brandNavy,
            side: const BorderSide(color: AppColors.borderSubtle, width: 1.5),
            minimumSize: Size(isFullWidth ? double.infinity : 120, buttonHeight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
          ),
          child: content,
        );
        break;

      case AppButtonStyle.ghost:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brandBlue,
            minimumSize: Size(isFullWidth ? double.infinity : 120, buttonHeight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
          ),
          child: content,
        );
        break;

      case AppButtonStyle.danger:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandCoral,
            foregroundColor: AppColors.textOnColor,
            elevation: 0,
            minimumSize: Size(isFullWidth ? double.infinity : 120, buttonHeight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
          ),
          child: content,
        );
        break;
    }

    return button;
  }

  Color _getTextColor() {
    switch (style) {
      case AppButtonStyle.primary:
      case AppButtonStyle.danger:
        return AppColors.textOnColor;
      case AppButtonStyle.secondary:
      case AppButtonStyle.ghost:
        return AppColors.brandBlue;
      case AppButtonStyle.outline:
        return AppColors.brandNavy;
    }
  }
}

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final bool hasShadow;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 44, // 44x44px minimum touch target
    this.iconSize = 20,
    this.hasShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surfaceCard,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: hasShadow
              ? [
                  BoxShadow(
                    color: AppColors.brandNavy.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor ?? AppColors.brandBlue,
          ),
        ),
      ),
    );
  }
}
