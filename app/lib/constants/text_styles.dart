import 'package:flutter/material.dart';
import 'colors.dart';
import 'dimensions.dart';

class TextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: Dimensions.fontLg,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: Dimensions.fontMd,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: Dimensions.fontSm,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Button text
  static const TextStyle button = TextStyle(
    fontSize: Dimensions.fontMd,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    height: 1,
  );

  // Input text
  static const TextStyle input = TextStyle(
    fontSize: Dimensions.fontMd,
    color: AppColors.textPrimary,
  );

  static const TextStyle inputLabel = TextStyle(
    fontSize: Dimensions.fontSm,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w500,
  );

  // Link text
  static const TextStyle link = TextStyle(
    fontSize: Dimensions.fontMd,
    color: AppColors.primary,
    fontWeight: FontWeight.w500,
  );

  // Error text
  static const TextStyle error = TextStyle(
    fontSize: Dimensions.fontSm,
    color: AppColors.error,
    height: 1.5,
  );

  // Caption text
  static const TextStyle caption = TextStyle(
    fontSize: Dimensions.fontXs,
    color: AppColors.textSecondary,
    height: 1.5,
  );
}
