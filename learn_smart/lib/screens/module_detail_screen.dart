import 'package:flutter/material.dart';
import 'package:learn_smart/services/api_service.dart';
import 'package:learn_smart/models/datastore.dart';
import 'package:learn_smart/models/note.dart' as modelsNote;
import 'package:learn_smart/models/quiz.dart' as modelsQuiz;
import 'package:learn_smart/view_models/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'notes_detail_screen.dart';
import 'quiz_detail_screen.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final modelsNote.Note note = notes[index];
                return Card(
                  color: Colors
                      .white, // Set the background color of the card to white
                  elevation: 4.0, // Add elevation to give a shadow effect
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 16.0), // Center the content
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.note,
                            color: Color.fromARGB(255, 217, 224, 229)),
                      ),
                      title: Text(
                        note.title ?? 'Untitled Note',
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
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
              // padding: const EdgeInsets.all(8.0),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final modelsQuiz.Quiz quiz = quizzes[index];
                return Card(
                  color: Colors
                      .white, // Set the background color of the card to white
                  elevation: 4.0, // Add elevation to give a shadow effect
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 16.0),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.question_answer,
                            color: Colors.white),
                      ),
                      title: Text(quiz.title ?? 'Untitled Quiz'),
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
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
              onPressed: () {
                // createQuiz();
              },
              child: Text('Create Quiz'))
        ],
      ),
    );
  }

  void _showEditQuizDialog(modelsQuiz.Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizDetailScreen(
            quizId: quiz.id,
            moduleId: widget.moduleId,
            isStudentEnrolled: false,
            isEditMode: false // Pass edit mode
            ),
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
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
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Enter Topic'),
              onSaved: (value) {
                _topic = value;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a topic';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
              child: const Text('Create'),
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
                    child: Icon(Icons.add),
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
              ],
              onTap: (index) {
                setState(() {
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildNotesSection(),
                        _buildQuizzesSection(),
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
                TextFormField(
                  decoration: InputDecoration(labelText: 'Title'),
                  onSaved: (value) {
                    _title = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Content'),
                  onSaved: (value) {
                    _content = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter content';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
              style: ElevatedButton.styleFrom(
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  await _apiService.createNote(widget.moduleId,
                      _title ?? 'Untitled', _content ?? 'No content');
                  Navigator.of(context).pop();
                  await _apiService.fetchNotes(widget.moduleId);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
