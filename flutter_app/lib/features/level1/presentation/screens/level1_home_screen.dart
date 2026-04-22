import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/level1_provider.dart';

class Level1HomeScreen extends ConsumerStatefulWidget {
  const Level1HomeScreen({super.key});
  @override
  ConsumerState<Level1HomeScreen> createState() => _Level1HomeScreenState();
}

class _Level1HomeScreenState extends ConsumerState<Level1HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(l1DashboardProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final dash = ref.watch(l1DashboardProvider);
    final d    = dash.data;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(l1DashboardProvider.notifier).load(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.surface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: const Text('Home'),
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
                    _buildGreeting(auth, d),
                    const SizedBox(height: 24),
                    _buildStatsGrid(d),
                    const SizedBox(height: 24),
                    _buildSubmissionStats(d),
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

  Widget _buildGreeting(AuthState auth, Map<String, dynamic> d) {
    final name = auth.user?.fullName.split(' ').first ?? 'User';
    final balance = ((d['wallet_balance'] ?? 0) as num).toStringAsFixed(2);
    return Row(
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $name', style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
            Text('${d['pending_tasks'] ?? 0} pending tasks',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            const Icon(Icons.account_balance_wallet_outlined,
              size: 14, color: AppColors.textMuted),
            const SizedBox(width: 5),
            Text('₹$balance', style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
      ],
    );
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
          GradientCard(title: 'Total Tasks', value: '${d['total_tasks'] ?? 0}',
              icon: Icons.assignment_outlined, gradient: AppColors.primaryGradient),
          GradientCard(title: 'Pending', value: '${d['pending_tasks'] ?? 0}',
              icon: Icons.pending_outlined, gradient: AppColors.warningGradient),
          GradientCard(title: 'Approved', value: '${d['approved_tasks'] ?? 0}',
              icon: Icons.check_circle_outline, gradient: AppColors.successGradient),
          GradientCard(title: 'Rejected', value: '${d['rejected_tasks'] ?? 0}',
              icon: Icons.cancel_outlined, gradient: AppColors.warningGradient),
        ],
      ),
    ],
  );

  Widget _buildSubmissionStats(Map<String, dynamic> d) {
    final pending  = (d['pending_submissions'] ?? 0) as int;
    final approved = (d['approved_submissions'] ?? 0) as int;
    final rejected = (d['rejected_submissions'] ?? 0) as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Submissions'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            _statItem('Pending', pending, AppColors.warning),
            Container(width: 1, height: 36, color: AppColors.border),
            _statItem('Approved', approved, AppColors.success),
            Container(width: 1, height: 36, color: AppColors.border),
            _statItem('Rejected', rejected, AppColors.error),
          ]),
        ),
      ],
    );
  }

  Widget _statItem(String label, int count, Color color) => Expanded(
    child: Column(children: [
      Text('$count', style: TextStyle(
        color: color, fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
    ]),
  );

  Widget _buildRecentTasks(Map<String, dynamic> d) {
    final list = (d['recent_tasks'] as List?) ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recent Tasks'),
        const SizedBox(height: 12),
        ...list.map((t) {
          final task = t as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              const Icon(Icons.assignment_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task['title'] ?? '', style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  if ((task['payment_amount'] as num? ?? 0) > 0)
                    Text('₹${task['payment_amount']}', style: const TextStyle(
                      color: AppColors.success, fontSize: 11)),
                ],
              )),
              StatusBadge(status: task['status'] ?? 'pending'),
            ]),
          );
        }),
      ],
    );
  }

  Widget _buildShimmer() => Column(
    children: List.generate(4, (i) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShimmerBox(width: double.infinity, height: 72),
    )),
  );
}
