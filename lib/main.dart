import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/vault_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_entry_screen.dart';
import 'screens/entry_detail_screen.dart';
import 'screens/entries_list_screen.dart';
import 'screens/sync_settings_screen.dart';
import 'screens/security_audit_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/password_generator_screen.dart';
import 'theme/app_theme.dart';
import 'models/password_entry.dart';
import 'widgets/ios_surface.dart';
import 'widgets/app_logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  FlutterError.onError = (details) {
    final exception = details.exception.toString();
    if (exception.contains('debugSize == size') &&
        exception.contains('text_painter.dart')) {
      return;
    }
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  runApp(
    ChangeNotifierProvider(
      create: (_) => VaultProvider(),
      child: const MiXiaApp(),
    ),
  );
}

class MiXiaApp extends StatelessWidget {
  const MiXiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VaultProvider>(
      builder: (context, provider, _) {
        return MaterialApp(
          title: '密匣',
          debugShowCheckedModeBanner: false,
          theme: provider.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/setup': (context) => const SetupScreen(),
            '/lock': (context) => const LockScreen(),
            '/home': (context) => const HomeScreen(),
            '/add_entry': (context) => const AddEntryScreen(),
            '/entry_detail': (context) {
              final entryId =
                  ModalRoute.of(context)!.settings.arguments as String;
              return EntryDetailScreen(entryId: entryId);
            },
            '/edit_entry': (context) {
              final entry =
                  ModalRoute.of(context)!.settings.arguments as PasswordEntry;
              return AddEntryScreen(entry: entry);
            },
            '/entries': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>?;
              return EntriesListScreen(
                type: args?['type'] as EntryType?,
                title: args?['title'] as String? ?? '全部条目',
              );
            },
            '/sync_settings': (context) => const SyncSettingsScreen(),
            '/security_audit': (context) => const SecurityAuditScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/password_generator': (context) => const PasswordGeneratorScreen(),
          },
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    final provider = context.read<VaultProvider>();

    await Future.wait([
      provider.initialize(),
      Future.delayed(const Duration(milliseconds: 800)),
    ]);

    if (!mounted) return;

    switch (provider.authState) {
      case AuthState.unauthenticated:
        Navigator.pushReplacementNamed(context, '/setup');
        break;
      case AuthState.locked:
        Navigator.pushReplacementNamed(context, '/lock');
        break;
      case AuthState.authenticated:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case AuthState.initial:
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/setup');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IosBackdrop(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 96, isHero: true),
              const SizedBox(height: 12),
              Text(
                '零后端 · 零信任 · 零负担',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
