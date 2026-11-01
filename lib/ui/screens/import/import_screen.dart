import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/parsed_import_result.dart';
import '../../../data/models/task_model.dart';
import '../../../data/services/message_parser_service.dart';
import '../../../providers/app_state_provider.dart';
import '../../widgets/priority_badge.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final TextEditingController _textController = TextEditingController();
  final MessageParserService _parserService = MessageParserService();

  ParsedImportResult? _parsedResult;
  bool _isParsing = false;
  int _currentStep = 0; // 0: Input, 1: Preview

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _parseText() {
    final text = _textController.text;
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste or type your roadmap text first.')),
      );
      return;
    }

    setState(() => _isParsing = true);
    final result = _parserService.parseRoadmap(text);

    setState(() {
      _parsedResult = result;
      _isParsing = false;
      _currentStep = 1;
    });
  }

  void _loadSample() {
    _textController.text = AppStrings.sampleRoadmap;
    _parseText();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _textController.text = data.text!;
      });
      _parseText();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty or does not contain text.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Learning Roadmap'),
        actions: [
          if (_currentStep == 0) ...[
            TextButton.icon(
              onPressed: _loadSample,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Try Sample'),
            ),
          ] else ...[
            TextButton.icon(
              onPressed: () => setState(() => _currentStep = 0),
              icon: const Icon(Icons.edit_note, size: 16),
              label: const Text('Edit Text'),
            ),
          ],
        ],
      ),
      body: _currentStep == 0 ? _buildInputStep(isDark) : _buildPreviewStep(isDark),
      bottomNavigationBar: _currentStep == 1 ? _buildBottomActionBar() : null,
    );
  }

  Widget _buildInputStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Informational Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryAccent.withOpacity(0.2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_outlined, color: AppColors.primaryAccent, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Paste your roadmap or syllabus in plain text. TaskFlow automatically detects Phases, Weeks, numbered tasks, bullet points, and Mini Projects!',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste, size: 18),
                  label: const Text('Paste from Clipboard'),
                ),
              ),
              const SizedBox(width: 12),
              if (_textController.text.isNotEmpty)
                IconButton.outlined(
                  onPressed: () => setState(() => _textController.clear()),
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Clear',
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Text Input Field
          TextField(
            controller: _textController,
            maxLines: 16,
            decoration: InputDecoration(
              hintText: 'Paste roadmap message here...\n\nExample:\n'
                  'Phase 1 — Dart Programming (Weeks 1–2)\n'
                  'Foundation\n'
                  '1. Variables: var, final, const, dynamic\n'
                  '2. Data types: int, double, String, bool\n\n'
                  'Mini projects:\n'
                  '- Student Management System\n'
                  '- Banking System',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),

          // Parse and Convert Button
          ElevatedButton.icon(
            onPressed: _isParsing ? null : _parseText,
            icon: _isParsing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.rocket_launch, size: 20),
            label: Text(_isParsing ? 'Analyzing Text...' : 'Convert to Structured Tasks'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep(bool isDark) {
    if (_parsedResult == null || _parsedResult!.phases.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.warning),
              const SizedBox(height: 16),
              const Text(
                'No structured tasks detected',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try adjusting the formatting or check your text.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => setState(() => _currentStep = 0),
                child: const Text('Back to Edit Text'),
              ),
            ],
          ),
        ),
      );
    }

    final result = _parsedResult!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Summary Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Phases', '${result.phases.length}'),
              _buildDivider(),
              _buildMetric('Tasks', '${result.totalTasks}'),
              _buildDivider(),
              _buildMetric('Mini Projects', '${result.totalProjects}'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Unparsed text warning / sheet if any
        if (result.unparsedLines.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${result.unparsedLines.length} unrecognized line(s) preserved.',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: () => _showUnparsedLinesDialog(result.unparsedLines),
                  child: const Text('View Preserved Lines', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Phases List
        ...result.phases.asMap().entries.map((entry) {
          final pIndex = entry.key;
          final phase = entry.value;
          return _buildPhasePreviewCard(phase, pIndex, isDark);
        }),

        // Add Manual Phase Button
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addManualPhase,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Missing Phase'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPhasePreviewCard(ParsedPhase phase, int phaseIndex, bool isDark) {
    return Card(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  phase.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              if (phase.weekDuration.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    phase.weekDuration,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryAccent,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: phase.description.isNotEmpty
              ? Text(
                  phase.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                )
              : null,
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (value) {
              if (value == 'edit') {
                _editPhase(phase);
              } else if (value == 'delete') {
                setState(() {
                  _parsedResult!.phases.removeAt(phaseIndex);
                });
              } else if (value == 'add_task') {
                _addTaskToPhase(phase);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'add_task', child: Text('Add Task')),
              const PopupMenuItem(value: 'edit', child: Text('Edit Phase Details')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Remove Phase', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
          children: [
            const Divider(),
            // Tasks Section
            if (phase.tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('No tasks in this phase yet.',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
              )
            else
              ...phase.tasks.asMap().entries.map((tEntry) {
                final tIndex = tEntry.key;
                final task = tEntry.value;
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  leading: Checkbox(
                    value: task.isSelected,
                    onChanged: (val) {
                      setState(() {
                        task.isSelected = val ?? true;
                      });
                    },
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: task.isSelected ? null : Colors.grey,
                    ),
                  ),
                  subtitle: task.description.isNotEmpty
                      ? Text(task.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11))
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PriorityBadge(priority: task.priority),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        onPressed: () => _editParsedTask(task),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            phase.tasks.removeAt(tIndex);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),

            // Mini Projects Section
            if (phase.projects.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    Icon(Icons.rocket_launch_outlined,
                        size: 16, color: AppColors.secondaryAccent),
                    SizedBox(width: 8),
                    Text(
                      'Mini Projects',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryAccent,
                      ),
                    ),
                  ],
                ),
              ),
              ...phase.projects.asMap().entries.map((pEntry) {
                final prIndex = pEntry.key;
                final project = pEntry.value;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: project.isSelected,
                        onChanged: (val) {
                          setState(() {
                            project.isSelected = val ?? true;
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: project.isSelected ? null : Colors.grey,
                              ),
                            ),
                            if (project.checklist.isNotEmpty)
                              Text(
                                '${project.checklist.length} subtasks',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            phase.projects.removeAt(prIndex);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final result = _parsedResult;
    final selectedCount = result?.selectedTasks ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$selectedCount Tasks Selected',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${result?.phases.length ?? 0} Learning Phases',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: selectedCount > 0 ? _commitImport : null,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Confirm & Save'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _commitImport() async {
    if (_parsedResult == null) return;

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    await appState.importParsedRoadmap(_parsedResult!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully imported ${_parsedResult!.selectedTasks} tasks across ${_parsedResult!.phases.length} phases!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _addManualPhase() {
    final titleCtrl = TextEditingController();
    final weekCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Phase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Phase Title *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weekCtrl,
              decoration: const InputDecoration(labelText: 'Week Duration (e.g. Weeks 1–2)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _parsedResult!.phases.add(
                    ParsedPhase(
                      id: const Uuid().v4(),
                      title: titleCtrl.text.trim(),
                      weekDuration: weekCtrl.text.trim(),
                      order: _parsedResult!.phases.length + 1,
                    ),
                  );
                });
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editPhase(ParsedPhase phase) {
    final titleCtrl = TextEditingController(text: phase.title);
    final weekCtrl = TextEditingController(text: phase.weekDuration);
    final descCtrl = TextEditingController(text: phase.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Phase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Phase Title')),
            const SizedBox(height: 10),
            TextField(controller: weekCtrl, decoration: const InputDecoration(labelText: 'Week Duration')),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                phase.title = titleCtrl.text.trim();
                phase.weekDuration = weekCtrl.text.trim();
                phase.description = descCtrl.text.trim();
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addTaskToPhase(ParsedPhase phase) {
    final titleCtrl = TextEditingController();
    TaskPriority priority = TaskPriority.medium;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Task to Phase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Task Title *'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskPriority>(
                value: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => priority = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    phase.tasks.add(
                      ParsedTask(
                        id: const Uuid().v4(),
                        title: titleCtrl.text.trim(),
                        priority: priority,
                      ),
                    );
                  });
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  void _editParsedTask(ParsedTask task) {
    final titleCtrl = TextEditingController(text: task.title);
    final descCtrl = TextEditingController(text: task.description);
    TaskPriority priority = task.priority;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 10),
              DropdownButtonFormField<TaskPriority>(
                value: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => priority = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  task.title = titleCtrl.text.trim();
                  task.description = descCtrl.text.trim();
                  task.priority = priority;
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnparsedLinesDialog(List<String> lines) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Preserved Unparsed Lines'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: lines
                  .map((l) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('• $l', style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 28, width: 1, color: Colors.grey.withOpacity(0.2));
  }
}
