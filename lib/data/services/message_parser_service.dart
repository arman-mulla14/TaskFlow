import 'package:uuid/uuid.dart';
import '../models/parsed_import_result.dart';
import '../models/task_model.dart';

class MessageParserService {
  static const _uuid = Uuid();

  /// Parse plain text input into structured phases, tasks, and mini projects.
  ParsedImportResult parseRoadmap(String input) {
    if (input.trim().isEmpty) {
      return const ParsedImportResult(
        phases: [],
        unparsedLines: [],
        rawLineCount: 0,
      );
    }

    final rawLines = input.split(RegExp(r'\r?\n'));
    final List<ParsedPhase> phases = [];
    final List<String> unparsedLines = [];

    ParsedPhase? currentPhase;
    bool inProjectsSection = false;
    ParsedProject? currentProject;
    int phaseOrderCounter = 1;

    // Helper regex patterns
    final phaseHeaderRegex = RegExp(
      r'^(?:#+\s*|\*+\s*)?(?:Phase|Module|Sprint|Part|Section|Week)\s*(\d+|[IVXLCDM]+)?\s*[:\-\u2013\u2014.]?\s*(.*?)(?:\*+)?$',
      caseSensitive: false,
    );

    final weekDurationRegex = RegExp(
      r'\((?:Weeks?|Duration:?)\s*([0-9]+(?:\s*[\-\u2013\u2014]\s*[0-9]+)?(?:\s*(?:weeks?|days?|months?))?)\)|(?:Weeks?|Duration:?)\s*([0-9]+(?:\s*[\-\u2013\u2014]\s*[0-9]+)?(?:\s*(?:weeks?|days?|months?))?)',
      caseSensitive: false,
    );

    final projectsHeaderRegex = RegExp(
      r'^(?:#+\s*|\*+\s*)?(?:Mini\s*projects?|Projects?|Hands-on\s*projects?|Assignments?|Practice\s*projects?)\s*:?\s*(?:\*+)?$',
      caseSensitive: false,
    );

    final numberedItemRegex = RegExp(
      r'^(?:\s*)?(?:(?:Task\s*)?(\d+)[\.\)\-\:]\s*|\[(\d+)\]\s*)(.+)$',
      caseSensitive: false,
    );

    final bulletItemRegex = RegExp(
      r'^(?:\s*)?[\-\*\u2022\+]\s*(?:\[(?:\s|x|X)?\]\s*)?(.+)$',
    );

    for (int i = 0; i < rawLines.length; i++) {
      final originalLine = rawLines[i];
      final line = originalLine.trim();

      if (line.isEmpty) {
        continue;
      }

      // 1. Check for Phase Header
      if (phaseHeaderRegex.hasMatch(line) && !line.toLowerCase().startsWith('phase out')) {
        final match = phaseHeaderRegex.firstMatch(line);
        final phaseNum = match?.group(1) ?? '$phaseOrderCounter';
        String fullTitle = (match?.group(2) ?? '').trim();

        // Extract week duration if present in the header
        String weekDuration = '';
        final weekMatch = weekDurationRegex.firstMatch(line);
        if (weekMatch != null) {
          weekDuration = weekMatch.group(1) ?? weekMatch.group(2) ?? '';
          if (weekDuration.isNotEmpty && !weekDuration.toLowerCase().contains('week')) {
            weekDuration = 'Weeks $weekDuration';
          }
        }

        // Clean title from duration in parentheses
        fullTitle = fullTitle.replaceAll(weekDurationRegex, '').trim();
        fullTitle = fullTitle.replaceAll(RegExp(r'[\(\)\[\]\*\#]'), '').trim();
        // Remove trailing hyphens or dashes
        fullTitle = fullTitle.replaceAll(RegExp(r'[\-\u2013\u2014:]+$'), '').trim();

        if (fullTitle.isEmpty) {
          fullTitle = 'Phase $phaseNum';
        } else if (!fullTitle.toLowerCase().contains('phase')) {
          fullTitle = 'Phase $phaseNum — $fullTitle';
        }

        currentPhase = ParsedPhase(
          id: _uuid.v4(),
          title: fullTitle,
          weekDuration: weekDuration,
          order: phaseOrderCounter++,
        );
        phases.add(currentPhase);
        inProjectsSection = false;
        currentProject = null;
        continue;
      }

      // 2. Check for Projects Header
      if (projectsHeaderRegex.hasMatch(line)) {
        inProjectsSection = true;
        currentProject = null;
        continue;
      }

      // If we don't have a phase yet, create a default Phase 1
      if (currentPhase == null) {
        currentPhase = ParsedPhase(
          id: _uuid.v4(),
          title: 'Phase 1 — Getting Started',
          weekDuration: '',
          order: phaseOrderCounter++,
        );
        phases.add(currentPhase);
      }

      // 3. In Projects Section
      if (inProjectsSection) {
        final bulletMatch = bulletItemRegex.firstMatch(line);
        final numberedMatch = numberedItemRegex.firstMatch(line);

        if (bulletMatch != null || numberedMatch != null) {
          final content = (bulletMatch?.group(1) ?? numberedMatch?.group(3) ?? '').trim();
          final isSubItem = originalLine.startsWith('   ') ||
              originalLine.startsWith('    ') ||
              originalLine.startsWith('\t');

          if (isSubItem && currentProject != null) {
            // Sub-checklist item for the current project
            currentProject = ParsedProject(
              id: currentProject.id,
              title: currentProject.title,
              description: currentProject.description,
              checklist: [...currentProject.checklist, content],
              isSelected: currentProject.isSelected,
            );
            // Replace in current phase
            final pIndex = currentPhase.projects.indexWhere((p) => p.id == currentProject?.id);
            if (pIndex >= 0) {
              currentPhase.projects[pIndex] = currentProject;
            }
          } else {
            // New Mini Project
            currentProject = ParsedProject(
              id: _uuid.v4(),
              title: content,
              checklist: [],
            );
            currentPhase.projects.add(currentProject);
          }
          continue;
        }
      }

      // 4. Numbered Task Items
      final numMatch = numberedItemRegex.firstMatch(line);
      if (numMatch != null) {
        final content = numMatch.group(3)?.trim() ?? '';
        final parsed = _extractTaskTitleAndDescription(content);

        final task = ParsedTask(
          id: _uuid.v4(),
          title: parsed['title'] ?? content,
          description: parsed['description'] ?? '',
          priority: _inferPriority(content),
        );
        currentPhase.tasks.add(task);
        inProjectsSection = false;
        currentProject = null;
        continue;
      }

      // 5. Bullet Task Items
      final bulletMatch = bulletItemRegex.firstMatch(line);
      if (bulletMatch != null) {
        final content = bulletMatch.group(1)?.trim() ?? '';
        final parsed = _extractTaskTitleAndDescription(content);

        final task = ParsedTask(
          id: _uuid.v4(),
          title: parsed['title'] ?? content,
          description: parsed['description'] ?? '',
          priority: _inferPriority(content),
        );
        currentPhase.tasks.add(task);
        continue;
      }

      // 6. Section Subtitle or Phase Description
      // e.g., "Foundation", "Core UI", "Architecture & Flow"
      if (currentPhase.description.isEmpty &&
          currentPhase.tasks.isEmpty &&
          currentPhase.projects.isEmpty &&
          line.length < 80 &&
          !line.endsWith('.')) {
        currentPhase.description = line.replaceAll(RegExp(r'[\*\#]'), '').trim();
        continue;
      }

      // 7. Check if line is descriptive text for the most recent task
      if (currentPhase.tasks.isNotEmpty &&
          (originalLine.startsWith('   ') ||
              originalLine.startsWith('    ') ||
              originalLine.startsWith('\t'))) {
        final lastTask = currentPhase.tasks.last;
        final updatedDesc = lastTask.description.isEmpty
            ? line
            : '${lastTask.description}\n$line';
        currentPhase.tasks[currentPhase.tasks.length - 1] =
            lastTask.copyWith(description: updatedDesc);
        continue;
      }

      // 8. Otherwise: Unrecognized line. Keep it for preview & manual assignment!
      unparsedLines.add(originalLine);
    }

    return ParsedImportResult(
      phases: phases,
      unparsedLines: unparsedLines,
      rawLineCount: rawLines.length,
    );
  }

  /// Separates title and description if formatted like "Variables: var, final, const"
  Map<String, String> _extractTaskTitleAndDescription(String text) {
    // If contains a colon, like "Topic: description"
    final colonIndex = text.indexOf(':');
    if (colonIndex > 2 && colonIndex < 40 && colonIndex < text.length - 1) {
      final title = text.substring(0, colonIndex).trim();
      final description = text.substring(colonIndex + 1).trim();
      return {
        'title': title,
        'description': description,
      };
    }
    return {
      'title': text,
      'description': '',
    };
  }

  TaskPriority _inferPriority(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('[high]') ||
        lower.contains('priority: high') ||
        lower.contains('urgent') ||
        lower.contains('important') ||
        lower.contains('critical')) {
      return TaskPriority.high;
    }
    if (lower.contains('[low]') ||
        lower.contains('priority: low') ||
        lower.contains('optional') ||
        lower.contains('bonus')) {
      return TaskPriority.low;
    }
    return TaskPriority.medium;
  }
}
