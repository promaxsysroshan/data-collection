import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/models/models.dart';
import '../providers/admin_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(usersListProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Users'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => ref.read(usersListProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2))
          : state.users.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 48, color: AppColors.border),
                    SizedBox(height: 12),
                    Text('No users found', style: TextStyle(color: AppColors.textSecondary)),
                  ]))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(usersListProvider.notifier).load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.users.length,
                    itemBuilder: (_, i) => _userCard(state.users[i]),
                  ),
                ),
    );
  }

  Widget _userCard(UserModel user) {
    final initials = user.fullName.split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(child: Text(initials, style: const TextStyle(
              color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 14))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(user.fullName, style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (user.isActive ? AppColors.success : AppColors.error)
                        .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(user.isActive ? 'Active' : 'Inactive', style: TextStyle(
                    color: user.isActive ? AppColors.success : AppColors.error,
                    fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ]),
              Text(user.email, style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 12, color: AppColors.success),
                const SizedBox(width: 3),
                Text('₹${user.walletBalance.toStringAsFixed(2)}', style: const TextStyle(
                  color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ],
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _actionBtn('Topup', Icons.add, AppColors.success,
              () => _showTopupSheet(user))),
          const SizedBox(width: 8),
          Expanded(child: _actionBtn('Profile', Icons.person_outline, AppColors.info,
              () => _showUserProfile(user))),
        ]),
      ]),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );

  void _showTopupSheet(UserModel user) {
    final amountCtrl = TextEditingController();
    final descCtrl   = TextEditingController(text: 'Admin top-up');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 3,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            const Text('Add Balance', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('${user.fullName}  ·  ₹${user.walletBalance.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
            AppTextField(controller: amountCtrl, label: 'Amount (₹)',
                prefixIcon: Icons.currency_rupee_outlined,
                keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            AppTextField(controller: descCtrl, label: 'Description',
                prefixIcon: Icons.notes_outlined),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: 'Add Balance',
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text);
                  if (amount == null || amount <= 0) return;
                  Navigator.pop(context);
                  final ok = await ref.read(usersListProvider.notifier)
                      .topupWallet(user.id, amount, descCtrl.text);
                  if (ok && mounted) {
                    showSuccessSnack(context,
                        '₹${amount.toStringAsFixed(0)} added to ${user.fullName}');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfile(UserModel user) {
    final initials = user.fullName.split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 3,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Center(child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border)),
              child: Center(child: Text(initials, style: const TextStyle(
                color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 20))),
            )),
            const SizedBox(height: 10),
            Center(child: Text(user.fullName, style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700))),
            Center(child: Text(user.email, style: const TextStyle(
                color: AppColors.textMuted, fontSize: 13))),
            const SizedBox(height: 20),
            _section('Personal', [
              if (user.age != null) _row('Age', '${user.age}'),
              if (user.gender != null) _row('Gender', user.gender!),
              if (user.phone != null) _row('Phone', user.phone!),
            ]),
            if (user.aadharNumber != null || user.panNumber != null)
              _section('KYC', [
                if (user.aadharNumber != null) _row('Aadhar', user.aadharNumber!),
                if (user.panNumber != null) _row('PAN', user.panNumber!),
              ]),
            if (user.bankName != null)
              _section('Bank', [
                if (user.bankName != null) _row('Bank', user.bankName!),
                if (user.bankAccountNumber != null) _row('Account', user.bankAccountNumber!),
                if (user.bankIfsc != null) _row('IFSC', user.bankIfsc!),
                if (user.upiId != null) _row('UPI', user.upiId!),
              ]),
            _section('Wallet', [_row('Balance', '₹${user.walletBalance.toStringAsFixed(2)}')]),
          ]),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppColors.textMuted,
          fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border)),
        child: Column(children: rows),
      ),
      const SizedBox(height: 16),
    ]);
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      const Spacer(),
      Text(value, style: const TextStyle(
          color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );
}
