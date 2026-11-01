import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/note_model.dart';
import '../../../providers/app_state_provider.dart';

class NoteEditDialog extends StatefulWidget {
  final Note? note;
  final String? initialEntityId;
  final String? initialEntityType;

  const NoteEditDialog({
    super.key,
    this.note,
    this.initialEntityId,
    this.initialEntityType,
  });

  static Future<Note?> show(
    BuildContext context, {
    Note? note,
    String? initialEntityId,
    String? initialEntityType,
  }) {
    return showDialog<Note>(
      context: context,
      builder: (ctx) => NoteEditDialog(
        note: note,
        initialEntityId: initialEntityId,
        initialEntityType: initialEntityType,
      ),
    );
  }

  @override
  State<NoteEditDialog> createState() => _NoteEditDialogState();
}

class _NoteEditDialogState extends State<NoteEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _contentController;
  late String _entityType;
  String? _relatedEntityId;

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    _contentController = TextEditingController(text: n?.content ?? '');
    _entityType = n?.entityType ?? widget.initialEntityType ?? 'general';
    _relatedEntityId = n?.relatedEntityId ?? widget.initialEntityId;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isEditing = widget.note != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Note' : 'Add Learning Note',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Entity Type Selector
              DropdownButtonFormField<String>(
                value: _entityType,
                decoration: const InputDecoration(labelText: 'Attach Note To'),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General Learning Note')),
                  DropdownMenuItem(value: 'phase', child: Text('Learning Phase')),
                  DropdownMenuItem(value: 'task', child: Text('Specific Task')),
                  DropdownMenuItem(value: 'project', child: Text('Mini Project')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _entityType = val;
                      _relatedEntityId = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Specific entity dropdown if not general
              if (_entityType == 'phase' && appState.phases.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: appState.phases.any((p) => p.id == _relatedEntityId)
                      ? _relatedEntityId
                      : appState.phases.first.id,
                  decoration: const InputDecoration(labelText: 'Select Phase'),
                  items: appState.phases.map((p) {
                    return DropdownMenuItem(
                      value: p.id,
                      child: Text(p.title, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _relatedEntityId = val),
                )
              else if (_entityType == 'task' && appState.tasks.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: appState.tasks.any((t) => t.id == _relatedEntityId)
                      ? _relatedEntityId
                      : appState.tasks.first.id,
                  decoration: const InputDecoration(labelText: 'Select Task'),
                  items: appState.tasks.map((t) {
                    return DropdownMenuItem(
                      value: t.id,
                      child: Text(t.title, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _relatedEntityId = val),
                )
              else if (_entityType == 'project' && appState.projects.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: appState.projects.any((p) => p.id == _relatedEntityId)
                      ? _relatedEntityId
                      : appState.projects.first.id,
                  decoration: const InputDecoration(labelText: 'Select Project'),
                  items: appState.projects.map((p) {
                    return DropdownMenuItem(
                      value: p.id,
                      child: Text(p.title, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _relatedEntityId = val),
                ),

              if (_entityType != 'general') const SizedBox(height: 12),

              // Content TextField
              TextFormField(
                controller: _contentController,
                autofocus: !isEditing,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Note Content *',
                  hintText: 'Code snippets, concept summaries, bugs solved...',
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter note content';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final now = DateTime.now();
            final note = Note(
              id: widget.note?.id ?? const Uuid().v4(),
              relatedEntityId: _relatedEntityId ?? '',
              entityType: _entityType,
              content: _contentController.text.trim(),
              createdAt: widget.note?.createdAt ?? now,
              updatedAt: now,
            );
            Navigator.of(context).pop(note);
          },
          child: Text(isEditing ? 'Save Changes' : 'Save Note'),
        ),
      ],
    );
  }
}

