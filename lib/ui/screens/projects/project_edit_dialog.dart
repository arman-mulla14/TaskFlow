import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/project_checklist_item_model.dart';
import '../../../data/models/project_model.dart';
import '../../../providers/app_state_provider.dart';

class ProjectEditDialog extends StatefulWidget {
  final Project? project;

  const ProjectEditDialog({super.key, this.project});

  static Future<Project?> show(BuildContext context, {Project? project}) {
    return showDialog<Project>(
      context: context,
      builder: (ctx) => ProjectEditDialog(project: project),
    );
  }

  @override
  State<ProjectEditDialog> createState() => _ProjectEditDialogState();
}

class _ProjectEditDialogState extends State<ProjectEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _notesController;
  final TextEditingController _newChecklistItemController = TextEditingController();

  late String _phaseId;
  late ProjectStatus _status;
  late List<ProjectChecklistItem> _checklist;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _titleController = TextEditingController(text: p?.title ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    if (p != null) {
      _phaseId = p.phaseId;
      _checklist = List.from(p.checklist);
    } else {
      _phaseId = appState.phases.isNotEmpty ? appState.phases.first.id : '';
      _checklist = [];
    }

    _status = p?.status ?? ProjectStatus.pending;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _notesController.dispose();
    _newChecklistItemController.dispose();
    super.dispose();
  }

  void _addChecklistItem() {
    final text = _newChecklistItemController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _checklist.add(
        ProjectChecklistItem(
          id: const Uuid().v4(),
          projectId: widget.project?.id ?? '',
          title: text,
          isCompleted: false,
        ),
      );
      _newChecklistItemController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final phases = appState.phases;
    final isEditing = widget.project != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Mini Project' : 'New Mini Project',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  autofocus: !isEditing,
                  decoration: const InputDecoration(
                    labelText: 'Project Name *',
                    hintText: 'e.g. Student Management System',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a project name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Project scope, tech requirements or features',
                  ),
                ),
                const SizedBox(height: 12),

                // Phase Dropdown
                if (phases.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: phases.any((p) => p.id == _phaseId) ? _phaseId : phases.first.id,
                    decoration: const InputDecoration(labelText: 'Related Learning Phase'),
                    items: phases.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text(p.title, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _phaseId = val);
                    },
                  ),
                if (phases.isNotEmpty) const SizedBox(height: 12),

                // Status Dropdown
                DropdownButtonFormField<ProjectStatus>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ProjectStatus.values.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s.label));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
                const SizedBox(height: 16),

                // Implementation Checklist Header
                const Text(
                  'Implementation Checklist',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 6),

                // Add checklist item input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newChecklistItemController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Create Student Model',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (_) => _addChecklistItem(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: _addChecklistItem,
                      icon: const Icon(Icons.add, size: 20),
                      tooltip: 'Add item',
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Checklist Items list
                if (_checklist.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No checklist tasks added yet.',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  )
                else
                  ..._checklist.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: item.isCompleted,
                            onChanged: (val) {
                              setState(() {
                                _checklist[idx] = item.copyWith(isCompleted: val ?? false);
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13,
                                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                color: item.isCompleted ? Colors.grey : null,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _checklist.removeAt(idx);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 14),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Architecture notes, Git repo link, ideas',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save Changes' : 'Create Project'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.project?.id ?? const Uuid().v4();
    final now = DateTime.now();

    final finalizedChecklist = _checklist.map((item) {
      if (item.projectId.isEmpty) {
        return item.copyWith(projectId: id);
      }
      return item;
    }).toList();

    final isCompleted = _status == ProjectStatus.completed;

    final project = Project(
      id: id,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      phaseId: _phaseId,
      status: _status,
      checklist: finalizedChecklist,
      notes: _notesController.text.trim(),
      startDate: widget.project?.startDate ?? now,
      createdAt: widget.project?.createdAt ?? now,
      completedAt: isCompleted ? (widget.project?.completedAt ?? now) : null,
    );

    Navigator.of(context).pop(project);
  }
}
