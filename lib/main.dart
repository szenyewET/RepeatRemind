import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'models/category.dart';
import 'models/interval.dart';
import 'models/task.dart';
import 'providers/settings_provider.dart';
import 'providers/task_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  await Hive.initFlutter();
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(IntervalTypeAdapter());
  Hive.registerAdapter(IntervalAdapter());
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>('tasks');

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
    onDidReceiveNotificationResponse: (_) {},
  );

  runApp(
    ProviderScope(
      overrides: [
        notificationsPluginProvider.overrideWithValue(plugin),
      ],
      child: const RepeatRemindApp(),
    ),
  );
}

class RepeatRemindApp extends ConsumerStatefulWidget {
  const RepeatRemindApp({super.key});

  @override
  ConsumerState<RepeatRemindApp> createState() => _RepeatRemindAppState();
}

class _RepeatRemindAppState extends ConsumerState<RepeatRemindApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskRepositoryProvider).rescheduleAll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(taskSectionsProvider);
      ref.read(taskRepositoryProvider).rescheduleAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RepeatRemind',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ref.watch(themeModeProvider),
      home: ref.watch(settingsProvider).when(
        data: (s) => s.onboardingDone ? const HomeScreen() : const OnboardingScreen(),
        loading: () => const Scaffold(body: SizedBox.shrink()),
        error: (e, st) => const HomeScreen(),
      ),
    );
  }
}
