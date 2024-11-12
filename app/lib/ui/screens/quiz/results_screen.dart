import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimensions.dart';
import '../../../constants/text_styles.dart';
import '../../../providers/quiz_provider.dart';
import '../../../widgets/quiz/result_card.dart';
import '../../../ui/controllers/quiz_controller.dart';

class ResultsScreen extends StatefulWidget {
  final int quizId;
  final int moduleId;
  final double score;
  final List<ParsedQuestion> questions;
  final Map<String, String> answers;

  const ResultsScreen({
    Key? key,
    required this.quizId,
    required this.moduleId,
    required this.score,
    required this.questions,
    required this.answers,
  }) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final QuizController _quizController = QuizController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResults();
    });
  }

  Future<void> _loadResults() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    await quizProvider.fetchQuizDetails(widget.moduleId, widget.quizId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz Results',
          style: TextStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          if (quizProvider.error != null) {
            return Center(
              child: Text(
                quizProvider.error!,
                style: TextStyles.error,
                textAlign: TextAlign.center,
              ),
            );
          }

          final quiz = quizProvider.selectedQuiz;
          if (quiz == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(Dimensions.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(Dimensions.borderRadiusMd),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your Score',
                        style: TextStyles.h3,
                      ),
                      const SizedBox(height: Dimensions.md),
                      Text(
                        '${widget.score.toStringAsFixed(1)}%',
                        style: TextStyles.h1.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: Dimensions.md),
                      Text(
                        _quizController.getScoreMessage(widget.score),
                        style: TextStyles.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.xl),
                Text(
                  'Detailed Results',
                  style: TextStyles.h3,
                ),
                const SizedBox(height: Dimensions.md),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.questions.length,
                  itemBuilder: (context, index) {
                    final question = widget.questions[index];
                    final userAnswer = widget.answers[question.text] ?? '';
                    final isCorrect = userAnswer == question.correctAnswer;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: Dimensions.md),
                      child: ResultCard(
                        question: question,
                        userAnswer: userAnswer,
                        isCorrect: isCorrect,
                      ),
                    );
                  },
                ),
                const SizedBox(height: Dimensions.xl),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Return to Home'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
