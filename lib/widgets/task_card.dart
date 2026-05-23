import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../screens/task_detail_screen.dart';
import 'category_icon.dart';

String countdownLabel(DateTime nextDueDate, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
  final days = due.difference(today).inDays;
  if (days < 0) return 'Overdue';
  if (days == 0) return 'Today';
  return '$days days';
}

class TaskCard extends ConsumerWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final label = countdownLabel(task.nextDueDate, now);

    Color labelColor;
    if (label == 'Overdue') {
      labelColor = Theme.of(context).colorScheme.error;
    } else if (label == 'Today') {
      labelColor = Colors.amber.shade700;
    } else {
      labelColor = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.green.shade600,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.check, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        final preview = ref
            .read(taskRepositoryProvider)
            .previewNextDueDate(task, DateTime.now());
        await ref
            .read(taskListProvider.notifier)
            .commitCompletion(task, preview);
        return false; // keep the tile; list updates via provider
      },
      child: ListTile(
        leading: CategoryIcon(category: task.category),
        title: Text(task.name),
        trailing: Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(task: task),
            ),
          );
        },
      ),
    );
  }
}
