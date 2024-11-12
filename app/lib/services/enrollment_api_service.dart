import 'package:dio/dio.dart';
import 'api_config.dart';

class EnrollmentApiService {
  final Dio _dio;

  EnrollmentApiService() : _dio = ApiConfig.dio;

  Future<List<dynamic>> fetchTeacherEnrollmentRequests() async {
    try {
      final response = await _dio.get('/enrollments/teacher/');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> fetchStudentEnrollmentRequests() async {
    try {
      final response = await _dio.get('/enrollments/student/');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> respondToEnrollment(int requestId, bool isApproved) async {
    try {
      await _dio.post('/enrollments/$requestId/respond/', data: {
        'is_approved': isApproved,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      if (e.response!.statusCode == 401) {
        return 'Please login to manage enrollments';
      }
      if (e.response!.data is Map) {
        return e.response!.data['detail'] ?? 'An error occurred';
      }
      return e.response!.statusMessage ?? 'An error occurred';
    }
    return e.message ?? 'Network error occurred';
  }
}
