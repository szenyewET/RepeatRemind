import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/task_provider.dart';
import 'add_task_screen.dart';
import 'settings_screen.dart';
import '../widgets/task_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showPermissionBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final alreadyAsked = prefs.getBool('notificationPermissionAsked') ?? false;
      if (!alreadyAsked) {
        await ref.read(notificationServiceProvider).requestPermission();
        await prefs.setBool('notificationPermissionAsked', true);
      }

      // Check if permission was denied (stored by notification service or
      // inferred from prior denial). We surface the banner if the key exists
      // and is explicitly false.
      final granted = prefs.getBool('notificationPermissionGranted');
      if (granted == false && mounted) {
        setState(() => _showPermissionBanner = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(taskSectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RepeatRemind'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: sectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sections) {
          final bool allEmpty = sections.overdue.isEmpty &&
              sections.dueSoon.isEmpty &&
              sections.upcoming.isEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Summary chip ────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _SummaryChip(dueSoonCount: sections.dueSoon.length),
              ),

              // ── Notification permission banner ───────────────────────────
              if (_showPermissionBanner)
                _NotificationBanner(
                  onDismiss: () =>
                      setState(() => _showPermissionBanner = false),
                ),

              // ── Task sections or empty state ────────────────────────────
              Expanded(
                child: allEmpty
                    ? _EmptyState(
                        onAddTask: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AddTaskScreen()),
                        ),
                      )
                    : ListView(
                        children: [
                          if (sections.overdue.isNotEmpty) ...[
                            _SectionHeader(title: 'Overdue'),
                            ...sections.overdue
                                .map((t) => TaskCard(task: t)),
                          ],
                          if (sections.dueSoon.isNotEmpty) ...[
                            _SectionHeader(title: 'Due Soon'),
                            ...sections.dueSoon
                                .map((t) => TaskCard(task: t)),
                          ],
                          if (sections.upcoming.isNotEmpty) ...[
                            _SectionHeader(title: 'Upcoming'),
                            ...sections.upcoming
                                .map((t) => TaskCard(task: t)),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddTaskScreen()),
        ),
        tooltip: 'Add task',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Supporting widgets ──────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final int dueSoonCount;

  const _SummaryChip({required this.dueSoonCount});

  @override
  Widget build(BuildContext context) {
    final label =
        dueSoonCount == 0 ? 'All clear' : '$dueSoonCount due this week';
    return Chip(
      avatar: Icon(
        dueSoonCount == 0 ? Icons.check_circle_outline : Icons.schedule,
        size: 18,
      ),
      label: Text(label),
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const _NotificationBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_outlined, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Enable notifications to get reminders'),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDismiss,
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTask;

  const _EmptyState({required this.onAddTask});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onAddTask,
            child: const Text('Add your first task'),
          ),
        ],
      ),
    );
  }
}
