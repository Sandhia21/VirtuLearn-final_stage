import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/dimensions.dart';
import '../../constants/text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../common/loading_overlay.dart';
import '../common/custom_button.dart';

class QuizSection extends StatefulWidget {
  final int moduleId;

  const QuizSection({
    super.key,
    required this.moduleId,
  });

  @override
  State<QuizSection> createState() => _QuizSectionState();
}

class _QuizSectionState extends State<QuizSection> {
  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    await quizProvider.fetchQuizzes(widget.moduleId);
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher =
        Provider.of<AuthProvider>(context).user?.role == 'teacher';

    return Consumer<QuizProvider>(
      builder: (context, quizProvider, child) {
        if (quizProvider.isLoading) {
          return const LoadingOverlay(
            isLoading: true,
            child: SizedBox.expand(),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(Dimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isTeacher)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomButton(
                      text: 'Create Quiz',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/create-quiz',
                        arguments: widget.moduleId,
                      ),
                      icon: Icons.add,
                    ),
                  ],
                ),
              const SizedBox(height: Dimensions.md),
              Expanded(
                child: quizProvider.quizzes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'No quizzes available',
                              style: TextStyles.bodyLarge,
                            ),
                            if (!isTeacher) ...[
                              const SizedBox(height: Dimensions.md),
                              const Text(
                                'Quizzes will appear here once your instructor creates them',
                                style: TextStyles.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: quizProvider.quizzes.length,
                        itemBuilder: (context, index) {
                          final quiz = quizProvider.quizzes[index];
                          return Card(
                            margin:
                                const EdgeInsets.only(bottom: Dimensions.sm),
                            child: ListTile(
                              leading: const Icon(
                                Icons.quiz,
                                color: AppColors.primary,
                              ),
                              title: Text(quiz.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quiz.description,
                                    style: TextStyles.caption,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Duration: ${quiz.quizDuration} minutes',
                                    style: TextStyles.caption,
                                  ),
                                ],
                              ),
                              trailing: CustomButton(
                                text: isTeacher ? 'View' : 'Take Quiz',
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  isTeacher ? '/quiz-details' : '/take-quiz',
                                  arguments: {
                                    'quizId': quiz.id,
                                    'moduleId': widget.moduleId,
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
