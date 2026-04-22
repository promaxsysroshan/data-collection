import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/admin/presentation/screens/admin_shell.dart';
import 'features/level1/presentation/screens/level1_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const ProviderScope(child: AudioDatasetApp()));
}

class AudioDatasetApp extends ConsumerWidget {
  const AudioDatasetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Audio Dataset System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    final auth = ref.read(authProvider);
    Widget dest;
    if (auth.isLoggedIn && auth.user != null) {
      dest = auth.user!.isAdmin ? const AdminShell() : const Level1Shell();
    } else {
      dest = const LoginScreen();
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a, __) => dest,
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),
            const Text('Audio Dataset',
              style: TextStyle(
                color: AppColors.textPrimary, fontSize: 22,
                fontWeight: FontWeight.w700,
              )),
            const SizedBox(height: 4),
            const Text('Dataset Collection Platform',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 48),
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                color: AppColors.textMuted, strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
