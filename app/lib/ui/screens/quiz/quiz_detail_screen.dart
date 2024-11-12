import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimensions.dart';
import '../../../constants/text_styles.dart';
import '../../../providers/quiz_provider.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/loading_overlay.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/quiz/question_card.dart';
import '../../../widgets/quiz/result_card.dart';
import '../../../widgets/quiz/result_view.dart';
import '../../../ui/controllers/quiz_controller.dart';

class QuizDetailScreen extends StatefulWidget {
  final int moduleId;
  final int quizId;

  const QuizDetailScreen({
    super.key,
    required this.moduleId,
    required this.quizId,
  });

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  final QuizController _quizController = QuizController();
  final Map<int, String> _userAnswers = {};
  bool _isSubmitted = false;
  bool _isReviewing = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    await quizProvider.fetchQuizDetails(widget.moduleId, widget.quizId);
  }

  void _handleAnswerSelected(int questionIndex, String answer) {
    setState(() {
      _userAnswers[questionIndex] = answer;
    });
  }

  Future<void> _handleSubmit() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final quiz = quizProvider.selectedQuiz;
    if (quiz == null) return;

    final questions = _quizController.parseQuizContent(quiz.content);
    if (_userAnswers.length != questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions before submitting'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final score = _calculateScore(questions);
      await quizProvider.submitQuizResult(
        moduleId: widget.moduleId,
        quizId: widget.quizId,
        percentage: score.toDouble(),
        quizContent: quiz.content,
      );

      if (mounted) {
        setState(() {
          _isSubmitted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  int _calculateScore(List<ParsedQuestion> questions) {
    int correct = 0;
    for (var i = 0; i < questions.length; i++) {
      if (_userAnswers[i] == questions[i].correctAnswer) {
        correct++;
      }
    }
    return ((correct / questions.length) * 100).round();
  }

  void _handleReviewAnswers() {
    setState(() {
      _isReviewing = true;
    });
  }

  void _handleReturn() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quit Quiz?'),
            content: const Text(
              'Are you sure you want to quit? Your progress will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Quit'),
              ),
            ],
          ),
        );

        if (shouldPop ?? false) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'Quiz',
        ),
        body: Consumer<QuizProvider>(
          builder: (context, quizProvider, child) {
            if (quizProvider.isLoading) {
              return const LoadingOverlay(
                isLoading: true,
                child: SizedBox.expand(),
              );
            }

            if (quizProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      quizProvider.error!,
                      style: TextStyles.error,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Dimensions.md),
                    CustomButton(
                      text: 'Retry',
                      onPressed: _loadQuiz,
                      width: 120,
                    ),
                  ],
                ),
              );
            }

            final quiz = quizProvider.selectedQuiz;
            if (quiz == null) {
              return const Center(
                child: Text(
                  'Quiz not found',
                  style: TextStyles.bodyLarge,
                ),
              );
            }

            final questions = _quizController.parseQuizContent(quiz.content);

            if (_isSubmitted) {
              final score = _calculateScore(questions);

              if (_isReviewing) {
                return ListView.builder(
                  padding: const EdgeInsets.all(Dimensions.md),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    final userAnswer = _userAnswers[index] ?? '';
                    final isCorrect = question.correctAnswer == userAnswer;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: Dimensions.md),
                      child: ResultCard(
                        question: question,
                        userAnswer: userAnswer,
                        isCorrect: isCorrect,
                      ),
                    );
                  },
                );
              }

              return ResultView(
                correctAnswers: score,
                totalQuestions: questions.length,
                onReviewAnswers: _handleReviewAnswers,
                onReturn: _handleReturn,
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(Dimensions.md),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Dimensions.md),
                        child: QuestionCard(
                          question: questions[index],
                          selectedAnswer: _userAnswers[index],
                          onAnswerSelected: (answer) =>
                              _handleAnswerSelected(index, answer),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(Dimensions.md),
                  child: CustomButton(
                    text: 'Submit Quiz',
                    onPressed: _handleSubmit,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
