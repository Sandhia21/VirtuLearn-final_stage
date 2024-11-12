class Quiz {
  final int id;
  final String title;
  final String description;
  final String content;
  final int moduleId;
  final int quizDuration;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.quizDuration,
    required this.moduleId,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled',
      description: json['description'] ?? 'No description provided',
      content: json['content'] ?? 'No content provided',
      quizDuration: json['quiz_duration'] ?? 0,
      moduleId: json['module_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'quiz_duration': quizDuration,
      'module_id': moduleId,
    };
  }
}
