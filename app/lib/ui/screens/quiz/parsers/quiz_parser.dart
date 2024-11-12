import 'package:app/data/models/parsed_questions.dart';

class QuizController {
  static final QuizController _instance = QuizController._internal();
  factory QuizController() => _instance;
  QuizController._internal();

  // Parse quiz content into structured format for display
  List<ParsedQuestion> parseQuizContent(String content) {
    final lines = content.split('\n');
    final questions = <ParsedQuestion>[];

    ParsedQuestion? currentQuestion;
    List<String> currentOptions = [];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (RegExp(r'^\d+\.').hasMatch(line)) {
        if (currentQuestion != null) {
          questions.add(currentQuestion);
        }

        final questionText = line.replaceFirst(RegExp(r'^\d+\.\s*'), '');
        currentQuestion = ParsedQuestion(
          text: questionText,
          options: [],
          correctAnswer: '',
        );
        currentOptions = [];
      } else if (RegExp(r'^[A-D]\)').hasMatch(line)) {
        final option = line.substring(3).trim();
        currentOptions.add(option);
      } else if (line.startsWith('Correct Answer:')) {
        final answer = line.split(':')[1].trim();
        if (currentQuestion != null) {
          currentQuestion = currentQuestion.copyWith(
            options: List.from(currentOptions),
            correctAnswer: currentOptions[_letterToIndex(answer)],
          );
        }
      }
    }

    if (currentQuestion != null) {
      questions.add(currentQuestion);
    }

    return questions;
  }

  // Format questions back into quiz content format
  String formatQuizContent(List<ParsedQuestion> questions) {
    final buffer = StringBuffer();

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];

      buffer.writeln('${i + 1}. ${q.text}');
      buffer.writeln();

      for (var j = 0; j < q.options.length; j++) {
        buffer.writeln('${_indexToLetter(j)}) ${q.options[j]}');
      }

      final correctIndex = q.options.indexOf(q.correctAnswer);
      buffer.writeln('Correct Answer: ${_indexToLetter(correctIndex)}');
      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  // Helper methods
  int _letterToIndex(String letter) {
    return letter.toUpperCase().codeUnitAt(0) - 'A'.codeUnitAt(0);
  }

  String _indexToLetter(int index) {
    return String.fromCharCode('A'.codeUnitAt(0) + index);
  }

  List<String> shuffleOptions(List<String> options) {
    final shuffled = List<String>.from(options);
    shuffled.shuffle();
    return shuffled;
  }

  double calculateProgress(int answered, int total) {
    return answered / total;
  }

  String getProgressMessage(double progress) {
    final percentage = (progress * 100).toStringAsFixed(0);
    return '$percentage% complete';
  }

  String getScoreMessage(double score) {
    if (score >= 90) return 'Excellent! You\'ve mastered this topic!';
    if (score >= 80) return 'Great job! You have a solid understanding!';
    if (score >= 70) return 'Good work! Keep practicing to improve!';
    if (score >= 60) return 'You passed! Review the topics you missed.';
    return 'Keep studying and try again. You can do it!';
  }

  double calculateScore(
      Map<String, String> answers, List<ParsedQuestion> questions) {
    int correct = 0;
    for (var question in questions) {
      if (answers[question.text] == question.correctAnswer) {
        correct++;
      }
    }
    return (correct / questions.length) * 100;
  }
}
