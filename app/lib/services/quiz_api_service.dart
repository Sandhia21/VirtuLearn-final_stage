import 'package:dio/dio.dart';
import 'api_config.dart';

class QuizApiService {
  final Dio _dio;

  QuizApiService() : _dio = ApiConfig.dio;

  Future<List<dynamic>> fetchQuizzes(int moduleId) async {
    try {
      final response = await _dio.get('/modules/$moduleId/quizzes/');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createQuiz({
    required int moduleId,
    required String title,
    required String description,
    required String content,
    required String quizDuration,
  }) async {
    try {
      final response = await _dio.post(
        '/modules/$moduleId/quizzes/',
        data: {
          'title': title,
          'description': description,
          'content': content,
          'quiz_duration': quizDuration,
          'module': moduleId,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getQuizDetail(int moduleId, int quizId) async {
    try {
      final response = await _dio.get('/modules/$moduleId/quizzes/$quizId/');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> submitQuizResult({
    required int moduleId,
    required int quizId,
    required double percentage,
    required String quizContent,
  }) async {
    try {
      final response = await _dio.post(
        '/modules/$moduleId/quizzes/$quizId/submit/',
        data: {
          'percentage': percentage,
          'quiz_content': quizContent,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      if (e.response!.statusCode == 401) {
        return 'Please login to access quiz content';
      }
      if (e.response!.data is Map) {
        return e.response!.data['detail'] ?? 'An error occurred';
      }
      return e.response!.statusMessage ?? 'An error occurred';
    }
    return e.message ?? 'Network error occurred';
  }
}
