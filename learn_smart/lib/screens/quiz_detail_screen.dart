import 'dart:async';
import 'package:flutter/material.dart';
import 'package:learn_smart/screens/widgets/app_bar.dart';
import 'package:learn_smart/services/api_service.dart';
import 'package:learn_smart/models/quiz.dart';
import 'package:provider/provider.dart';
import 'package:learn_smart/view_models/auth_view_model.dart';

class QuizDetailScreen extends StatefulWidget {
  final int moduleId;
  final int quizId;
  final bool isStudentEnrolled;
  final bool isEditMode;

  QuizDetailScreen({
    required this.moduleId,
    required this.quizId,
    required this.isStudentEnrolled,
    this.isEditMode = false,
  });

  @override
  _QuizDetailScreenState createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  late Future<Quiz> quizFuture;
  late ApiService _apiService;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> parsedQuestions = [];

  int currentQuestionIndex = 0;
  String selectedAnswer = '';
  Map<int, String> selectedAnswers = {};
  bool showResult = false;
  bool showReview = false;

  double progress = 0.0;
  int correctAnswersCount = 0;
  Timer? _timer;
  int timeLeft = 30; // 30 seconds per question
  var isStudent;
  bool hasQuizStarted = false;

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    _apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
    _apiService.updateToken(authViewModel.user.token ?? '');
    quizFuture = _apiService.getQuizDetail(widget.moduleId, widget.quizId);
    isStudent = authViewModel.user.isStudent();

    if (hasQuizStarted && isStudent) _startTimer();
  }

  void _startTimer() {
    timeLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
          progress = 1 - (timeLeft / 30);
        } else {
          timer.cancel();
          _goToNextQuestion();
        }
      });
    });
  }

  void _parseQuizContent(String content) {
    List<String> questionBlocks = content.split("\n\n");
    parsedQuestions.clear(); // Clear existing questions

    for (var block in questionBlocks) {
      List<String> lines = block.split("\n");
      if (lines.length >= 6) {
        String questionText = lines[0];
        List<String> options = [
          lines[1].trim(),
          lines[2].trim(),
          lines[3].trim(),
          lines[4].trim(),
        ];
        String correctAnswer = _extractCorrectAnswer(block);

        parsedQuestions.add({
          'question': questionText,
          'options': options,
          'correctAnswer': correctAnswer,
        });
      }
    }
  }

  String _extractCorrectAnswer(String questionBlock) {
    final correctAnswerPattern = RegExp(r'Correct Answer:\s?([A-D])');
    final match = correctAnswerPattern.firstMatch(questionBlock);
    return match?.group(1) ?? '';
  }

  void _goToNextQuestion() {
    if (currentQuestionIndex < parsedQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = selectedAnswers[currentQuestionIndex] ?? '';
        timeLeft = 30; // Reset timer for new question
      });
    } else {
      _submitQuiz();
    }
  }

  void _calculateResult() {
    correctAnswersCount = 0;
    for (int i = 0; i < parsedQuestions.length; i++) {
      String correctAnswer = parsedQuestions[i]['correctAnswer'];
      String? selectedAnswer = selectedAnswers[i];

      if (selectedAnswer != null &&
          correctAnswer == selectedAnswer.substring(0, 1)) {
        correctAnswersCount++;
      }
    }
  }

  void _submitQuiz() {
    _calculateResult();
    setState(() {
      showResult = true;
      _timer?.cancel();
    });
  }

  Widget _buildQuizContent() {
    if (parsedQuestions.isEmpty) {
      return Center(child: Text('No quiz content available.'));
    }

    if (!hasQuizStarted && isStudent) {
      return Center(
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              hasQuizStarted = true;
              _startTimer();
            });
          },
          child: Text('Attempt Quiz'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Progress indicator and question counter
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentQuestionIndex + 1}/${parsedQuestions.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              Container(
                width: 45,
                height: 45,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF4CAF50),
                      ),
                      strokeWidth: 4,
                    ),
                    Center(
                      child: Text(
                        '$timeLeft',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Question
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child: Text(
            parsedQuestions[currentQuestionIndex]['question'],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Options
        ...parsedQuestions[currentQuestionIndex]['options']
            .map<Widget>((option) {
          bool isSelected = selectedAnswer == option;
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedAnswer = option;
                  selectedAnswers[currentQuestionIndex] = option;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFFE3F2FD) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Color(0xFF2196F3) : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Color(0xFF2196F3)
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                        color: isSelected ? Color(0xFF2196F3) : Colors.white,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              isSelected ? Color(0xFF2196F3) : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),

        // Next/Submit button
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedAnswer.isEmpty ? null : _goToNextQuestion,
              child: Text(
                currentQuestionIndex < parsedQuestions.length - 1
                    ? 'Next'
                    : 'Submit',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewContent() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: parsedQuestions.length,
      itemBuilder: (context, index) {
        final question = parsedQuestions[index];
        final selectedAnswer = selectedAnswers[index] ?? '';
        final correctAnswer = question['correctAnswer'];

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${index + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  question['question'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                ...question['options'].map<Widget>((option) {
                  bool isSelected = selectedAnswer == option;
                  bool isCorrect = option.startsWith(correctAnswer);

                  Color getBackgroundColor() {
                    if (isSelected && isCorrect) return Color(0xFFE8F5E9);
                    if (isSelected && !isCorrect) return Color(0xFFFFEBEE);
                    if (isCorrect) return Color(0xFFE8F5E9);
                    return Colors.white;
                  }

                  Color getBorderColor() {
                    if (isSelected && isCorrect) return Color(0xFF4CAF50);
                    if (isSelected && !isCorrect) return Color(0xFFEF5350);
                    if (isCorrect) return Color(0xFF4CAF50);
                    return Colors.grey[300]!;
                  }

                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: getBackgroundColor(),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: getBorderColor(),
                        width: 2,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Row(
                      children: [
                        if (isSelected && isCorrect)
                          Icon(Icons.check_circle, color: Color(0xFF4CAF50))
                        else if (isSelected && !isCorrect)
                          Icon(Icons.cancel, color: Color(0xFFEF5350))
                        else if (isCorrect)
                          Icon(Icons.check_circle_outline,
                              color: Color(0xFF4CAF50))
                        else
                          Icon(Icons.radio_button_unchecked,
                              color: Colors.grey),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultView() {
    int totalQuestions = parsedQuestions.length;
    double percentage = (correctAnswersCount / totalQuestions) * 100;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Quiz Completed!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A4A44),
          ),
        ),
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                '${percentage.round()}%',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A4A44),
                ),
              ),
              Text(
                '$correctAnswersCount out of $totalQuestions correct',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  showReview = true;
                });
              },
              child: Text('Review Answers'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Color(0xFF1A4A44),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(width: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Return'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Quiz'),
      body: FutureBuilder<Quiz>(
        future: quizFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final quiz = snapshot.data!;
            if (parsedQuestions.isEmpty) {
              _parseQuizContent(quiz.content);
              if (!widget.isEditMode) _startTimer();
            }

            if (showReview) {
              return _buildReviewContent();
            } else if (showResult) {
              return _buildResultView();
            } else {
              return isStudent && !widget.isEditMode
                  ? _buildQuizContent()
                  : _buildReviewContent();
            }
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
