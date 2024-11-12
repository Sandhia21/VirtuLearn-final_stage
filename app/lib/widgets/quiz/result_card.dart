import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimensions.dart';
import '../../../constants/text_styles.dart';
import 'package:app/ui/controllers/quiz_controller.dart';

class ResultCard extends StatelessWidget {
  final ParsedQuestion question;
  final String userAnswer;
  final bool isCorrect;

  const ResultCard({
    Key? key,
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: Dimensions.sm),
                Expanded(
                  child: Text(
                    question.text,
                    style: TextStyles.h3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.md),
            Text(
              'Your answer: $userAnswer',
              style: TextStyles.bodyMedium.copyWith(
                color: isCorrect ? AppColors.success : AppColors.error,
              ),
            ),
            if (!isCorrect) ...[
              const SizedBox(height: Dimensions.sm),
              Text(
                'Correct answer: ${question.correctAnswer}',
                style: TextStyles.bodyMedium.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
            const SizedBox(height: Dimensions.sm),
            Text(
              'Options:',
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ...question.options.map((option) => Padding(
                  padding: const EdgeInsets.only(
                    left: Dimensions.md,
                    top: Dimensions.xs,
                  ),
                  child: Text(
                    '• $option',
                    style: TextStyles.bodyMedium.copyWith(
                      color: option == question.correctAnswer
                          ? AppColors.success
                          : option == userAnswer && !isCorrect
                              ? AppColors.error
                              : AppColors.textPrimary,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
