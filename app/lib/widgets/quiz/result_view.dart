import 'package:flutter/material.dart';
import 'package:app/constants/colors.dart';
import 'package:app/constants/dimensions.dart';
import 'package:app/constants/text_styles.dart';
import 'package:app/widgets/common/custom_button.dart';

class ResultView extends StatelessWidget {
  final int correctAnswers;
  final int totalQuestions;
  final VoidCallback onReviewAnswers;
  final VoidCallback onReturn;

  const ResultView({
    Key? key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.onReviewAnswers,
    required this.onReturn,
  }) : super(key: key);

  String _getPerformanceMessage(double percentage) {
    if (percentage >= 90) return 'Excellent!';
    if (percentage >= 80) return 'Great Job!';
    if (percentage >= 70) return 'Good Work!';
    if (percentage >= 60) return 'Keep Practicing!';
    return 'Try Again!';
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 90) return AppColors.success;
    if (percentage >= 70) return AppColors.primary;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (correctAnswers / totalQuestions) * 100;
    final performanceColor = _getPerformanceColor(percentage);

    return Container(
      padding: const EdgeInsets.all(Dimensions.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Performance Icon
          Icon(
            percentage >= 60 ? Icons.emoji_events : Icons.psychology,
            size: 64,
            color: performanceColor,
          ),
          const SizedBox(height: Dimensions.md),

          // Quiz Complete Text
          Text(
            _getPerformanceMessage(percentage),
            style: TextStyles.h1.copyWith(
              color: performanceColor,
            ),
          ),
          const SizedBox(height: Dimensions.lg),

          // Score Container
          Container(
            padding: const EdgeInsets.all(Dimensions.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  performanceColor.withOpacity(0.1),
                  performanceColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(Dimensions.borderRadiusLg),
              border: Border.all(
                color: performanceColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Percentage
                Text(
                  '${percentage.round()}%',
                  style: TextStyles.h1.copyWith(
                    color: performanceColor,
                    fontSize: 48,
                  ),
                ),
                const SizedBox(height: Dimensions.sm),

                // Score Details
                Text(
                  '$correctAnswers out of $totalQuestions correct',
                  style: TextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.xl),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Review Answers',
                  onPressed: onReviewAnswers,
                  isOutlined: true,
                  icon: Icons.refresh,
                ),
              ),
              const SizedBox(width: Dimensions.md),
              Expanded(
                child: CustomButton(
                  text: 'Return',
                  onPressed: onReturn,
                  icon: Icons.check_circle_outline,
                  gradient: LinearGradient(
                    colors: [
                      performanceColor,
                      performanceColor.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
