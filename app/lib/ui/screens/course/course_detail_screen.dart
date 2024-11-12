import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimensions.dart';
import '../../../constants/text_styles.dart';
import '../../../providers/course_provider.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/gradient_background.dart';
import '../../../widgets/common/loading_overlay.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/course/course_info_section.dart';
import '../../../data/models/course.dart';
import '../../../ui/screens/modules/module_list_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;

  const CourseDetailScreen({
    Key? key,
    required this.courseId,
  }) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadCourseDetail());
  }

  Future<void> _loadCourseDetail() async {
    if (!mounted) return;
    try {
      final courseProvider =
          Provider.of<CourseProvider>(context, listen: false);
      await courseProvider.getCourseDetail(widget.courseId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, _) {
        final course = courseProvider.selectedCourse;
        final isLoading = courseProvider.isLoading;
        final error = courseProvider.error;

        return Scaffold(
          appBar: CustomAppBar(
            title: course.name.isEmpty ? 'Course Details' : course.name,
            actions: course.id != 0
                ? [
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.white,
                      ),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          // Navigate to edit screen
                        } else if (value == 'delete') {
                          await _showDeleteConfirmation(context, course.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit Course'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Course'),
                        ),
                      ],
                    ),
                  ]
                : null,
          ),
          body: LoadingOverlay(
            isLoading: isLoading,
            child: GradientBackground(
              colors: const [
                AppColors.background,
                AppColors.surface,
              ],
              child: error != null
                  ? _buildErrorState(error)
                  : course.id == 0 && !isLoading
                      ? _buildEmptyState()
                      : _buildContent(course),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: Dimensions.md),
            Text(
              'Error Loading Course',
              style: TextStyles.h3.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: Dimensions.sm),
            Text(
              error,
              style: TextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.lg),
            CustomButton(
              text: 'Retry',
              onPressed: _loadCourseDetail,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: Dimensions.md),
          Text(
            'Course Not Found',
            style: TextStyles.h3.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Course course) {
    return RefreshIndicator(
      onRefresh: _loadCourseDetail,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image Section
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.sm),
              child: course.imageUrl.isNotEmpty
                  ? Image.network(
                      course.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/images/default_course.png',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: Dimensions.lg),

            // Instructor Info Section
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/default_profile.png'),
                  radius: 20,
                ),
                const SizedBox(width: Dimensions.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Course by',
                      style: TextStyles.bodySmall,
                    ),
                    Text(
                      course.createdByUsername,
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Dimensions.xl),

            // Course Overview Section
            Text(
              'Course Overview',
              style: TextStyles.h3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Dimensions.md),
            Text(
              course.description,
              style: TextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: Dimensions.md),
            Text(
              'Course Code: ${course.courseCode}',
              style: TextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            // Students Count
            const SizedBox(height: Dimensions.md),
            Row(
              children: const [
                Icon(
                  Icons.group_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                SizedBox(width: Dimensions.xs),
                Text(
                  'students enrolled',
                  style: TextStyles.bodyMedium,
                ),
              ],
            ),

            const SizedBox(height: Dimensions.xl),

            // Modules Section
            Text(
              'Modules',
              style: TextStyles.h3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Dimensions.md),

            // Module List
            SizedBox(
              height: 400,
              child: ModuleListScreen(
                courseId: course.id,
                embedded: true,
              ),
            ),

            // Action Buttons for instructor
            if (course.createdByUsername.isNotEmpty) ...[
              const SizedBox(height: Dimensions.xl),
              CustomButton(
                text: 'Add Module',
                onPressed: () {
                  // TODO: Implement add module functionality
                },
                backgroundColor: AppColors.primary,
                width: double.infinity,
              ),
              const SizedBox(height: Dimensions.md),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Edit Course',
                      onPressed: () {
                        // TODO: Implement edit course functionality
                      },
                      backgroundColor: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: Dimensions.md),
                  Expanded(
                    child: CustomButton(
                      text: 'Delete Course',
                      onPressed: () =>
                          _showDeleteConfirmation(context, course.id),
                      backgroundColor: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, int courseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: const Text(
          'Are you sure you want to delete this course? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final courseProvider =
            Provider.of<CourseProvider>(context, listen: false);
        await courseProvider.deleteCourse(courseId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }
}
