import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/models/models.dart';
import '../providers/admin_provider.dart';
import '../../../../shared/widgets/file_viewer_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:audio_dataset_app/shared/widgets/video_player_screen.dart';

class AdminSubmissionsScreen extends ConsumerStatefulWidget {
  const AdminSubmissionsScreen({super.key});
  @override
  ConsumerState<AdminSubmissionsScreen> createState() => _AdminSubmissionsScreenState();
}

class _AdminSubmissionsScreenState extends ConsumerState<AdminSubmissionsScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(submissionsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(submissionsProvider);
    final subs = state.submissions.where((s) {
      if (_filter == 'all') return true;
      return s.status.toLowerCase() == _filter.toLowerCase();
    }).toList();

    final counts = {
      'all': state.submissions.length,
      'pending': state.submissions.where((s) => s.status == 'pending').length,
      'approved': state.submissions.where((s) => s.status == 'approved').length,
      'rejected': state.submissions.where((s) => s.status == 'rejected').length,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(children: [
          const Text('Submissions'),
          if (state.submissions.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border),
              ),
              child: Text('${state.submissions.length}', style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => ref.read(submissionsProvider.notifier).load(),
          ),
        ],
      ),
      body: Column(children: [
        _buildFilterBar(counts),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2))
              : state.error != null
                  ? _buildErrorState(state.error!)
                  : subs.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () => ref.read(submissionsProvider.notifier).load(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: subs.length,
                            itemBuilder: (_, i) => _buildCard(subs[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _buildFilterBar(Map<String, int> counts) {
    final filters = ['all', 'pending', 'approved', 'rejected'];
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
          final cnt = counts[f] ?? 0;
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
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(f == 'all' ? 'All' : f[0].toUpperCase() + f.substring(1),
                    style: TextStyle(
                        color: sel ? Colors.white : AppColors.textSecondary,
                        fontSize: 12, fontWeight: FontWeight.w600)),
                if (cnt > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: sel ? Colors.white.withOpacity(0.25) : AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text('$cnt', style: TextStyle(
                        color: sel ? Colors.white : AppColors.textSecondary,
                        fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(SubmissionModel sub) {
    final isPending = sub.status == 'pending';
    Color borderColor = AppColors.border;
    if (isPending) borderColor = AppColors.warning.withOpacity(0.4);
    if (sub.status == 'approved') borderColor = AppColors.success.withOpacity(0.3);
    if (sub.status == 'rejected') borderColor = AppColors.error.withOpacity(0.3);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: [
        _buildCardHeader(sub),
        if (sub.notes != null && sub.notes!.isNotEmpty)
          _infoBox('Notes', sub.notes!, AppColors.textSecondary),
        if (sub.adminRemarks != null && sub.adminRemarks!.isNotEmpty)
          _infoBox('Remarks', sub.adminRemarks!,
              sub.status == 'approved' ? AppColors.success : AppColors.error),
        _buildFilesSection(sub),
        _buildActionButtons(sub),
      ]),
    );
  }

  Widget _buildCardHeader(SubmissionModel sub) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.upload_file_outlined, size: 16, color: AppColors.textMuted),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(sub.taskTitle ?? 'Task', style: const TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 2),
        Text('${sub.userName ?? 'Unknown'}  ·  ${_formatDate(sub.createdAt)}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ])),
      StatusBadge(status: sub.status),
    ]),
  );

  Widget _infoBox(String label, String content, Color color) => Container(
    margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.15)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(content, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    ]),
  );

  Widget _buildFilesSection(SubmissionModel sub) {
    if (sub.files.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline, size: 13, color: AppColors.textMuted),
          SizedBox(width: 6),
          Text('No files attached', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Files (${sub.files.length})', style: const TextStyle(
            color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...sub.files.map((f) => _fileRow(f)),
      ]),
    );
  }

  Widget _fileRow(SubmissionFileModel f) => GestureDetector(
    onTap: () => _showFileSheet(f),
    child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Icon(_fileIcon(f.mimeType), size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f.originalFilename, style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 12),
              overflow: TextOverflow.ellipsis),
          Text(_formatSize(f.fileSize), style: const TextStyle(
              color: AppColors.textMuted, fontSize: 10)),
        ])),
        const Text('View', style: TextStyle(
            color: AppColors.info, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    ),
  );

  void _showFileSheet(SubmissionFileModel f) {
    final fileUrl = f.fileUrl != null
        ? '${ApiConstants.baseUrl}${f.fileUrl}'
        : '${ApiConstants.baseUrl}/uploads/submissions/${f.filename}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 3,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Row(children: [
              Icon(_fileIcon(f.mimeType), size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.originalFilename, style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                Text(_formatSize(f.fileSize), style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 12),
            _detailRow('File name', f.filename),
            _detailRow('MIME type', f.mimeType ?? 'Unknown'),
            _detailRow('Uploaded', _formatDate(f.createdAt)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(fileUrl, style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View File'),
                onPressed: () {
                  final mime = f.mimeType ?? '';
                  if (mime.startsWith('image/')) {
                    _openImageViewer(fileUrl);
                  } else if (mime.startsWith('video/')) {
                    final videoUrl = fileUrl.replaceFirst('/uploads', '/files');
                    _openVideoPlayer(videoUrl);
                  } else if (mime.contains('pdf')) {
                    _openPdfViewer(fileUrl);
                  } else {
                    launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(
          color: AppColors.textMuted, fontSize: 12))),
      Expanded(child: Text(value, style: const TextStyle(
          color: AppColors.textSecondary, fontSize: 12),
          overflow: TextOverflow.ellipsis)),
    ]),
  );

  void _openImageViewer(String url) {
    showDialog(context: context, builder: (_) => Dialog(
      child: InteractiveViewer(child: Image.network(url))));
  }

  void _openVideoPlayer(String url) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(url: url)));
  }

  void _openPdfViewer(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
  }

  Widget _buildActionButtons(SubmissionModel sub) {
    final isPending = sub.status == 'pending';
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
      ),
      padding: const EdgeInsets.all(10),
      child: isPending
          ? Row(children: [
              Expanded(child: _actionBtn('Approve', AppColors.success,
                  () => _showReviewDialog(sub, approve: true))),
              const SizedBox(width: 6),
              Expanded(child: _actionBtn('Reject', AppColors.error,
                  () => _showReviewDialog(sub, approve: false))),
              const SizedBox(width: 6),
              _deleteBtn(sub),
            ])
          : Row(children: [
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: (sub.status == 'approved' ? AppColors.success : AppColors.error)
                      .withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(child: Text(
                  sub.status == 'approved' ? 'Approved' : 'Rejected',
                  style: TextStyle(
                    color: sub.status == 'approved' ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600, fontSize: 12))),
              )),
              const SizedBox(width: 6),
              _deleteBtn(sub),
            ]),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Center(child: Text(label, style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 12))),
      ),
    );

  Widget _deleteBtn(SubmissionModel sub) => GestureDetector(
    onTap: () => _confirmDelete(sub),
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted),
    ),
  );

  void _showReviewDialog(SubmissionModel sub, {required bool approve}) {
    final remarksCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(20),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        title: Text(approve ? 'Approve Submission' : 'Reject Submission',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          if (sub.files.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.visibility_outlined, size: 15),
                label: const Text('View Submission', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final f = sub.files.first;
                  final url = f.fileUrl != null
                      ? '${ApiConstants.baseUrl}${f.fileUrl}'
                      : '${ApiConstants.baseUrl}/uploads/submissions/${f.filename}';
                  showDialog(context: context,
                      builder: (_) => FileViewerDialog(fileUrl: url));
                },
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: remarksCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: approve ? 'Add remarks (optional)' : 'Reason for rejection (optional)',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? AppColors.success : AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final status = approve ? 'approved' : 'rejected';
              final remarks = remarksCtrl.text.trim().isEmpty ? null : remarksCtrl.text.trim();
              final ok = await ref.read(submissionsProvider.notifier)
                  .review(sub.id, status, remarks);
              if (mounted) {
                ok
                    ? showSuccessSnack(context, approve ? 'Approved!' : 'Rejected.')
                    : showErrorSnack(context, 'Failed. Try again.');
              }
            },
            child: Text(approve ? 'Approve' : 'Reject',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(SubmissionModel sub) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete?', style: TextStyle(
            color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Delete submission by ${sub.userName ?? 'Unknown'}? Cannot be undone.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ref.read(submissionsProvider.notifier).delete(sub.id);
              if (mounted) {
                ok
                    ? showSuccessSnack(context, 'Deleted.')
                    : showErrorSnack(context, 'Failed. Try again.');
              }
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  IconData _fileIcon(String? mime) {
    if (mime == null) return Icons.attach_file_outlined;
    if (mime.startsWith('audio')) return Icons.audio_file_outlined;
    if (mime.startsWith('video')) return Icons.video_file_outlined;
    if (mime.startsWith('image')) return Icons.image_outlined;
    if (mime.contains('pdf')) return Icons.picture_as_pdf_outlined;
    return Icons.description_outlined;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return iso; }
  }

  Widget _buildEmptyState() => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.upload_file_outlined, size: 48, color: AppColors.border),
      SizedBox(height: 12),
      Text('No submissions', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
    ]),
  );

  Widget _buildErrorState(String error) => Center(
    child: Padding(padding: const EdgeInsets.all(32), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.error),
      const SizedBox(height: 12),
      Text(error, style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          textAlign: TextAlign.center),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () => ref.read(submissionsProvider.notifier).load(),
        child: const Text('Retry'),
      ),
    ])),
  );
}
