import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';

/// Modal bottom sheet for the Mark as Done flow.
///
/// 1. Shows the previewed next due date from [taskRepositoryProvider].
/// 2. Allows the user to adjust the date via [showDatePicker].
/// 3. On Confirm: calls [TaskListNotifier.commitCompletion], plays haptic,
///    pops the sheet, and shows a success SnackBar on the parent scaffold.
void showMarkAsDoneSheet(
  BuildContext context,
  WidgetRef ref,
  Task task,
) {
  final previewDate =
      ref.read(taskRepositoryProvider).previewNextDueDate(task, DateTime.now());

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _MarkAsDoneSheet(
      task: task,
      previewDate: previewDate,
      parentContext: context,
      ref: ref,
    ),
  );
}

// ── Internal StatefulWidget ───────────────────────────────────────────────

class _MarkAsDoneSheet extends StatefulWidget {
  final Task task;
  final DateTime previewDate;
  final BuildContext parentContext;
  final WidgetRef ref;

  const _MarkAsDoneSheet({
    required this.task,
    required this.previewDate,
    required this.parentContext,
    required this.ref,
  });

  @override
  State<_MarkAsDoneSheet> createState() => _MarkAsDoneSheetState();
}

class _MarkAsDoneSheetState extends State<_MarkAsDoneSheet> {
  late DateTime _selectedDate;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.previewDate;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);

    // Let the checkmark animate for 500ms before dismissing
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final confirmedDate = _selectedDate;

    await widget.ref
        .read(taskListProvider.notifier)
        .commitCompletion(widget.task, confirmedDate);

    HapticFeedback.mediumImpact();

    if (mounted) Navigator.of(context).pop();

    // Show success SnackBar on parent scaffold
    if (widget.parentContext.mounted) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: Text('Done! Next reminder: ${_formatDate(confirmedDate)}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _confirming
                  ? const Icon(
                      Icons.check_circle,
                      key: ValueKey('check'),
                      color: Colors.green,
                      size: 64,
                    )
                  : const SizedBox(key: ValueKey('no-check'), height: 0),
            ),
          ),
          if (_confirming) const SizedBox(height: 16),

          Text(
            'Mark as Done',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            widget.task.name,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),

          // ── Next due date row ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next due date',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(_selectedDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month_outlined),
                tooltip: 'Adjust date',
                onPressed: _confirming ? null : _pickDate,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Action buttons ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _confirming
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _confirming ? null : _confirm,
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
