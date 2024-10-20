import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:learn_smart/services/api_service.dart';
import 'package:learn_smart/models/datastore.dart';
import 'package:learn_smart/models/note.dart';
import 'package:learn_smart/screens/widgets/app_bar.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';

class NotesDetailScreen extends StatefulWidget {
  final int noteId;
  final int moduleId;
  final bool isEditMode; // Added to handle edit mode

  NotesDetailScreen({
    Key? key,
    required this.noteId,
    required this.moduleId,
    this.isEditMode = false,
  }) : super(key: key);

  @override
  _NotesDetailScreenState createState() => _NotesDetailScreenState();
}

class _NotesDetailScreenState extends State<NotesDetailScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late Note note;
  late ApiService _apiService;
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      _apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
      _apiService.updateToken(authViewModel.user.token ?? '');

      await _loadNoteDetails();
    });
  }

  Future<void> _loadNoteDetails() async {
    try {
      // Fetch note details from DataStore or ApiService
      final noteList = DataStore.getNotes(widget.moduleId);
      note = noteList.firstWhere((n) => n.id == widget.noteId);

      if (widget.isEditMode) {
        // Pre-populate text controllers if in edit mode
        _titleController.text = note.title ?? '';
        _contentController.text = note.content ?? '';
      }

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

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isLoading
            ? 'Loading...'
            : widget.isEditMode
                ? 'Edit Note'
                : note.title,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(child: Text(_errorMessage))
              : widget.isEditMode
                  ? _buildEditNoteForm(note)
                  : _buildNoteView(note),
    );
  }

  Widget _buildEditNoteForm(Note note) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: 'Note Title'),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _contentController,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: 'Note Content',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.isNotEmpty &&
                  _contentController.text.isNotEmpty) {
                await _showSaveConfirmation();
              } else {
                _showErrorSnackBar('Please fill all fields.');
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteView(Note note) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            note.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // const SizedBox(height: 16),
        Expanded(
          // Ensure Markdown fills the available space
          child: Markdown(
            data: note.content.toString(),
            styleSheet: MarkdownStyleSheet(
              h1: TextStyle(fontSize: 24),
              h2: TextStyle(fontSize: 22),
              p: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showSaveConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Save Note'),
        content: Text('Are you sure you want to save this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, true);
              await _saveNote();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      _showSuccessSnackBar('Note saved successfully!');
      Navigator.pop(context);
    }
  }

  Future<void> _saveNote() async {
    try {
      await _apiService.updateNote(
        moduleId: widget.moduleId,
        noteId: note.id,
        title: _titleController.text,
        content: _contentController.text,
      );
      _showSuccessSnackBar('Note saved successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to save the note: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}
