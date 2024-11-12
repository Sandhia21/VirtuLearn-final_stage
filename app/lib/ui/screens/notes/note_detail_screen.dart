import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/constants/constants.dart';
import '../../../providers/note_provider.dart';
import 'package:app/widgets/widgets.dart';

class NoteDetailScreen extends StatefulWidget {
  final int moduleId;
  final int? noteId;

  const NoteDetailScreen({
    Key? key,
    required this.moduleId,
    this.noteId,
  }) : super(key: key);

  @override
  _NoteDetailScreenState createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.noteId != null;
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadNote();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    try {
      final noteProvider = Provider.of<NoteProvider>(context, listen: false);
      final note = await noteProvider
          .getNote(widget.noteId!); // Changed from loadNotes to getNote
      setState(() {
        _titleController.text = note.title;
        _contentController.text = note.content;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final noteProvider = Provider.of<NoteProvider>(context, listen: false);
      if (_isEditing) {
        await noteProvider.updateNote(
          widget.moduleId, // Added moduleId
          widget.noteId!,
          _titleController.text,
          _contentController.text,
        );
      } else {
        await noteProvider.createNote(
          widget.moduleId,
          _titleController.text,
          _contentController.text,
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
          'Are you sure you want to delete this note? This action cannot be undone.',
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

    if (confirmed == true) {
      try {
        final noteProvider = Provider.of<NoteProvider>(context, listen: false);
        await noteProvider.deleteNote(
          widget.moduleId, // Added moduleId
          widget.noteId!,
        );
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Note' : 'New Note',
          style: TextStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteNote,
            ),
        ],
      ),
      body: Consumer<NoteProvider>(
        builder: (context, noteProvider, child) {
          return LoadingOverlay(
            isLoading: noteProvider.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.md),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _titleController,
                      labelText: 'Title',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Dimensions.md),
                    CustomTextField(
                      controller: _contentController,
                      labelText: 'Content',
                      maxLines: 10,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some content';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Dimensions.xl),
                    CustomButton(
                      text: _isEditing ? 'Update Note' : 'Save Note',
                      onPressed: _saveNote,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
