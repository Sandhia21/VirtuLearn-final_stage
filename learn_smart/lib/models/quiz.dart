class Quiz {
  final int id;
  final String title;
  final String description;
  final String content; // Quiz content field
  final int moduleId; // Linking to the module the quiz belongs to
  final int quizDuration; // Duration in minutes

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.quizDuration,
    required this.moduleId,
  });

  // Factory method to create Quiz from JSON
  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled',
      description: json['description'] ?? 'No description provided',
      content: json['content'] ?? 'No content provided', // Quiz content
      quizDuration: json['quiz_duration'] ?? 0,
      moduleId: json['module_id'] ?? 0,
    );
  }

  // Method to convert Quiz to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content, // Content now replaces questions
      'quiz_duration': quizDuration,
      'module_id': moduleId,
    };
  }
}
