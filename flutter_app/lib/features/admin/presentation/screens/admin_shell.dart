import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import 'admin_home_screen.dart';
import 'admin_tasks_screen.dart';
import 'admin_submissions_screen.dart';
import 'admin_users_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});
  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  final _screens = const [
    AdminHomeScreen(),
    AdminTasksScreen(),
    AdminSubmissionsScreen(),
    AdminUsersScreen(),
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
            _navItem(0, Icons.grid_view_rounded, 'Dashboard'),
            _navItem(1, Icons.assignment_outlined, 'Tasks'),
            _navItem(2, Icons.upload_file_outlined, 'Submissions'),
            _navItem(3, Icons.people_outline_rounded, 'Users'),
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
