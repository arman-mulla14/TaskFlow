import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/task_model.dart';
import '../../../providers/app_state_provider.dart';

class TaskEditDialog extends StatefulWidget {
  final Task? task;
  final String? initialPhaseId;

  const TaskEditDialog({super.key, this.task, this.initialPhaseId});

  static Future<Task?> show(BuildContext context, {Task? task, String? initialPhaseId}) {
    return showDialog<Task>(
      context: context,
      builder: (ctx) => TaskEditDialog(task: task, initialPhaseId: initialPhaseId),
    );
  }

  @override
  State<TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _notesController;

  late String _phaseId;
  late TaskPriority _priority;
  late TaskStatus _status;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _notesController = TextEditingController(text: t?.notes ?? '');

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    if (t != null) {
      _phaseId = t.phaseId;
    } else if (widget.initialPhaseId != null && widget.initialPhaseId!.isNotEmpty) {
      _phaseId = widget.initialPhaseId!;
    } else if (appState.phases.isNotEmpty) {
      _phaseId = appState.phases.first.id;
    } else {
      _phaseId = '';
    }

    _priority = t?.priority ?? TaskPriority.medium;
    _status = t?.status ?? TaskStatus.pending;
    _dueDate = t?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final phases = appState.phases;
    final isEditing = widget.task != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Task' : 'New Task',
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
                    labelText: 'Task Title *',
                    hintText: 'e.g. Variables & Data Types',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Add details, topics covered, or notes',
                  ),
                ),
                const SizedBox(height: 14),

                // Phase selection
                if (phases.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: phases.any((p) => p.id == _phaseId) ? _phaseId : phases.first.id,
                    decoration: const InputDecoration(
                      labelText: 'Phase',
                    ),
                    items: phases.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          p.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _phaseId = val);
                      }
                    },
                  ),
                if (phases.isNotEmpty) const SizedBox(height: 14),

                // Priority & Status Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<TaskPriority>(
                        value: _priority,
                        decoration: const InputDecoration(labelText: 'Priority'),
                        items: TaskPriority.values.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(p.label),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _priority = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<TaskStatus>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: TaskStatus.values.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Due Date Picker Tile
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Due Date', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              _dueDate != null
                                  ? DateFormatter.formatMedium(_dueDate)
                                  : 'No deadline set',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                      if (_dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _dueDate = null),
                          tooltip: 'Clear deadline',
                        ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                          );
                          if (picked != null) {
                            setState(() => _dueDate = picked);
                          }
                        },
                        child: Text(_dueDate == null ? 'Set Date' : 'Change'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Personal Notes (Optional)',
                    hintText: 'Gotchas, links, or takeaways',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save Changes' : 'Create Task'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final isDone = _status == TaskStatus.completed;

    final task = Task(
      id: widget.task?.id ?? const Uuid().v4(),
      phaseId: _phaseId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      priority: _priority,
      status: _status,
      dueDate: _dueDate,
      notes: _notesController.text.trim(),
      createdAt: widget.task?.createdAt ?? now,
      completedAt: isDone ? (widget.task?.completedAt ?? now) : null,
    );

    Navigator.of(context).pop(task);
  }
}
