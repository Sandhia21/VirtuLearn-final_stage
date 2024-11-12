import 'package:flutter/foundation.dart';
import '../data/models/quiz.dart';
import '../data/repositories/quiz_repository.dart';

class QuizProvider extends ChangeNotifier {
  final QuizRepository _repository;
  List<Quiz> _quizzes = [];
  Quiz? _selectedQuiz;
  bool _isLoading = false;
  String? _error;

  QuizProvider(this._repository);

  // Getters
  List<Quiz> get quizzes => _quizzes;
  Quiz? get selectedQuiz => _selectedQuiz;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchQuizzes(int moduleId) async {
    try {
      _setLoading(true);
      _quizzes = await _repository.getQuizzes(moduleId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchQuizDetails(int moduleId, int quizId) async {
    try {
      _setLoading(true);
      _selectedQuiz = await _repository.getQuizDetail(moduleId, quizId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createQuiz({
    required int moduleId,
    required String title,
    required String description,
    required String content,
    required String quizDuration,
  }) async {
    try {
      _setLoading(true);
      await _repository.createQuiz(
        moduleId: moduleId,
        title: title,
        description: description,
        content: content,
        quizDuration: quizDuration,
      );
      await fetchQuizzes(moduleId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow; // Changed from throw e to rethrow
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitQuizResult({
    required int moduleId,
    required int quizId,
    required double percentage,
    required String quizContent,
  }) async {
    try {
      _setLoading(true);
      await _repository.submitQuizResult(
        moduleId: moduleId,
        quizId: quizId,
        percentage: percentage,
        quizContent: quizContent,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow; // Changed from throw e to rethrow
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
