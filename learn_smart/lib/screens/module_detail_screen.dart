import 'package:flutter/material.dart';
import 'package:learn_smart/services/api_service.dart';
import 'package:learn_smart/models/datastore.dart';
import 'package:learn_smart/models/note.dart' as modelsNote;
import 'package:learn_smart/models/quiz.dart' as modelsQuiz;
import 'package:learn_smart/view_models/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'notes_detail_screen.dart';
import 'quiz_detail_screen.dart';
import 'widgets/custom_card.dart';
import 'widgets/custom_button.dart';
import 'widgets/custom_form_field.dart';

class ModuleDetailScreen extends StatefulWidget {
  final int moduleId;

  ModuleDetailScreen({
    Key? key,
    required this.moduleId,
  }) : super(key: key);

  @override
  _ModuleDetailScreenState createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen>
    with SingleTickerProviderStateMixin {
  String moduleTitle = "Loading...";
  String moduleDescription = "Loading description...";
  late TabController _tabController;
  late ApiService _apiService;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isSelectionMode = false;
  List<int> _selectedNoteIds = []; // Store selected note IDs

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      _apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
      _apiService.updateToken(authViewModel.user.token ?? '');

      await _loadModuleDetails();
    });
  }

  Future<void> _loadModuleDetails() async {
    try {
      final module = DataStore.getModuleById(widget.moduleId);

      setState(() {
        moduleTitle = module?.title ?? "Unknown Module Title";
        moduleDescription = module?.description ?? "No description available";
        _isLoading = false;
      });

      await _apiService.fetchNotes(widget.moduleId);
      await _apiService.fetchQuizzes(widget.moduleId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _toggleNoteSelection(int noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
      } else {
        _selectedNoteIds.add(noteId);
      }
    });
  }

  Future<void> _generateQuiz() async {
    if (_selectedNoteIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select at least one note.")),
      );
      return;
    }
    Provider.of<ApiService>(context, listen: false);

    try {
      await _apiService.generateQuizForMultipleNotes(
          widget.moduleId, _selectedNoteIds);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Quiz generated successfully!")),
      );
      setState(() {
        _selectedNoteIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating quiz: $e")),
      );
    }
  }

  Widget _buildNotesSection() {
    final notes = DataStore.getNotes(widget.moduleId);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    bool isTeacher = authViewModel.user.role == 'teacher';
    String truncateWithEllipsis(int cutoff, String myString) {
      return (myString.length <= cutoff)
          ? myString
          : '${myString.substring(0, cutoff)}...';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final modelsNote.Note note = notes[index];
                return CustomCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0), // Center the content
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.note,
                          color: Color.fromARGB(255, 217, 224, 229)),
                    ),
                    title: Text(
                      truncateWithEllipsis(50, note.title),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    trailing: isTeacher
                        ? _isSelectionMode
                            ? Checkbox(
                                value: _selectedNoteIds.contains(note.id),
                                onChanged: (bool? value) {
                                  _toggleNoteSelection(note.id);
                                },
                              )
                            : _buildNotePopupMenu(note)
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotesDetailScreen(
                            noteId: note.id,
                            moduleId: widget.moduleId,
                          ),
                        ),
                      );
                    },
                    onLongPress: isTeacher
                        ? () {
                            _toggleNoteSelection(note.id);
                          }
                        : null,
                    selected: _selectedNoteIds.contains(note.id),
                  ),
                );
              },
            ),
          ),
          if (isTeacher)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () => _showAIInputDialog(context),
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Use AI to Create Notes'),
              ),
            ),
        ],
      ),
    );
  }

  void _showEditNoteDialog(modelsNote.Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotesDetailScreen(
            noteId: note.id,
            moduleId: widget.moduleId,
            isEditMode: true), // Pass edit mode
      ),
    );
  }

  Widget _buildNotePopupMenu(modelsNote.Note note) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'Edit') {
          _showEditNoteDialog(note);
        } else if (value == 'Delete') {
          _confirmDeleteNote(note);
        } else if (value == 'Generate AI Quiz') {
          _generateAIQuiz(note.id);
        } else if (value == "Select") {
          setState(() {
            _isSelectionMode = !_isSelectionMode; // Toggle selection mode
          });
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'Edit',
          child: Text('Edit'),
        ),
        const PopupMenuItem(
          value: 'Delete',
          child: Text('Delete'),
        ),
        const PopupMenuItem(
          value: 'Generate AI Quiz',
          child: Text('Generate AI Quiz'),
        ),
        const PopupMenuItem(
          value: 'Select',
          child: Text('Select'),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteNote(modelsNote.Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this note?'),
        actions: [
          CustomButton(
            text: 'Cancel',
            backgroundColor: Colors.grey,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CustomButton(
            text: 'Delete',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteNote(note);
    }
  }

  Future<void> _generateAIQuiz(int noteId) async {
    try {
      String quizTitle = 'Quiz for Note $noteId'; // Set dynamic quiz title
      await _apiService.generateQuizFromNotes(
          moduleId: widget.moduleId, quizTitle: quizTitle, noteId: noteId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI quiz generated successfully')),
      );
      await _apiService.fetchQuizzes(widget.moduleId); // Refresh quizzes
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating AI quiz: $e')),
      );
    }
  }

  Widget _buildQuizzesSection() {
    final quizzes = DataStore.getQuizzes(widget.moduleId);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    bool isTeacher = authViewModel.user.role == 'teacher';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final modelsQuiz.Quiz quiz = quizzes[index];
                return CustomCard(
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.question_answer,
                          color: Colors.white),
                    ),
                    title: Text(quiz.title),
                    trailing: isTeacher ? _buildQuizPopupMenu(quiz) : null,
                    onTap: () {
                      if (authViewModel.user.role == 'student') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizDetailScreen(
                              quizId: quiz.id,
                              moduleId: widget.moduleId,
                              isStudentEnrolled: true,
                            ),
                          ),
                        );
                      } else if (authViewModel.user.role == 'teacher') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizDetailScreen(
                              quizId: quiz.id,
                              moduleId: widget.moduleId,
                              isStudentEnrolled: false, // For teachers
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
          if (isTeacher)
            ElevatedButton(
              onPressed: () {
                // Call the method to open the quiz creation dialog
                _showCreateQuizDialog(widget.moduleId);
              },
              child: const Text('Create Quiz'),
              style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder()),
            ),
        ],
      ),
    );
  }

  // Add these as instance variables to your existing class
  late final _inputDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    filled: true,
    fillColor: Colors.grey[50],
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  late final _buttonStyle = ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    foregroundColor: Colors.white,
    backgroundColor: Colors.blue,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  );

// Custom form field widget method
  Widget _buildFormField({
    required String label,
    required void Function(String?) onSaved,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: _inputDecoration.copyWith(labelText: label),
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
        onSaved: onSaved,
        keyboardType: keyboardType,
      ),
    );
  }

  void _showCreateQuizDialog(int moduleId) {
    final formKey = GlobalKey<FormState>();
    String? title, description, currentQuestion, correctAnswer;
    int? quizDuration;
    String content = '';
    final options = <String, String?>{};
    int currentPhase = 1;
    int questionCount = 0;

    void addQuestionToContent() {
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();
        content += "${questionCount + 1}) $currentQuestion\n";
        options.forEach((key, value) {
          content += "$key) $value\n";
        });
        content += "Correct Answer: $correctAnswer\n\n";

        // Reset current question data
        currentQuestion = null;
        options.clear();
        correctAnswer = null;
        formKey.currentState!.reset();
        questionCount++;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Widget buildQuizDetailsPhase() {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Quiz',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      label: 'Quiz Title',
                      onSaved: (value) => title = value,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Description',
                      onSaved: (value) => description = value,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Duration (minutes)',
                      onSaved: (value) =>
                          quizDuration = int.tryParse(value ?? ''),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                          setState(() => currentPhase = 2);
                        }
                      },
                      style: _buildButtonStyle(Colors.blue),
                      child: const Text('Next'),
                    ),
                  ],
                ),
              );
            }

            Widget buildQuestionPhase() {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add Question ${questionCount + 1}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      label: 'Question',
                      onSaved: (value) => currentQuestion = value,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ...['A', 'B', 'C', 'D'].map((option) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildInputField(
                            label: 'Option $option',
                            onSaved: (value) => options[option] = value,
                          ),
                        )),
                    _buildInputField(
                      label: 'Correct Answer (A/B/C/D)',
                      onSaved: (value) => correctAnswer = value?.toUpperCase(),
                      validator: (value) {
                        if (value == null ||
                            !['A', 'B', 'C', 'D']
                                .contains(value.toUpperCase())) {
                          return 'Please enter a valid answer (A, B, C, or D)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // First row of buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: _buildButtonStyle(Colors.grey),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              addQuestionToContent();
                              setState(() {});
                            },
                            style: _buildButtonStyle(Colors.blue),
                            child: const Text('Add Question'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Create button in second row
                    if (questionCount > 0)
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            addQuestionToContent();
                            await _apiService.createQuiz(
                              moduleId,
                              title!,
                              description!,
                              content,
                              quizDuration.toString(),
                            );
                            Navigator.of(context).pop();
                          }
                        },
                        style: _buildButtonStyle(Colors.green),
                        child: const Text('Create Quiz'),
                      ),
                  ],
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: currentPhase == 1
                    ? buildQuizDetailsPhase()
                    : buildQuestionPhase(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField({
    required String label,
    required void Function(String?) onSaved,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
      onSaved: onSaved,
    );
  }

  ButtonStyle _buildButtonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 12,
      ),
    );
  }

  void _showEditQuizDialog(modelsQuiz.Quiz quiz) {
    final formKey = GlobalKey<FormState>();
    TextEditingController titleController =
        TextEditingController(text: quiz.title);
    TextEditingController descriptionController =
        TextEditingController(text: quiz.description);
    TextEditingController durationController =
        TextEditingController(text: quiz.quizDuration.toString());
    String? currentQuestion, correctAnswer;
    String content = quiz.content ?? '';
    final options = <String, String?>{};
    int currentPhase = 1;
    int questionCount = 0;

    // Parse existing questions from content
    List<Map<String, dynamic>> existingQuestions = [];
    if (content.isNotEmpty) {
      final questionBlocks = content.split('\n\n');
      for (var block in questionBlocks) {
        if (block.trim().isEmpty) continue;

        final lines = block.split('\n');
        if (lines.isEmpty) continue;

        final questionMap = <String, dynamic>{};
        // Parse question
        final questionMatch = RegExp(r'^\d+\) (.+)$').firstMatch(lines[0]);
        if (questionMatch != null) {
          questionMap['question'] = questionMatch.group(1);
          questionMap['options'] = <String, String>{};

          // Parse options
          for (int i = 1; i < lines.length - 1; i++) {
            final optionMatch =
                RegExp(r'^([A-D])\) (.+)$').firstMatch(lines[i]);
            if (optionMatch != null) {
              questionMap['options']![optionMatch.group(1)!] =
                  optionMatch.group(2)!;
            }
          }

          // Parse correct answer
          final answerMatch =
              RegExp(r'^Correct Answer: ([A-D])$').firstMatch(lines.last);
          if (answerMatch != null) {
            questionMap['correctAnswer'] = answerMatch.group(1);
          }

          existingQuestions.add(questionMap);
        }
      }
      questionCount = existingQuestions.length;
    }

    void addQuestionToContent() {
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();
        content += "${questionCount + 1}) $currentQuestion\n";
        options.forEach((key, value) {
          content += "$key) $value\n";
        });
        content += "Correct Answer: $correctAnswer\n\n";

        // Reset current question data
        currentQuestion = null;
        options.clear();
        correctAnswer = null;
        formKey.currentState!.reset();
        questionCount++;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Widget buildQuizDetailsPhase() {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Quiz',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    CustomFormField(
                      label: 'Quiz Title',
                      controller: titleController,
                    ),
                    const SizedBox(height: 16),
                    CustomFormField(
                      label: 'Description',
                      controller: descriptionController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    CustomFormField(
                      label: 'Duration (minutes)',
                      controller: durationController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Next',
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                          setState(() => currentPhase = 2);
                        }
                      },
                    ),
                  ],
                ),
              );
            }

            Widget buildQuestionPhase() {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Edit Question ${questionCount + 1}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      label: 'Question',
                      onSaved: (value) => currentQuestion = value,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ...['A', 'B', 'C', 'D'].map((option) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildInputField(
                            label: 'Option $option',
                            onSaved: (value) => options[option] = value,
                          ),
                        )),
                    _buildInputField(
                      label: 'Correct Answer (A/B/C/D)',
                      onSaved: (value) => correctAnswer = value?.toUpperCase(),
                      validator: (value) {
                        if (value == null ||
                            !['A', 'B', 'C', 'D']
                                .contains(value.toUpperCase())) {
                          return 'Please enter a valid answer (A, B, C, or D)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // First row of buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: _buildButtonStyleEdit(Colors.grey),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              addQuestionToContent();
                              setState(() {});
                            },
                            style: _buildButtonStyleEdit(Colors.blue),
                            child: const Text('Add Question'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Save button in second row
                    if (questionCount > 0 || existingQuestions.isNotEmpty)
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            if (currentQuestion != null) {
                              addQuestionToContent();
                            }
                            await _apiService.updateQuiz(
                              moduleId: widget.moduleId,
                              quizId: quiz.id,
                              title: titleController.text,
                              description: descriptionController.text,
                              content: content,
                            );
                            Navigator.of(context).pop();
                            await _apiService.fetchQuizzes(widget.moduleId);
                          }
                        },
                        style: _buildButtonStyleEdit(Colors.green),
                        child: const Text('Save Changes'),
                      ),
                  ],
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: currentPhase == 1
                    ? buildQuizDetailsPhase()
                    : buildQuestionPhase(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputFieldEdit({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
    );
  }

  ButtonStyle _buildButtonStyleEdit(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 12,
      ),
    );
  }

  Future<void> _confirmDeleteQuiz(modelsQuiz.Quiz quiz) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this quiz?'),
        actions: [
          CustomButton(
            text: 'Cancel',
            backgroundColor: Colors.grey,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CustomButton(
            text: 'Delete',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteQuiz(quiz);
    }
  }

  Widget _buildQuizPopupMenu(modelsQuiz.Quiz quiz) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'Edit') {
          _showEditQuizDialog(quiz);
        } else if (value == 'Delete') {
          await _confirmDeleteQuiz(quiz);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'Edit',
          child: Text('Edit'),
        ),
        const PopupMenuItem(
          value: 'Delete',
          child: Text('Delete'),
        ),
      ],
    );
  }

  Future<void> _showAIInputDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    String? _topic;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Generate Notes Using AI'),
          content: Form(
            key: _formKey,
            child: CustomFormField(
              label: 'Enter Topic',
              onSaved: (value) => _topic = value,
            ),
          ),
          actions: [
            CustomButton(
              text: 'Cancel',
              backgroundColor: Colors.grey,
              onPressed: () => Navigator.of(context).pop(),
            ),
            CustomButton(
              text: 'Create',
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  if (_topic != null) {
                    await _createAINote(
                        topic: _topic!, moduleId: widget.moduleId);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('AI note created'),
                        backgroundColor: Colors.greenAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _createAINote(
      {required String topic, required int moduleId}) async {
    try {
      await _apiService.generateAINoteForModule(moduleId, topic);
      await _apiService.fetchNotes(moduleId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating AI note: $e')),
      );
    }
  }

  Future<void> _deleteNote(modelsNote.Note note) async {
    try {
      await _apiService.deleteNote(moduleId: widget.moduleId, noteId: note.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note Deleted successfully')),
      );
      await _apiService.fetchNotes(widget.moduleId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting note: $e')),
      );
    }
  }

  Future<void> _deleteQuiz(modelsQuiz.Quiz quiz) async {
    try {
      await _apiService.deleteQuiz(
        moduleId: widget.moduleId,
        quizId: quiz.id,
      );
      await _apiService.fetchQuizzes(widget.moduleId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting quiz: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        toolbarHeight: 80,
        title: Text(
          moduleTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(child: Text(_errorMessage))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModuleHeader(),
                    _buildTabs(),
                  ],
                ),
      floatingActionButton: _tabController.index == 0 &&
              Provider.of<AuthViewModel>(context, listen: false).user.role ==
                  'teacher'
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: FloatingActionButton(
                    onPressed: () => _showCreateNoteDialog(context),
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.add, color: Colors.white),
                    heroTag: "createNote",
                  ),
                ),
                SizedBox(height: 16), // Space between buttons
                FloatingActionButton(
                  onPressed: _generateQuiz,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.question_answer),
                  heroTag: "generateQuiz",
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildModuleHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            moduleTitle,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            moduleDescription,
            style: TextStyle(
                fontSize: 16, color: const Color.fromARGB(255, 155, 145, 145)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Expanded(
      child: Column(
        children: [
          TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black,
              tabs: [
                Tab(text: "Notes"),
                Tab(text: "Quizzes"),
                Tab(text: "Results"),
              ],
              onTap: (index) {
                setState(() {
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildNotesSection(),
                        _buildQuizzesSection(),
                        _buildResultsSection(),
                      ],
                    ),
                  );
                });
              }),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotesSection(),
                _buildQuizzesSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    bool isTeacher = authViewModel.user.role == 'teacher';

    if (isTeacher) {
      return _buildTeacherResultsView();
    } else {
      return _buildStudentResultsView();
    }
  }

  Widget _buildTeacherResultsView() {
    final quizzes = DataStore.getQuizzes(widget.moduleId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListView.builder(
        itemCount: quizzes.length,
        itemBuilder: (context, index) {
          final quiz = quizzes[index];
          return CustomCard(
            child: ListTile(
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: const Icon(Icons.leaderboard, color: Colors.white),
              ),
              title: Text(quiz.title),
              subtitle: Text('View student results'),
              onTap: () => _showQuizLeaderboard(quiz.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentResultsView() {
    final quizzes = DataStore.getQuizzes(widget.moduleId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListView.builder(
        itemCount: quizzes.length,
        itemBuilder: (context, index) {
          final quiz = quizzes[index];
          return FutureBuilder<Map<String, dynamic>>(
            future: _apiService.getQuizResult(quiz.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return CustomCard(
                  child: ListTile(
                    title: Text('Error loading results'),
                    subtitle: Text(snapshot.error.toString()),
                  ),
                );
              }

              final result = snapshot.data;
              if (result == null) {
                return CustomCard(
                  child: ListTile(
                    title: Text(quiz.title),
                    subtitle: Text('No attempt yet'),
                  ),
                );
              }

              return CustomCard(
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text('${result['percentage']}%'),
                  ),
                  title: Text(quiz.title),
                  subtitle:
                      Text('Score: ${result['score']}/${result['total']}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Recommendations:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(result['ai_recommendations'] ??
                              'No recommendations available'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showQuizLeaderboard(int quizId) async {
    try {
      final leaderboard = await _apiService.getQuizLeaderboard(quizId);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Quiz Leaderboard'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final entry = leaderboard[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(entry['student_name']),
                  trailing: Text('${entry['percentage']}%'),
                  subtitle: Text('Score: ${entry['score']}/${entry['total']}'),
                );
              },
            ),
          ),
          actions: [
            CustomButton(
              text: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading leaderboard: $e')),
      );
    }
  }

  Future<void> _showCreateNoteDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    String? _title;
    String? _content;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create Note'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomFormField(
                  label: 'Title',
                  onSaved: (value) => _title = value,
                ),
                SizedBox(height: 16),
                CustomFormField(
                  label: 'Content',
                  onSaved: (value) => _content = value,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            CustomButton(
              text: 'Cancel',
              backgroundColor: Colors.grey,
              onPressed: () => Navigator.of(context).pop(),
            ),
            CustomButton(
              text: 'Create',
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  await _apiService.createNote(widget.moduleId,
                      _title ?? 'Untitled', _content ?? 'No content');
                  Navigator.of(context).pop();
                  await _apiService.fetchNotes(widget.moduleId);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
