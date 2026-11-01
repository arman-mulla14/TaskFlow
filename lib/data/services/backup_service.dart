import 'dart:convert';
import '../repositories/database_service.dart';

class BackupService {
  final DatabaseService _db;

  BackupService(this._db);

  String exportToJsonString() {
    final data = _db.exportToJson();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> restoreFromJsonString(String jsonString) async {
    final Map<String, dynamic> data = jsonDecode(jsonString) as Map<String, dynamic>;
    await _db.importFromJson(data);
  }

  String generateProgressReport() {
    final phases = _db.getAllPhases();
    final tasks = _db.getAllTasks();
    final projects = _db.getAllProjects();

    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final percentage = totalTasks > 0 ? (completedTasks / totalTasks * 100).toStringAsFixed(1) : '0';

    final buffer = StringBuffer();
    buffer.writeln('# TaskFlow Learning Progress Report');
    buffer.writeln('Generated on: ${DateTime.now().toLocal().toString().split('.')[0]}');
    buffer.writeln();
    buffer.writeln('## Overview');
    buffer.writeln('- **Overall Progress**: $percentage% ($completedTasks of $totalTasks tasks)');
    buffer.writeln('- **Total Learning Phases**: ${phases.length}');
    buffer.writeln('- **Total Mini Projects**: ${projects.length} (${projects.where((p) => p.isCompleted).length} completed)');
    buffer.writeln();
    buffer.writeln('## Phase Breakdown');

    for (var phase in phases) {
      final phaseTasks = tasks.where((t) => t.phaseId == phase.id).toList();
      final pTotal = phaseTasks.length;
      final pDone = phaseTasks.where((t) => t.isCompleted).length;
      final pPct = pTotal > 0 ? (pDone / pTotal * 100).toStringAsFixed(0) : '0';

      buffer.writeln('### ${phase.title} ${phase.weekDuration.isNotEmpty ? "(${phase.weekDuration})" : ""}');
      buffer.writeln('Progress: $pPct% ($pDone / $pTotal completed)');
      for (var task in phaseTasks) {
        final check = task.isCompleted ? '[x]' : '[ ]';
        buffer.writeln('- $check ${task.title}');
      }
      buffer.writeln();
    }

    if (projects.isNotEmpty) {
      buffer.writeln('## Mini Projects');
      for (var project in projects) {
        final check = project.isCompleted ? '[x]' : '[ ]';
        buffer.writeln('- $check **${project.title}** (${project.status.label})');
        for (var item in project.checklist) {
          final itemCheck = item.isCompleted ? '  [x]' : '  [ ]';
          buffer.writeln('$itemCheck ${item.title}');
        }
      }
    }

    return buffer.toString();
  }
}
