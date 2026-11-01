import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/app_state_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'note_edit_dialog.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _typeFilter = 'all'; // 'all', 'general', 'phase', 'task', 'project'

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final notes = appState.notes;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final filteredNotes = notes.where((n) {
      if (_typeFilter != 'all' && n.entityType != _typeFilter) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Note',
            onPressed: () => _addNote(context, appState),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip('All (${notes.length})', 'all'),
                  const SizedBox(width: 8),
                  _buildChip('General', 'general'),
                  const SizedBox(width: 8),
                  _buildChip('Phase Notes', 'phase'),
                  const SizedBox(width: 8),
                  _buildChip('Task Notes', 'task'),
                  const SizedBox(width: 8),
                  _buildChip('Project Notes', 'project'),
                ],
              ),
            ),
          ),
          const Divider(),

          // Notes List
          Expanded(
            child: filteredNotes.isEmpty
                ? EmptyState(
                    icon: Icons.sticky_note_2_outlined,
                    title: 'No Notes Found',
                    subtitle: notes.isEmpty
                        ? 'Capture your key learnings, code snippets, and solutions.'
                        : 'No notes match the selected filter.',
                    buttonLabel: notes.isEmpty ? 'Write First Note' : null,
                    onButtonPressed: notes.isEmpty ? () => _addNote(context, appState) : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
                    itemCount: filteredNotes.length,
                    itemBuilder: (ctx, i) {
                      final note = filteredNotes[i];
                      return Card(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Theme.of(context).dividerTheme.color ??
                                Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryAccent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      note.entityType.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryAccentLight,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormatter.formatShort(note.updatedAt),
                                    style: TextStyle(fontSize: 11, color: textMuted),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert, size: 18, color: textMuted),
                                    onSelected: (val) async {
                                      if (val == 'edit') {
                                        final updated = await NoteEditDialog.show(
                                          context,
                                          note: note,
                                        );
                                        if (updated != null && context.mounted) {
                                          await appState.saveNote(updated);
                                        }
                                      } else if (val == 'delete') {
                                        final confirm = await ConfirmDialog.show(
                                          context: context,
                                          title: 'Delete Note',
                                          message: 'Are you sure you want to delete this note?',
                                          confirmLabel: 'Delete',
                                          isDestructive: true,
                                        );
                                        if (confirm && context.mounted) {
                                          await appState.deleteNote(note.id);
                                        }
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete',
                                            style: TextStyle(color: AppColors.danger)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                note.content,
                                style: const TextStyle(fontSize: 13.5, height: 1.45),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNote(context, appState),
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Note'),
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final isSelected = _typeFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _typeFilter = value),
      selectedColor: AppColors.primaryAccent.withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? AppColors.primaryAccent : null,
      ),
    );
  }

  Future<void> _addNote(BuildContext context, AppStateProvider appState) async {
    final newNote = await NoteEditDialog.show(context);
    if (newNote != null) {
      await appState.saveNote(newNote);
    }
  }
}
