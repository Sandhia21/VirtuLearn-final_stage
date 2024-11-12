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

      // Match question pattern: "1. What is..."
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
      }
      // Match option pattern: "A) Option"
      else if (RegExp(r'^[A-D]\)').hasMatch(line)) {
        final option = line.substring(3).trim();
        currentOptions.add(option);
      }
      // Match correct answer pattern: "Correct Answer: X"
      else if (line.startsWith('Correct Answer:')) {
        final answer = line.split(':')[1].trim();
        if (currentQuestion != null) {
          currentQuestion = currentQuestion.copyWith(
            options: List.from(currentOptions),
            correctAnswer: currentOptions[_letterToIndex(answer)],
          );
        }
      }
    }

    // Add the last question
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

      // Add question number and text
      buffer.writeln('${i + 1}. ${q.text}');
      buffer.writeln();

      // Add options with letters
      for (var j = 0; j < q.options.length; j++) {
        buffer.writeln('${_indexToLetter(j)}) ${q.options[j]}');
      }

      // Add correct answer
      final correctIndex = q.options.indexOf(q.correctAnswer);
      buffer.writeln('Correct Answer: ${_indexToLetter(correctIndex)}');
      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  // Validation methods
  bool validateQuizContent(String content) {
    try {
      final questions = parseQuizContent(content);
      return questions.isNotEmpty &&
          questions.every((q) =>
              q.options.length == 4 && q.options.contains(q.correctAnswer));
    } catch (e) {
      return false;
    }
  }

  bool validateQuestion(ParsedQuestion question) {
    return question.options.length == 4 &&
        question.options.contains(question.correctAnswer) &&
        question.text.isNotEmpty;
  }

  // Scoring and progress methods
  double calculateScore(
      Map<String, String> answers, List<ParsedQuestion> questions) {
    if (questions.isEmpty) return 0.0;

    int correct = 0;
    for (var question in questions) {
      if (answers[question.text] == question.correctAnswer) {
        correct++;
      }
    }
    return (correct / questions.length) * 100;
  }

  double calculateProgress(int answeredCount, int totalQuestions) {
    if (totalQuestions == 0) return 0.0;
    return answeredCount / totalQuestions;
  }

  // Helper methods
  List<String> shuffleOptions(List<String> options) {
    final shuffled = List<String>.from(options);
    shuffled.shuffle();
    return shuffled;
  }

  int _letterToIndex(String letter) {
    return letter.trim().toUpperCase().codeUnitAt(0) - 'A'.codeUnitAt(0);
  }

  String _indexToLetter(int index) {
    return String.fromCharCode('A'.codeUnitAt(0) + index);
  }

  // Message formatting methods
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

  // Quiz creation helper
  String createQuizContent(List<Map<String, dynamic>> questions) {
    final parsedQuestions = questions
        .map((q) => ParsedQuestion(
              text: q['question'] as String,
              options: List<String>.from(q['options']),
              correctAnswer: q['correctAnswer'] as String,
            ))
        .toList();

    return formatQuizContent(parsedQuestions);
  }
}

class ParsedQuestion {
  final String text;
  final List<String> options;
  final String correctAnswer;

  ParsedQuestion({
    required this.text,
    required this.options,
    required this.correctAnswer,
  });

  ParsedQuestion copyWith({
    String? text,
    List<String>? options,
    String? correctAnswer,
  }) {
    return ParsedQuestion(
      text: text ?? this.text,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
    );
  }
}
