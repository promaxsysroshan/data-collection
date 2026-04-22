import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/models/models.dart';
import '../providers/level1_provider.dart';

class Level1TasksScreen extends ConsumerStatefulWidget {
  const Level1TasksScreen({super.key});
  @override
  ConsumerState<Level1TasksScreen> createState() => _Level1TasksScreenState();
}

class _Level1TasksScreenState extends ConsumerState<Level1TasksScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(myTasksProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myTasksProvider);
    final tasks = _filter == 'all'
        ? state.tasks
        : state.tasks.where((t) => t.status == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Tasks'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => ref.read(myTasksProvider.notifier).load(),
          ),
        ],
      ),
      body: Column(children: [
        _buildFilters(),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2))
              : state.error != null
                  ? _errorState(state.error!)
                  : tasks.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () => ref.read(myTasksProvider.notifier).load(),
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
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          if (task.instructions != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(child: Text(task.instructions!, style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 3, overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ],
          const SizedBox(height: 10),
          Row(children: [
            StatusBadge(status: task.status),
            const Spacer(),
            if (task.paymentAmount > 0)
              Text('₹${task.paymentAmount.toStringAsFixed(0)}', style: const TextStyle(
                  color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
      if (task.status == 'pending' || task.status == 'in_progress' || task.status == 'rejected') ...[
        Container(height: 1, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.all(10),
          child: task.status == 'pending'
              ? GestureDetector(
                  onTap: () => _startTask(task),
                  child: Container(
                    width: double.infinity,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(child: Text('Start Task', style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
                  ),
                )
              : GestureDetector(
                  onTap: () => _showSubmitSheet(task),
                  child: Container(
                    width: double.infinity,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(child: Text(
                      task.status == 'rejected' ? 'Resubmit Work' : 'Submit Work',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w600, fontSize: 13))),
                  ),
                ),
        ),
      ],
      if (task.status == 'submitted') ...[
        Container(height: 1, color: AppColors.border),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
          child: const Center(child: Text('Awaiting admin review',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
        ),
      ],
    ]),
  );

  Widget _emptyState() => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.assignment_outlined, size: 48, color: AppColors.border),
      SizedBox(height: 12),
      Text('No tasks yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
      SizedBox(height: 4),
      Text('Admin will assign tasks soon', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
    ]),
  );

  Widget _errorState(String error) => Center(
    child: Padding(padding: const EdgeInsets.all(32), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.error),
      const SizedBox(height: 12),
      Text(error, style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          textAlign: TextAlign.center),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () => ref.read(myTasksProvider.notifier).load(),
        child: const Text('Retry'),
      ),
    ])),
  );

  Future<void> _startTask(TaskModel task) async {
    final ok = await ref.read(myTasksProvider.notifier).startTask(task.id);
    if (mounted) {
      if (ok) {
        showSuccessSnack(context, 'Task started!');
      } else {
        showErrorSnack(context, ref.read(myTasksProvider).error ?? 'Failed to start task.');
      }
    }
  }

  void _showSubmitSheet(TaskModel task) {
    final notesCtrl = TextEditingController();
    List<PlatformFile> selectedFiles = [];

    showModalBottomSheet(
      context: context,
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 3,
                    decoration: BoxDecoration(color: AppColors.border,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 18),
                Text(task.status == 'rejected' ? 'Resubmit Work' : 'Submit Work',
                    style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(task.title, style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 20),
                AppTextField(controller: notesCtrl, label: 'Notes (optional)',
                    prefixIcon: Icons.notes_outlined, maxLines: 3),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      allowMultiple: true, type: FileType.any, withData: true);
                    if (result != null) setSt(() => selectedFiles = result.files);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.attach_file, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 7),
                        Text(
                          selectedFiles.isEmpty
                              ? 'Select files'
                              : '${selectedFiles.length} file(s) selected',
                          style: const TextStyle(color: AppColors.textSecondary,
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...selectedFiles.map((f) => Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      const Icon(Icons.insert_drive_file_outlined,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 7),
                      Expanded(child: Text(f.name, style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 12),
                          overflow: TextOverflow.ellipsis)),
                      Text(_formatSize(f.size), style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10)),
                    ]),
                  )),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: 'Submit',
                    icon: Icons.send_outlined,
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final files = selectedFiles
                          .where((f) => f.bytes != null)
                          .map((f) => {
                                'bytes': f.bytes!,
                                'name': f.name,
                                'mimeType': f.extension != null
                                    ? _mimeFromExt(f.extension!)
                                    : 'application/octet-stream'
                              })
                          .toList();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Row(children: [
                            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white)),
                            SizedBox(width: 12),
                            Text('Uploading…'),
                          ]),
                          duration: Duration(seconds: 30),
                        ));
                      }
                      final err = await ref.read(mySubmissionsProvider.notifier).submitTask(
                        taskId: task.id,
                        notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                        files: files,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        if (err == null) {
                          ref.read(myTasksProvider.notifier).load();
                          showSuccessSnack(context, 'Submitted!');
                        } else {
                          showErrorSnack(context, err);
                        }
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

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _mimeFromExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'mp3': case 'wav': case 'm4a': case 'ogg': return 'audio/$ext';
      case 'mp4': case 'mov': case 'avi': return 'video/$ext';
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'pdf': return 'application/pdf';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt': return 'text/plain';
      default: return 'application/octet-stream';
    }
  }
}
