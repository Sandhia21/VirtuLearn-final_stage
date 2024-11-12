import '../models/enrollment.dart';
import '../../services/enrollment_api_service.dart';

class EnrollmentRepository {
  final EnrollmentApiService _enrollmentService;

  EnrollmentRepository(this._enrollmentService);

  Future<List<EnrollmentRequest>> fetchTeacherEnrollmentRequests() async {
    try {
      final response =
          await _enrollmentService.fetchTeacherEnrollmentRequests();
      return response
          .map((request) => EnrollmentRequest.fromJson(request))
          .toList();
    } catch (e) {
      throw _handleRepositoryError(e);
    }
  }

  Future<List<StudentEnrollmentRequest>>
      fetchStudentEnrollmentRequests() async {
    try {
      final response =
          await _enrollmentService.fetchStudentEnrollmentRequests();
      return response
          .map((request) => StudentEnrollmentRequest.fromJson(request))
          .toList();
    } catch (e) {
      throw _handleRepositoryError(e);
    }
  }

  Future<void> respondToEnrollment(int requestId, bool isApproved) async {
    try {
      await _enrollmentService.respondToEnrollment(requestId, isApproved);
    } catch (e) {
      throw _handleRepositoryError(e);
    }
  }

  String _handleRepositoryError(dynamic error) {
    if (error is String) {
      switch (error.toLowerCase()) {
        case 'enrollment request not found':
          return 'The enrollment request no longer exists';
        case 'permission denied':
          return 'You do not have permission to manage enrollments';
        case 'network error occurred':
          return 'Please check your internet connection';
        case 'request already processed':
          return 'This enrollment request has already been processed';
        case 'course is full':
          return 'Cannot approve enrollment as the course is full';
        default:
          return error;
      }
    }
    return error.toString();
  }
}
