import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = isLoading || onPressed == null;

    return SizedBox(
      width: double.infinity,
      height: height ?? 56,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          // Premium gold background
          backgroundColor: backgroundColor ?? AppColors.gold,
          // Dark red/charcoal text for contrast
          foregroundColor: foregroundColor ?? AppColors.dark,
          // Disabled state: faded gold
          disabledBackgroundColor: AppColors.gold.withOpacity(0.5),
          elevation: 4,
          shadowColor: AppColors.goldDark.withOpacity(0.4),
          padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  // Spinner in dark color for visibility on gold
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.dark),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.dark, // Ensures text color even if theme overrides
                ),
              ),
      ),
    );
  }
}