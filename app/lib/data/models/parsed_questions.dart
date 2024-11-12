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
