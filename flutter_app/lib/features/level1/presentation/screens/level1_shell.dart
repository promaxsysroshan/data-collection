import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import 'level1_home_screen.dart';
import 'level1_tasks_screen.dart';
import 'level1_submissions_screen.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class Level1Shell extends ConsumerStatefulWidget {
  const Level1Shell({super.key});
  @override
  ConsumerState<Level1Shell> createState() => _Level1ShellState();
}

class _Level1ShellState extends ConsumerState<Level1Shell> {
  int _index = 0;

  final _screens = const [
    Level1HomeScreen(),
    Level1TasksScreen(),
    Level1SubmissionsScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() => Container(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: SafeArea(
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            _navItem(0, Icons.grid_view_rounded, 'Home'),
            _navItem(1, Icons.assignment_outlined, 'Tasks'),
            _navItem(2, Icons.upload_file_outlined, 'Uploads'),
            _navItem(3, Icons.account_balance_wallet_outlined, 'Wallet'),
            _navItem(4, Icons.person_outline_rounded, 'Profile'),
          ],
        ),
      ),
    ),
  );

  Widget _navItem(int idx, IconData icon, String label) {
    final selected = _index == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _index = idx),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20,
              color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
              fontSize: 9,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              color: selected ? AppColors.primary : AppColors.textMuted,
            )),
          ],
        ),
      ),
    );
  }
}
