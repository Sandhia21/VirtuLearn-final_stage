import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimensions.dart';
import '../../../constants/text_styles.dart';
import '../../../providers/module_provider.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/loading_overlay.dart';
import '../../../widgets/module/notes_section.dart';
import '../../../widgets/module/quiz_section.dart';
import '../../../widgets/module/results_section.dart';
import '../../../providers/quiz_provider.dart';

class ModuleDetailScreen extends StatefulWidget {
  final int moduleId;
  final int courseId;

  const ModuleDetailScreen({
    super.key,
    required this.moduleId,
    required this.courseId,
  });

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _quizId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadModuleDetails();
      _loadQuizDetails();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadModuleDetails() async {
    final moduleProvider = Provider.of<ModuleProvider>(context, listen: false);
    await moduleProvider.fetchModuleDetails(widget.moduleId);
  }

  Future<void> _loadQuizDetails() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    await quizProvider.fetchQuizzes(widget.moduleId);

    if (mounted) {
      setState(() {
        // Get the first quiz ID if available
        _quizId = quizProvider.quizzes.isNotEmpty
            ? quizProvider.quizzes.first.id
            : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Module Details',
      ),
      body: Consumer<ModuleProvider>(
        builder: (context, moduleProvider, child) {
          if (moduleProvider.isLoading) {
            return const LoadingOverlay(
              isLoading: true,
              child: SizedBox.expand(),
            );
          }

          if (moduleProvider.error != null) {
            return Center(
              child: Text(
                moduleProvider.error!,
                style: TextStyles.error,
                textAlign: TextAlign.center,
              ),
            );
          }

          final module = moduleProvider.selectedModule;
          if (module == null) {
            return const Center(
              child: Text(
                'Module not found',
                style: TextStyles.bodyLarge,
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(Dimensions.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.title, style: TextStyles.h2),
                    const SizedBox(height: Dimensions.sm),
                    Text(
                      module.description,
                      style: TextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.grey,
                tabs: const [
                  Tab(text: 'Notes'),
                  Tab(text: 'Quiz'),
                  Tab(text: 'Results'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    NotesSection(moduleId: widget.moduleId),
                    QuizSection(moduleId: widget.moduleId),
                    ResultSection(
                      moduleId: widget.moduleId,
                      quizId: _quizId!,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
