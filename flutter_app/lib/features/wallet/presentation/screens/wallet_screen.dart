import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/models/models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final walletTxnsProvider = FutureProvider<List<WalletTxnModel>>((ref) async {
  final r = await ApiClient.instance.get(ApiConstants.walletTransactions);
  return (r.data['data'] as List)
      .map((e) => WalletTxnModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final txnsAsync = ref.watch(walletTxnsProvider);
    final balance = auth.user?.walletBalance ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Wallet'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => ref.invalidate(walletTxnsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(walletTxnsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // Balance card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Balance',
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('₹${balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700,
                    )),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(children: [
                      const Icon(Icons.person_outline, color: Colors.white, size: 14),
                      const SizedBox(width: 7),
                      Text(auth.user?.fullName ?? 'User',
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w600, fontSize: 13)),
                      const Spacer(),
                      Text(auth.user?.role.toUpperCase() ?? '',
                        style: TextStyle(color: Colors.white.withOpacity(0.55),
                            fontSize: 10, letterSpacing: 1)),
                    ]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Info note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withOpacity(0.2)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: AppColors.success, size: 14),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Payments are credited automatically when admin approves your submission.',
                  style: TextStyle(color: AppColors.success, fontSize: 12))),
              ]),
            ),

            const SizedBox(height: 24),

            const SectionHeader(title: 'Transaction History'),
            const SizedBox(height: 12),

            txnsAsync.when(
              data: (txns) => txns.isEmpty
                  ? _emptyState()
                  : Column(children: txns.map((t) => _txnTile(t)).toList()),
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2)),
              ),
              error: (e, _) => Center(child: Text('Error: $e',
                  style: const TextStyle(color: AppColors.error, fontSize: 13))),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _txnTile(WalletTxnModel t) {
    final isCredit = t.transactionType == 'credit';
    final color = isCredit ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: color, size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.description ?? (isCredit ? 'Credit' : 'Debit'),
              style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
            Text(_formatDate(t.createdAt),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        )),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${isCredit ? '+' : '-'}₹${t.amount.toStringAsFixed(2)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
            Text('₹${t.balanceAfter.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ]),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return iso; }
  }

  Widget _emptyState() => const Padding(
    padding: EdgeInsets.all(32),
    child: Center(child: Column(children: [
      Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.border),
      SizedBox(height: 10),
      Text('No transactions yet',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
    ])),
  );
}
