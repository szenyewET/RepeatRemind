import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) {
          final notifier = ref.read(settingsProvider.notifier);
          return ListView(
            children: [
              // ── Theme ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Theme',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        )),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selected) {
                    if (selected.isNotEmpty) {
                      notifier.setThemeMode(selected.first);
                    }
                  },
                ),
              ),
              const Divider(),

              // ── Default advance notice ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('Notifications',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        )),
              ),
              ListTile(
                title: const Text('Default advance notice'),
                subtitle: const Text('Days before due date to remind you'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: settings.defaultAdvanceNoticeDays > 1
                          ? () => notifier.setDefaultAdvanceNoticeDays(
                              settings.defaultAdvanceNoticeDays - 1)
                          : null,
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${settings.defaultAdvanceNoticeDays}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: settings.defaultAdvanceNoticeDays < 30
                          ? () => notifier.setDefaultAdvanceNoticeDays(
                              settings.defaultAdvanceNoticeDays + 1)
                          : null,
                    ),
                  ],
                ),
              ),

              // ── Notification time ──────────────────────────────────────────
              ListTile(
                title: const Text('Notification time'),
                subtitle: Text(
                  _formatTime(settings.notificationHour, settings.notificationMinute),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: settings.notificationHour,
                      minute: settings.notificationMinute,
                    ),
                  );
                  if (picked != null) {
                    await notifier.setNotificationTime(
                      hour: picked.hour,
                      minute: picked.minute,
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }
}
