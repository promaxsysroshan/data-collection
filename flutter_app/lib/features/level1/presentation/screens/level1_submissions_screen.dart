import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/models/models.dart';
import '../providers/level1_provider.dart';

class Level1SubmissionsScreen extends ConsumerStatefulWidget {
  const Level1SubmissionsScreen({super.key});
  @override
  ConsumerState<Level1SubmissionsScreen> createState() => _Level1SubmissionsScreenState();
}

class _Level1SubmissionsScreenState extends ConsumerState<Level1SubmissionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(mySubmissionsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mySubmissionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Submissions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => ref.read(mySubmissionsProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2))
          : state.submissions.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.upload_file_outlined, size: 48, color: AppColors.border),
                  SizedBox(height: 12),
                  Text('No submissions yet', style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 15)),
                  SizedBox(height: 4),
                  Text('Complete tasks and submit work', style: TextStyle(
                      color: AppColors.textMuted, fontSize: 13)),
                ]))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(mySubmissionsProvider.notifier).load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.submissions.length,
                    itemBuilder: (_, i) => _card(state.submissions[i]),
                  ),
                ),
    );
  }

  Widget _card(SubmissionModel sub) {
    final Color statusColor;
    switch (sub.status) {
      case 'approved': statusColor = AppColors.success; break;
      case 'rejected': statusColor = AppColors.error; break;
      default: statusColor = AppColors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(sub.taskTitle ?? 'Task', style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
              StatusBadge(status: sub.status),
            ]),
            const SizedBox(height: 3),
            Text(_formatDate(sub.createdAt),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            if (sub.notes != null && sub.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoBox('Your notes', sub.notes!, AppColors.textMuted),
            ],
            if (sub.adminRemarks != null && sub.adminRemarks!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _infoBox('Admin remarks', sub.adminRemarks!,
                  sub.status == 'approved' ? AppColors.success : AppColors.error),
            ],
            if (sub.files.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('${sub.files.length} file(s) uploaded', style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(spacing: 5, runSpacing: 5, children: sub.files.map((f) =>
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_fileIcon(f.mimeType), size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      f.originalFilename.length > 16
                          ? '${f.originalFilename.substring(0, 13)}…'
                          : f.originalFilename,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                  ]),
                )).toList()),
            ],
            if (sub.status == 'approved') ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.success.withOpacity(0.2)),
                ),
                child: const Center(child: Text('Payment credited to your wallet',
                    style: TextStyle(color: AppColors.success,
                        fontWeight: FontWeight.w600, fontSize: 12))),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _infoBox(String label, String content, Color color) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.15)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(content, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    ]),
  );

  IconData _fileIcon(String? mime) {
    if (mime == null) return Icons.attach_file_outlined;
    if (mime.startsWith('audio')) return Icons.audio_file_outlined;
    if (mime.startsWith('video')) return Icons.video_file_outlined;
    if (mime.startsWith('image')) return Icons.image_outlined;
    if (mime.contains('pdf')) return Icons.picture_as_pdf_outlined;
    return Icons.description_outlined;
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) { return iso; }
  }
}
