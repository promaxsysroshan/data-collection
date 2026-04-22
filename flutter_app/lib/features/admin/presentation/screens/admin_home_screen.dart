import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminDashboardProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final dash = ref.watch(adminDashboardProvider);
    final d    = dash.data;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(adminDashboardProvider.notifier).load(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.surface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: const Text('Dashboard'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: AppColors.border),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (dash.isLoading && d == null)
                    _buildShimmer()
                  else if (d != null) ...[
                    _buildGreeting(auth),
                    const SizedBox(height: 24),
                    _buildStatsGrid(d),
                    const SizedBox(height: 24),
                    _buildSubmissionStats(d),
                    const SizedBox(height: 24),
                    _buildRecentSubmissions(d),
                    const SizedBox(height: 24),
                    _buildRecentTasks(d),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(AuthState auth) {
    final name = auth.user?.fullName.split(' ').first ?? 'Admin';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Good ${_greeting()},', style: const TextStyle(
          color: AppColors.textMuted, fontSize: 14)),
        Text(name, style: const TextStyle(
          color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  Widget _buildStatsGrid(Map<String, dynamic> d) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeader(title: 'Overview'),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.3,
        children: [
          GradientCard(title: 'Total Users', value: '${d['total_users'] ?? 0}',
              icon: Icons.people_outline_rounded, gradient: AppColors.level1Gradient),
          GradientCard(title: 'Total Tasks', value: '${d['total_tasks'] ?? 0}',
              icon: Icons.assignment_outlined, gradient: AppColors.adminGradient),
          GradientCard(title: 'Pending Tasks', value: '${d['pending_tasks'] ?? 0}',
              icon: Icons.pending_outlined, gradient: AppColors.warningGradient),
          GradientCard(title: 'Disbursed',
              value: '₹${((d['total_wallet_disbursed'] ?? 0) as num).toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet_outlined, gradient: AppColors.walletGradient),
        ],
      ),
    ],
  );

  Widget _buildSubmissionStats(Map<String, dynamic> d) {
    final pending  = (d['pending_submissions'] ?? 0) as int;
    final approved = (d['approved_submissions'] ?? 0) as int;
    final rejected = (d['rejected_submissions'] ?? 0) as int;
    final total = pending + approved + rejected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Submissions'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(children: [
                _statPill('Pending', pending, AppColors.warning),
                const SizedBox(width: 8),
                _statPill('Approved', approved, AppColors.success),
                const SizedBox(width: 8),
                _statPill('Rejected', rejected, AppColors.error),
              ]),
              if (total > 0) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 4,
                    child: Row(children: [
                      if (pending > 0) Expanded(flex: pending,
                          child: Container(color: AppColors.warning)),
                      if (approved > 0) Expanded(flex: approved,
                          child: Container(color: AppColors.success)),
                      if (rejected > 0) Expanded(flex: rejected,
                          child: Container(color: AppColors.error)),
                    ]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _statPill(String label, int count, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        Text('$count', style: TextStyle(
          color: color, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
      ]),
    ),
  );

  Widget _buildRecentSubmissions(Map<String, dynamic> d) {
    final list = (d['recent_submissions'] as List?) ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recent Submissions'),
        const SizedBox(height: 12),
        ...list.map((s) => _listTile(
          title: s['task_title'] ?? 'Task',
          subtitle: s['user_name'] ?? 'User',
          icon: Icons.upload_file_outlined,
          trailing: StatusBadge(status: s['status'] ?? 'pending'),
        )),
      ],
    );
  }

  Widget _buildRecentTasks(Map<String, dynamic> d) {
    final list = (d['recent_tasks'] as List?) ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recent Tasks'),
        const SizedBox(height: 12),
        ...list.map((t) => _listTile(
          title: t['title'] ?? '',
          subtitle: t['assignee_name'] != null ? '→ ${t['assignee_name']}' : '',
          icon: Icons.assignment_outlined,
          trailing: StatusBadge(status: t['status'] ?? 'pending'),
        )),
      ],
    );
  }

  Widget _listTile({
    required String title, required String subtitle,
    required IconData icon, required Widget trailing,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(children: [
      Icon(icon, size: 16, color: AppColors.textMuted),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: const TextStyle(
              color: AppColors.textMuted, fontSize: 11)),
        ],
      )),
      trailing,
    ]),
  );

  Widget _buildShimmer() => Column(
    children: List.generate(4, (i) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShimmerBox(width: double.infinity, height: 72),
    )),
  );
}
