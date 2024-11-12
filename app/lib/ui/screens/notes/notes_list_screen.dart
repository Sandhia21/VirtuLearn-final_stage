import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimensions.dart';
import '../../../constants/text_styles.dart';
import '../../../providers/note_provider.dart';
import 'package:app/widgets/widgets.dart';

class NotesListScreen extends StatefulWidget {
  final int moduleId;

  const NotesListScreen({
    Key? key,
    required this.moduleId,
  }) : super(key: key);

  @override
  _NotesListScreenState createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotes();
    });
  }

  Future<void> _loadNotes() async {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    await noteProvider
        .loadNotes(widget.moduleId); // Changed from getNotes to loadNotes
  }

  void _createNote() {
    Navigator.pushNamed(
      context,
      '/note-detail',
      arguments: {'moduleId': widget.moduleId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notes',
          style: TextStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Consumer<NoteProvider>(
        builder: (context, noteProvider, child) {
          return LoadingOverlay(
            isLoading: noteProvider.isLoading,
            child: RefreshIndicator(
              onRefresh: _loadNotes,
              child: noteProvider.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            noteProvider.error!,
                            style: TextStyles.error,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: Dimensions.md),
                          CustomButton(
                            text: 'Retry',
                            onPressed: _loadNotes,
                            width: 120,
                          ),
                        ],
                      ),
                    )
                  : noteProvider.notes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'No notes yet',
                                style: TextStyles.bodyLarge,
                              ),
                              const SizedBox(height: Dimensions.md),
                              CustomButton(
                                text: 'Create Note',
                                onPressed: _createNote,
                                width: 150,
                                icon: Icons.add,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(Dimensions.md),
                          itemCount: noteProvider.notes.length,
                          itemBuilder: (context, index) {
                            final note = noteProvider.notes[index];
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: Dimensions.md,
                              ),
                              child: NoteCard(
                                note: note,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/note-detail',
                                  arguments: {
                                    'moduleId': widget.moduleId,
                                    'noteId': note.id,
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
