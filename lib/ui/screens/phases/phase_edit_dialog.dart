import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/phase_model.dart';

class PhaseEditDialog extends StatefulWidget {
  final Phase? phase;
  final int defaultOrder;

  const PhaseEditDialog({super.key, this.phase, this.defaultOrder = 1});

  static Future<Phase?> show(BuildContext context, {Phase? phase, int defaultOrder = 1}) {
    return showDialog<Phase>(
      context: context,
      builder: (ctx) => PhaseEditDialog(phase: phase, defaultOrder: defaultOrder),
    );
  }

  @override
  State<PhaseEditDialog> createState() => _PhaseEditDialogState();
}

class _PhaseEditDialogState extends State<PhaseEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _weekController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.phase?.title ?? '');
    _weekController = TextEditingController(text: widget.phase?.weekDuration ?? '');
    _descController = TextEditingController(text: widget.phase?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _weekController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.phase != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Learning Phase' : 'New Learning Phase',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                autofocus: !isEditing,
                decoration: const InputDecoration(
                  labelText: 'Phase Title *',
                  hintText: 'e.g. Dart Programming & OOP',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a phase title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weekController,
                decoration: const InputDecoration(
                  labelText: 'Week Duration (Optional)',
                  hintText: 'e.g. Weeks 1–2 or 2 Weeks',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Core concepts, focus areas or goals',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final phase = Phase(
              id: widget.phase?.id ?? const Uuid().v4(),
              title: _titleController.text.trim(),
              weekDuration: _weekController.text.trim(),
              description: _descController.text.trim(),
              order: widget.phase?.order ?? widget.defaultOrder,
              createdAt: widget.phase?.createdAt ?? DateTime.now(),
            );
            Navigator.of(context).pop(phase);
          },
          child: Text(isEditing ? 'Save Changes' : 'Create Phase'),
        ),
      ],
    );
  }
}
