import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/dimensions.dart';
import '../../constants/text_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final bool isOutlined;
  final bool isLoading;
  final bool isDisabled; // Added isDisabled property
  final double? width;
  final IconData? icon;
  final Gradient? gradient;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.isOutlined = false,
    this.isLoading = false,
    this.isDisabled = false, // Added default value
    this.width,
    this.icon,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: BoxConstraints(
        minWidth: 88.0,
        maxWidth: width ?? double.infinity,
      ),
      height: 48.0,
      child: isOutlined ? _buildOutlinedButton() : _buildElevatedButton(),
    );
  }

  Widget _buildElevatedButton() {
    if (gradient != null) {
      return Container(
        decoration: BoxDecoration(
          gradient:
              isDisabled ? null : gradient, // Don't show gradient if disabled
          color: isDisabled
              ? AppColors.grey.withOpacity(0.3)
              : null, // Show grey if disabled
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusMd),
          boxShadow: isDisabled
              ? []
              : [
                  // No shadow if disabled
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (isLoading || isDisabled) ? null : onPressed,
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusMd),
            child: Center(child: _buildButtonContent()),
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: (isLoading || isDisabled) ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled
            ? AppColors.grey.withOpacity(0.3)
            : backgroundColor ?? AppColors.primary,
        foregroundColor:
            isDisabled ? AppColors.grey : textColor ?? AppColors.white,
        elevation: isDisabled ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusMd),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: width != null ? Dimensions.md : Dimensions.lg,
        ),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildOutlinedButton() {
    return OutlinedButton(
      onPressed: (isLoading || isDisabled) ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor:
            isDisabled ? AppColors.grey : textColor ?? AppColors.primary,
        side: BorderSide(
          color: isDisabled
              ? AppColors.grey.withOpacity(0.3)
              : borderColor ?? backgroundColor ?? AppColors.primary,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusMd),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: width != null ? Dimensions.md : Dimensions.lg,
        ),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        height: 24.0,
        width: 24.0,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isDisabled
                ? AppColors.grey
                : textColor ??
                    (isOutlined ? AppColors.primary : AppColors.white),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 24.0,
            color: isDisabled
                ? AppColors.grey
                : textColor ??
                    (isOutlined ? AppColors.primary : AppColors.white),
          ),
          const SizedBox(width: 8.0),
        ],
        Text(
          text,
          style: TextStyle(
            color: isDisabled
                ? AppColors.grey
                : textColor ??
                    (isOutlined ? AppColors.primary : AppColors.white),
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
