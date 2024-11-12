import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/dimensions.dart';
import '../../constants/text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/note_provider.dart';
import '../../data/models/note.dart';
import '../common/loading_overlay.dart';
import '../common/custom_button.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class NotesSection extends StatefulWidget {
  final int moduleId;

  const NotesSection({
    super.key,
    required this.moduleId,
  });

  @override
  State<NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<NotesSection> {
  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    if (!mounted) return;
    final notesProvider = Provider.of<NoteProvider>(context, listen: false);
    await notesProvider.loadNotes(widget.moduleId);
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher =
        Provider.of<AuthProvider>(context).user?.role == 'teacher';

    return Consumer<NoteProvider>(
      builder: (context, notesProvider, child) {
        if (notesProvider.isLoading) {
          return const LoadingOverlay(
            isLoading: true,
            child: SizedBox.expand(),
          );
        }

        if (notesProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading notes',
                  style: TextStyles.h3.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: Dimensions.sm),
                Text(
                  notesProvider.error!,
                  style: TextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Dimensions.md),
                CustomButton(
                  text: 'Retry',
                  onPressed: _loadNotes,
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(Dimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isTeacher)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomButton(
                      text: 'Create Note',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/create-note',
                        arguments: widget.moduleId,
                      ),
                      icon: Icons.add,
                    ),
                  ],
                ),
              const SizedBox(height: Dimensions.md),
              Expanded(
                child: notesProvider.notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note,
                              size: Dimensions.iconLg,
                              color: AppColors.grey,
                            ),
                            const SizedBox(height: Dimensions.md),
                            Text(
                              'No notes available',
                              style: TextStyles.h3,
                            ),
                            const SizedBox(height: Dimensions.sm),
                            Text(
                              isTeacher
                                  ? 'Create your first note'
                                  : 'Notes will appear here once your instructor creates them',
                              style: TextStyles.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: notesProvider.notes.length,
                        itemBuilder: (context, index) {
                          final note = notesProvider.notes[index];
                          return Card(
                            margin:
                                const EdgeInsets.only(bottom: Dimensions.sm),
                            child: ListTile(
                              leading: const Icon(
                                Icons.note,
                                color: AppColors.primary,
                                size: Dimensions.iconMd,
                              ),
                              title: Text(
                                note.title,
                                style: TextStyles.bodyLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                note.content,
                                style: TextStyles.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isTeacher) ...[
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      color: AppColors.primary,
                                      onPressed: () => Navigator.pushNamed(
                                        context,
                                        '/edit-note',
                                        arguments: {
                                          'moduleId': widget.moduleId,
                                          'noteId': note.id,
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      color: AppColors.error,
                                      onPressed: () =>
                                          _showDeleteConfirmation(note),
                                    ),
                                  ],
                                  CustomButton(
                                    text: 'View',
                                    onPressed: () => _showNoteContent(note),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Note',
          style: TextStyles.h3,
        ),
        content: Text(
          'Are you sure you want to delete this note?',
          style: TextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyles.button.copyWith(color: AppColors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final notesProvider =
                    Provider.of<NoteProvider>(context, listen: false);
                await notesProvider.deleteNote(widget.moduleId, note.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Note deleted successfully',
                      style: TextStyles.bodyMedium.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to delete note: $e',
                      style: TextStyles.bodyMedium.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: TextStyles.button.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showNoteContent(Note note) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 800,
          ),
          padding: const EdgeInsets.all(Dimensions.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: TextStyles.h3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.grey,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: Dimensions.sm),
              Expanded(
                child: SingleChildScrollView(
                  child: MarkdownBody(
                    data: note.content,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyles.bodyMedium,
                      h1: TextStyles.h1,
                      h2: TextStyles.h2,
                      h3: TextStyles.h3,
                      listBullet: TextStyles.bodyMedium,
                      blockquote: TextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      code: TextStyles.bodyMedium.copyWith(
                        fontFamily: 'monospace',
                        backgroundColor: AppColors.lightGrey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
