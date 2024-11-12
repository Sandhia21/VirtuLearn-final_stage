import 'package:flutter/material.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/registration_screen.dart';
import '../ui/screens/auth/welcome_screen.dart';
import '../ui/screens/course/course_detail_screen.dart';
import '../ui/screens/course/course_list_screen.dart';
import '../ui/screens/home/home_screen.dart';
import '../ui/screens/modules/module_detail_screen.dart';
import '../ui/screens/modules/module_list_screen.dart';
import '../ui/screens/notes/note_detail_screen.dart';
import '../ui/screens/notes/notes_list_screen.dart';
import '../ui/screens/quiz/quiz_detail_screen.dart';
import '../ui/screens/quiz/results_screen.dart';
import '../ui/controllers/quiz_controller.dart';

class AppRoutes {
  // Auth Routes
  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Main Routes
  static const String home = '/home';

  // Course Routes
  static const String courseList = '/course-list';
  static const String courseDetail = '/course-detail';

  // Module Routes
  static const String moduleList = '/module-list';
  static const String moduleDetail = '/module-detail';

  // Note Routes
  static const String notesList = '/notes-list';
  static const String noteDetail = '/note-detail';

  // Quiz Routes
  static const String quizDetail = '/quiz-detail';
  static const String quizResults = '/quiz-results';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth Routes
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegistrationScreen());

      // Main Routes
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      // Course Routes
      case courseList:
        return MaterialPageRoute(builder: (_) => const CourseListScreen());

      case courseDetail:
        final courseId = settings.arguments as int?;
        if (courseId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Invalid course ID')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => CourseDetailScreen(courseId: courseId),
        );

      // Module Routes
      case moduleList:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || !args.containsKey('courseId')) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Invalid module list parameters')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ModuleListScreen(
            courseId: args['courseId'] as int,
          ),
        );

      case moduleDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null ||
            !args.containsKey('moduleId') ||
            !args.containsKey('courseId')) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Invalid module parameters')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ModuleDetailScreen(
            moduleId: args['moduleId'] as int,
            courseId: args['courseId'] as int,
          ),
        );

      // Note Routes
      case notesList:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || !args.containsKey('moduleId')) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Invalid notes list parameters')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => NotesListScreen(
            moduleId: args['moduleId'] as int,
          ),
        );

      case noteDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || !args.containsKey('moduleId')) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Invalid note parameters')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => NoteDetailScreen(
            moduleId: args['moduleId'] as int,
            noteId: args['noteId'] as int?,
          ),
        );

      // Quiz Routes
      case quizDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null ||
            !args.containsKey('quizId') ||
            !args.containsKey('moduleId')) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Invalid quiz parameters')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => QuizDetailScreen(
            quizId: args['quizId'] as int,
            moduleId: args['moduleId'] as int,
          ),
        );

      case quizResults:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Invalid quiz results parameters')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ResultsScreen(
            quizId: args['quizId'] as int,
            moduleId: args['moduleId'] as int,
            score: args['score'] as double,
            questions: args['questions'] as List<ParsedQuestion>,
            answers: args['answers'] as Map<String, String>,
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
