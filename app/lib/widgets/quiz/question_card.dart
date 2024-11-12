import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimensions.dart';
import '../../../constants/text_styles.dart';
import 'package:app/ui/controllers/quiz_controller.dart';

class QuestionCard extends StatelessWidget {
  final question;
  final String? selectedAnswer;
  final Function(String) onAnswerSelected;
  final QuizController _quizController = QuizController();

  QuestionCard({
    Key? key,
    required this.question,
    required this.selectedAnswer,
    required this.onAnswerSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use controller to get shuffled options
    final shuffledOptions = _quizController.shuffleOptions(question.options);

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
            Text(
              question.text,
              style: TextStyles.h3,
            ),
            const SizedBox(height: Dimensions.md),
            ...shuffledOptions.map((option) => RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: selectedAnswer,
                  onChanged: (value) => onAnswerSelected(value!),
                  activeColor: AppColors.primary,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.borderRadiusSm),
                  ),
                  tileColor: selectedAnswer == option
                      ? AppColors.primary.withOpacity(0.1)
                      : null,
                )),
          ],
        ),
      ),
    );
  }
}
