import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/phase_model.dart';
import '../../../providers/app_state_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'phase_detail_screen.dart';
import 'phase_edit_dialog.dart';

class PhasesScreen extends StatelessWidget {
  const PhasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final phases = appState.phases;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Phases'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Phase',
            onPressed: () => _addPhase(context, appState),
          ),
        ],
      ),
      body: phases.isEmpty
          ? EmptyState(
              icon: Icons.layers_outlined,
              title: 'No Learning Phases Yet',
              subtitle: 'Import a learning roadmap or add your first learning phase manually.',
              buttonLabel: 'Add First Phase',
              onButtonPressed: () => _addPhase(context, appState),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: phases.length,
              onReorder: (oldIdx, newIdx) => appState.reorderPhases(oldIdx, newIdx),
              itemBuilder: (ctx, i) {
                final phase = phases[i];
                final progress = appState.getPhaseProgress(phase.id);
                final total = appState.getPhaseTasksCount(phase.id);
                final completed = appState.getPhaseCompletedCount(phase.id);
                final remaining = appState.getPhaseRemainingCount(phase.id);
                final percentage = (progress * 100).toInt();

                return Card(
                  key: ValueKey(phase.id),
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PhaseDetailScreen(phase: phase),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Phase Number & Title & Actions
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAccent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      phase.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (phase.weekDuration.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        phase.weekDuration,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.secondaryAccent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert, size: 18, color: textMuted),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _editPhase(context, appState, phase);
                                  } else if (val == 'delete') {
                                    _deletePhase(context, appState, phase);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit Phase')),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete Phase',
                                        style: TextStyle(color: AppColors.danger)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (phase.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              phase.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.5, color: textMuted),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 7,
                              backgroundColor: isDark ? AppColors.darkCard : Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.secondaryAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Stats Row (Number of tasks, Completed, Remaining, % Completed)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatItem('Tasks', '$total', textMuted),
                              _buildStatItem('Completed', '$completed', AppColors.secondaryAccent),
                              _buildStatItem('Remaining', '$remaining', textMuted),
                              _buildStatItem('Progress', '$percentage%', AppColors.primaryAccent),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPhase(context, appState),
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Phase'),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor)),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
      ],
    );
  }

  Future<void> _addPhase(BuildContext context, AppStateProvider appState) async {
    final newPhase = await PhaseEditDialog.show(
      context,
      defaultOrder: appState.phases.length + 1,
    );
    if (newPhase != null) {
      await appState.savePhase(newPhase);
    }
  }

  Future<void> _editPhase(BuildContext context, AppStateProvider appState, Phase phase) async {
    final updated = await PhaseEditDialog.show(context, phase: phase);
    if (updated != null) {
      await appState.savePhase(updated);
    }
  }

  Future<void> _deletePhase(BuildContext context, AppStateProvider appState, Phase phase) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Delete Phase',
      message:
          'Are you sure you want to delete "${phase.title}"? All associated tasks will also be deleted.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirm) {
      await appState.deletePhase(phase.id);
    }
  }
}
