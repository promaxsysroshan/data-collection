import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../../admin/presentation/screens/admin_shell.dart';
import '../../../level1/presentation/screens/level1_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  bool _obscure = true;
  bool _isSignup = false;
  String _selectedRole = 'level1';

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose(); _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    bool ok;
    if (_isSignup) {
      if (_nameCtrl.text.isEmpty) return;
      ok = await ref.read(authProvider.notifier).signup(
        _emailCtrl.text.trim(), _passCtrl.text.trim(),
        _nameCtrl.text.trim(), _selectedRole,
      );
    } else {
      ok = await ref.read(authProvider.notifier).login(
        _emailCtrl.text.trim(), _passCtrl.text.trim(),
      );
    }
    if (ok && mounted) {
      final user = ref.read(authProvider).user!;
      Widget dest = user.isAdmin ? const AdminShell() : const Level1Shell();
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, a, __) => dest,
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (_) => false,
      );
    }
  }

  void _fillDemo(String role) {
    if (role == 'admin') {
      _emailCtrl.text = 'admin@example.com';
      _passCtrl.text  = 'admin123';
    } else {
      _emailCtrl.text = 'level1@example.com';
      _passCtrl.text  = 'level1123';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.book_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 24),
                const Text('Audio Dataset',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  )),
                const SizedBox(height: 4),
                Text(_isSignup ? 'Create your account' : 'Sign in to continue',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),

                const SizedBox(height: 36),

                // Role tabs
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    _roleTab('admin', 'Admin'),
                    _roleTab('level1', 'Level 1'),
                  ]),
                ),

                const SizedBox(height: 24),

                // Error
                if (auth.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 15),
                      const SizedBox(width: 8),
                      Expanded(child: Text(auth.error!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // Fields
                if (_isSignup) ...[
                  _field(_nameCtrl, 'Full Name', Icons.person_outline),
                  const SizedBox(height: 12),
                ],
                _field(_emailCtrl, 'Email address', Icons.mail_outline,
                    type: TextInputType.emailAddress),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  onSubmitted: (_) => _submit(),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18, color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit button
                GestureDetector(
                  onTap: auth.isLoading ? null : _submit,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: auth.isLoading ? AppColors.surfaceVariant : AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: auth.isLoading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isSignup ? 'Create Account' : 'Sign In',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600,
                            )),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _isSignup = !_isSignup);
                      ref.read(authProvider.notifier).clearError();
                    },
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13),
                        children: [
                          TextSpan(
                            text: _isSignup ? 'Already have an account? ' : "Don't have an account? ",
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          TextSpan(
                            text: _isSignup ? 'Sign In' : 'Sign Up',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Demo credentials
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Demo credentials',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11,
                          fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      const SizedBox(height: 10),
                      _credRow('Admin', 'admin@example.com / admin123', () => _fillDemo('admin')),
                      const SizedBox(height: 6),
                      _credRow('Level 1', 'level1@example.com / level1123', () => _fillDemo('level1')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleTab(String role, String label) {
    final sel = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedRole = role);
          if (!_isSignup) _fillDemo(role);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: sel ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: sel ? Border.all(color: AppColors.border) : null,
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              color: sel ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            )),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? type}) =>
    TextField(
      controller: ctrl,
      keyboardType: type,
      onSubmitted: (_) => _submit(),
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );

  Widget _credRow(String role, String creds, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(role, style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700,
          )),
        ),
        const SizedBox(width: 8),
        Text(creds, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const Spacer(),
        const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.textMuted),
      ]),
    );
}
