import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/repositories/database_service.dart';
import '../../../data/services/backup_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../providers/app_state_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../calendar/calendar_screen.dart';
import '../notes/notes_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await _notificationService.isEnabled();
    final time = await _notificationService.getReminderTime();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _reminderTime = time;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appState = Provider.of<AppStateProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          // Section: Appearance
          _buildSectionHeader('Appearance & Display'),
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    isDark ? 'Using dark productivity theme' : 'Using crisp light theme',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                  secondary: Icon(
                    isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    color: AppColors.primaryAccent,
                  ),
                  value: isDark,
                  onChanged: (val) => themeProvider.toggleTheme(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Section: Daily Learning Goals & Reminders
          _buildSectionHeader('Learning Goals & Reminders'),
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: AppColors.secondaryAccent),
                  title: const Text('Daily Learning Goal',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${appState.dailyGoal} completed tasks per day',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                  trailing: DropdownButton<int>(
                    value: appState.dailyGoal,
                    underline: const SizedBox(),
                    items: [1, 2, 3, 5, 8, 10].map((goalVal) {
                      return DropdownMenuItem(
                        value: goalVal,
                        child: Text('$goalVal / day', style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) appState.setDailyGoal(val);
                    },
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primaryAccent),
                  title: const Text('Daily Study Reminder',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    _notificationsEnabled
                        ? 'Remind at ${_reminderTime.format(context)}'
                        : 'Reminders disabled',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                  value: _notificationsEnabled,
                  onChanged: (val) async {
                    setState(() => _notificationsEnabled = val);
                    await _notificationService.saveSettings(
                      enabled: val,
                      time: _reminderTime,
                    );
                  },
                ),
                if (_notificationsEnabled) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.schedule, color: Colors.grey),
                    title: const Text('Reminder Time'),
                    trailing: TextButton(
                      child: Text(_reminderTime.format(context)),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _reminderTime,
                        );
                        if (picked != null) {
                          setState(() => _reminderTime = picked);
                          await _notificationService.saveSettings(
                            enabled: _notificationsEnabled,
                            time: picked,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Section: Utilities & Shortcuts
          _buildSectionHeader('Productivity Tools'),
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined, color: AppColors.info),
                  title: const Text('Calendar & Schedule',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Manage daily tasks and deadlines',
                      style: TextStyle(fontSize: 12, color: textMuted)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.sticky_note_2_outlined, color: AppColors.warning),
                  title: const Text('Learning Notes', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Review personal notes & code solutions',
                      style: TextStyle(fontSize: 12, color: textMuted)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotesScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Section: Data & Backup
          _buildSectionHeader('Data Management & Backup'),
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined, color: AppColors.secondaryAccent),
                  title: const Text('Export Backup (JSON)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Export all phases, tasks, projects and notes',
                      style: TextStyle(fontSize: 12, color: textMuted)),
                  onTap: () => _exportBackup(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined, color: AppColors.primaryAccent),
                  title: const Text('Restore Backup (JSON)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Restore entire database from JSON text',
                      style: TextStyle(fontSize: 12, color: textMuted)),
                  onTap: () => _importBackup(context, appState),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.summarize_outlined, color: AppColors.info),
                  title: const Text('Export Progress Summary',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Generate formatted Markdown progress report',
                      style: TextStyle(fontSize: 12, color: textMuted)),
                  onTap: () => _exportProgressReport(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.warning),
                  title: const Text('Clear Completed Tasks',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Remove completed tasks while keeping pending ones',
                      style: TextStyle(fontSize: 12, color: textMuted)),
                  onTap: () => _clearCompleted(context, appState),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.restart_alt, color: AppColors.danger),
                  title: const Text('Reset All Application Data',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.danger)),
                  subtitle: Text('Permanently wipe database and restart clean',
                      style: TextStyle(fontSize: 12, color: textMuted)),
                  onTap: () => _resetAllData(context, appState),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Section: About
          _buildSectionHeader('About'),
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.task_alt, color: AppColors.primaryAccent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(AppStrings.appName,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(AppStrings.appTagline,
                              style: TextStyle(fontSize: 12, color: textMuted)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Version', style: TextStyle(fontSize: 13)),
                      Text(AppStrings.appVersion,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Architecture', style: TextStyle(fontSize: 13)),
                      Text('Offline-First Local DB',
                          style: TextStyle(fontSize: 13, color: textMuted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Privacy', style: TextStyle(fontSize: 13)),
                      Text('100% On-Device Only',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryAccent,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryAccentLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _exportBackup(BuildContext context) {
    final db = DatabaseService();
    final backupService = BackupService(db);
    final jsonStr = backupService.exportToJsonString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exported Database (JSON)'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Copy this JSON backup text or save it safely to restore anytime.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                height: 180,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup JSON copied to clipboard!')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  void _importBackup(BuildContext context, AppStateProvider appState) {
    final textCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Database from JSON'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paste previously exported TaskFlow JSON backup string below:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Paste {"app": "TaskFlow", ...} here',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final text = textCtrl.text.trim();
              if (text.isEmpty) return;
              try {
                final db = DatabaseService();
                final backupService = BackupService(db);
                await backupService.restoreFromJsonString(text);
                await appState.reloadData();
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Database restored successfully!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invalid JSON format: $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _exportProgressReport(BuildContext context) {
    final db = DatabaseService();
    final backupService = BackupService(db);
    final report = backupService.generateProgressReport();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Learning Progress Summary'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 240,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    report,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Progress report copied to clipboard!')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Markdown Report'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCompleted(BuildContext context, AppStateProvider appState) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Clear Completed Tasks',
      message: 'This will remove all finished tasks from the database. Are you sure?',
      confirmLabel: 'Clear',
      isDestructive: true,
    );
    if (confirm) {
      await appState.clearCompletedTasks();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completed tasks cleared.')),
        );
      }
    }
  }

  Future<void> _resetAllData(BuildContext context, AppStateProvider appState) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Reset Application',
      message:
          'This will permanently delete ALL phases, tasks, mini projects, and notes. This action CANNOT be undone.',
      confirmLabel: 'Reset Everything',
      isDestructive: true,
    );
    if (confirm) {
      await appState.resetAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data has been reset.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
