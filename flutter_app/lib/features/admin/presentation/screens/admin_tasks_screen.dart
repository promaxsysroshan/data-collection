import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/models/models.dart';
import '../providers/admin_provider.dart';

class AdminTasksScreen extends ConsumerStatefulWidget {
  const AdminTasksScreen({super.key});
  @override
  ConsumerState<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends ConsumerState<AdminTasksScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(tasksProvider.notifier).load();
      ref.read(usersListProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tasksProvider);
    final tasks = _filter == 'all'
        ? state.tasks
        : state.tasks.where((t) => t.status == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            onPressed: () => _showCreateTaskSheet(context),
          ),
        ],
      ),
      body: Column(children: [
        _buildFilters(),
        Expanded(
          child: state.isLoading
            ? const Center(child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2))
            : tasks.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(tasksProvider.notifier).load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (_, i) => _taskCard(tasks[i]),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _buildFilters() {
    final filters = ['all', 'pending', 'in_progress', 'submitted', 'approved', 'rejected'];
    return Container(
      color: AppColors.surface,
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final f = filters[i];
          final sel = f == _filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: sel ? AppColors.primary : AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                f == 'all' ? 'All' : f[0].toUpperCase() + f.substring(1).replaceAll('_', ' '),
                style: TextStyle(
                  color: sel ? Colors.white : AppColors.textSecondary,
                  fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _taskCard(TaskModel task) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text(task.title, style: const TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
          PriorityBadge(priority: task.priority),
        ]),
        if (task.description != null) ...[
          const SizedBox(height: 5),
          Text(task.description!, style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 12),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 10),
        Row(children: [
          StatusBadge(status: task.status),
          const SizedBox(width: 8),
          if (task.assigneeName != null) ...[
            const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Text(task.assigneeName!, style: const TextStyle(
              color: AppColors.textMuted, fontSize: 11)),
          ],
          const Spacer(),
          if (task.paymentAmount > 0)
            Text('₹${task.paymentAmount.toStringAsFixed(0)}', style: const TextStyle(
              color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _actionBtn('Edit', Icons.edit_outlined, AppColors.info,
              () => _showEditSheet(context, task)),
          const SizedBox(width: 8),
          _actionBtn('Delete', Icons.delete_outline, AppColors.error,
              () => _confirmDelete(context, task)),
        ]),
      ],
    ),
  );

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );

  Widget _emptyState() => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.assignment_outlined, size: 48, color: AppColors.border),
      SizedBox(height: 12),
      Text('No tasks yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
      SizedBox(height: 4),
      Text('Tap + to create a task', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
    ]),
  );

  void _showCreateTaskSheet(BuildContext ctx) {
    final users = ref.read(usersListProvider).users;
    _showTaskSheet(ctx, null, users);
  }

  void _showEditSheet(BuildContext ctx, TaskModel task) {
    final users = ref.read(usersListProvider).users;
    _showTaskSheet(ctx, task, users);
  }

  void _showTaskSheet(BuildContext ctx, TaskModel? existing, List<UserModel> users) {
    final titleCtrl  = TextEditingController(text: existing?.title);
    final descCtrl   = TextEditingController(text: existing?.description);
    final instrCtrl  = TextEditingController(text: existing?.instructions);
    final amountCtrl = TextEditingController(text: existing?.paymentAmount.toString() ?? '0');
    String priority  = existing?.priority ?? 'medium';
    String? assignedTo = existing?.assignedToId;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 36, height: 3,
                    decoration: BoxDecoration(color: AppColors.border,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 18),
                Text(existing == null ? 'New Task' : 'Edit Task',
                    style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 18),
                AppTextField(controller: titleCtrl, label: 'Title',
                    prefixIcon: Icons.assignment_outlined),
                const SizedBox(height: 10),
                AppTextField(controller: descCtrl, label: 'Description',
                    prefixIcon: Icons.notes_outlined, maxLines: 3),
                const SizedBox(height: 10),
                AppTextField(controller: instrCtrl, label: 'Instructions',
                    prefixIcon: Icons.info_outline, maxLines: 3),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: priority,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(labelText: 'Priority',
                      prefixIcon: Icon(Icons.flag_outlined, size: 18)),
                  items: ['low', 'medium', 'high'].map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p[0].toUpperCase() + p.substring(1),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  )).toList(),
                  onChanged: (v) => setSt(() => priority = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  value: assignedTo,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(labelText: 'Assign To',
                      prefixIcon: Icon(Icons.person_outline, size: 18)),
                  items: [
                    const DropdownMenuItem<String?>(value: null,
                        child: Text('Unassigned',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 14))),
                    ...users.map((u) => DropdownMenuItem<String?>(
                      value: u.id,
                      child: Text(u.fullName,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    )),
                  ],
                  onChanged: (v) => setSt(() => assignedTo = v),
                ),
                const SizedBox(height: 10),
                AppTextField(controller: amountCtrl, label: 'Payment (₹)',
                    prefixIcon: Icons.currency_rupee_outlined,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: existing == null ? 'Create Task' : 'Update Task',
                    onPressed: () async {
                      final data = {
                        'title': titleCtrl.text,
                        'description': descCtrl.text.isEmpty ? null : descCtrl.text,
                        'instructions': instrCtrl.text.isEmpty ? null : instrCtrl.text,
                        'priority': priority,
                        'assigned_to_id': assignedTo,
                        'payment_amount': double.tryParse(amountCtrl.text) ?? 0.0,
                      };
                      bool ok;
                      if (existing == null) {
                        ok = await ref.read(tasksProvider.notifier).createTask(data);
                      } else {
                        ok = await ref.read(tasksProvider.notifier).updateTask(existing.id, data);
                      }
                      if (ok && ctx.mounted) {
                        Navigator.pop(ctx);
                        showSuccessSnack(context,
                            existing == null ? 'Task created!' : 'Task updated!');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, TaskModel task) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Task?', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: Text('Delete "${task.title}"?',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(tasksProvider.notifier).deleteTask(task.id);
              if (mounted) showSuccessSnack(context, 'Task deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
