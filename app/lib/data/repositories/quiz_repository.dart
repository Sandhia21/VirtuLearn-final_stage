import '../models/quiz.dart';
import '../../services/quiz_api_service.dart';

class QuizRepository {
  final QuizApiService _quizService;

  QuizRepository(this._quizService);

  Future<List<Quiz>> getQuizzes(int moduleId) async {
    try {
      final response = await _quizService.fetchQuizzes(moduleId);
      return response.map((quizJson) => Quiz.fromJson(quizJson)).toList();
    } catch (e) {
      throw _handleRepositoryError(e);
    }
  }

  // Add this method
  Future<Quiz> getQuizDetail(int quizId, int moduleId) async {
    try {
      final response = await _quizService.getQuizDetail(quizId, moduleId);
      return Quiz.fromJson(response);
    } catch (e) {
      throw _handleRepositoryError(e);
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
      await _quizService.createQuiz(
        moduleId: moduleId,
        title: title,
        description: description,
        content: content,
        quizDuration: quizDuration,
      );
    } catch (e) {
      throw _handleRepositoryError(e);
    }
  }

  Future<void> submitQuizResult({
    required int moduleId,
    required int quizId,
    required double percentage,
    required String quizContent,
  }) async {
    try {
      await _quizService.submitQuizResult(
        moduleId: moduleId,
        quizId: quizId,
        percentage: percentage,
        quizContent: quizContent,
      );
    } catch (e) {
      throw _handleRepositoryError(e);
    }
  }

  String _handleRepositoryError(dynamic error) {
    if (error is String) {
      switch (error.toLowerCase()) {
        case 'quiz not found':
          return 'The requested quiz does not exist';
        case 'permission denied':
          return 'You do not have permission to access this quiz';
        case 'network error occurred':
          return 'Please check your internet connection';
        case 'quiz already submitted':
          return 'You have already submitted this quiz';
        default:
          return error;
      }
    }
    return error.toString();
  }
}
