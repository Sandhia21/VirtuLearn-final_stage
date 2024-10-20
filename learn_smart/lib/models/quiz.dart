class Quiz {
  final int id;
  final String title;
  final String description;
  final String quizType;
  final String category;
  final String content; // Quiz content field
  final int moduleId; // Linking to the module the quiz belongs to
  final int quizDuration; // Duration in minutes
  final List<Question> questions;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.quizType,
    required this.category,
    required this.quizDuration,
    required this.questions,
    required this.content,
    required this.moduleId,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled',
      description: json['description'] ?? 'No description provided',
      quizType: json['quiz_type'] ?? 'unknown',
      category: json['category'] ?? 'unknown',
      quizDuration: json['quiz_duration'] ?? 0,
      questions: (json['questions'] as List)
          .map((question) => Question.fromJson(question))
          .toList(),
      content: json['content'] ?? 'No content',
      moduleId: json['module_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'quiz_type': quizType,
      'category': category,
      'quiz_duration': quizDuration,
      'questions': questions.map((q) => q.toJson()).toList(),
      'content': content,
      'module_id': moduleId
    };
  }
}

class Question {
  final int id;
  final String questionText;
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;
  final String? correctAnswer;

  Question({
    required this.id,
    required this.questionText,
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
    this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? 0,
      questionText: json['question_text'] ?? 'No question text provided',
      optionA: json['option_a'],
      optionB: json['option_b'],
      optionC: json['option_c'],
      optionD: json['option_d'],
      correctAnswer: json['correct_answer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_answer': correctAnswer,
    };
  }
}
