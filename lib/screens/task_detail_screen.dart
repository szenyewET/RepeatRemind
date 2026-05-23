import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/interval.dart' as ri;
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/category_icon.dart';
import 'add_task_screen.dart';

class TaskDetailScreen extends ConsumerWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(task.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddTaskScreen(initialTask: task),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Category ────────────────────────────────────────────────────
          _DetailRow(
            icon: categoryIcon(task.category),
            child: Text(categoryLabel(task.category)),
          ),
          const SizedBox(height: 12),

          // ── Interval ────────────────────────────────────────────────────
          _DetailRow(
            icon: Icons.repeat,
            child: Text(_intervalLabel(task.interval)),
          ),
          const SizedBox(height: 12),

          // ── Next due date ────────────────────────────────────────────────
          _DetailRow(
            icon: Icons.calendar_today,
            child: Text(_formatDate(task.nextDueDate)),
          ),
          const SizedBox(height: 12),

          // ── Advance notice ───────────────────────────────────────────────
          _DetailRow(
            icon: Icons.notifications_outlined,
            child: Text('${task.advanceNoticeDays} days before'),
          ),
          const SizedBox(height: 12),

          // ── Notes (only when present) ────────────────────────────────────
          if (task.notes != null) ...[
            _DetailRow(
              key: const Key('notes_row'),
              icon: Icons.notes,
              child: Text(task.notes!),
            ),
            const SizedBox(height: 12),
          ],

          const Divider(height: 32),

          // ── Mark as Done ─────────────────────────────────────────────────
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            },
            child: const Text('Mark as Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(taskListProvider.notifier).delete(task);
      if (context.mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    }
  }

  String _intervalLabel(ri.Interval interval) {
    return 'Every ${interval.value} ${interval.type.name}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ── Supporting widget ─────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _DetailRow({super.key, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}
