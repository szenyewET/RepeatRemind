import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/interval.dart' as ri;
import '../models/task.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/category_icon.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  final Task? initialTask;

  const AddTaskScreen({super.key, this.initialTask});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _intervalValueController;
  late final TextEditingController _advanceNoticeController;
  late final TextEditingController _notesController;

  late Category _selectedCategory;
  late ri.IntervalType _selectedIntervalType;
  late DateTime _selectedDueDate;

  bool _advanceNoticeInitialised = false;

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTask;
    _nameController = TextEditingController(text: t?.name ?? '');
    _intervalValueController =
        TextEditingController(text: t != null ? '${t.interval.value}' : '1');
    _advanceNoticeController =
        TextEditingController(text: t != null ? '${t.advanceNoticeDays}' : '1');
    _notesController = TextEditingController(text: t?.notes ?? '');
    _selectedCategory = t?.category ?? Category.car;
    _selectedIntervalType = t?.interval.type ?? ri.IntervalType.days;
    _selectedDueDate = t?.nextDueDate ?? DateTime.now();
    // If editing, advance notice is already set from initialTask — skip settings default.
    if (_isEditing) _advanceNoticeInitialised = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _intervalValueController.dispose();
    _advanceNoticeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final intervalValue = int.tryParse(_intervalValueController.text) ?? 1;
    final advanceDays = int.tryParse(_advanceNoticeController.text) ?? 1;
    final notesText = _notesController.text.trim();

    if (_isEditing) {
      final edited = widget.initialTask!.copyWith(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        interval: ri.Interval(type: _selectedIntervalType, value: intervalValue),
        nextDueDate: _selectedDueDate,
        advanceNoticeDays: advanceDays,
        notes: notesText.isEmpty ? null : notesText,
      );
      await ref.read(taskListProvider.notifier).edit(edited);
    } else {
      final task = Task(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        interval: ri.Interval(type: _selectedIntervalType, value: intervalValue),
        nextDueDate: _selectedDueDate,
        advanceNoticeDays: advanceDays,
        notes: notesText.isEmpty ? null : notesText,
      );
      await ref.read(taskListProvider.notifier).add(task);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Initialise advance notice from settings once data is available (new task only).
    if (!_isEditing) {
      final settingsAsync = ref.watch(settingsProvider);
      settingsAsync.whenData((settings) {
        if (!_advanceNoticeInitialised) {
          _advanceNoticeController.text =
              '${settings.defaultAdvanceNoticeDays}';
          _advanceNoticeInitialised = true;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Name ────────────────────────────────────────────────────────
            TextFormField(
              key: const Key('task_name_field'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Task name',
                hintText: 'e.g. Oil Change',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Category ─────────────────────────────────────────────────────
            Text(
              'Category',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
              children: Category.values.map((cat) {
                final isSelected = cat == _selectedCategory;
                return InkWell(
                  onTap: () => setState(() => _selectedCategory = cat),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.4)
                          : null,
                    ),
                    child: Center(
                      child: CategoryIcon(
                        category: cat,
                        selected: isSelected,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Interval type ─────────────────────────────────────────────────
            Text(
              'Repeat every',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ri.IntervalType>(
              segments: const [
                ButtonSegment(value: ri.IntervalType.days, label: Text('Days')),
                ButtonSegment(value: ri.IntervalType.weeks, label: Text('Weeks')),
                ButtonSegment(value: ri.IntervalType.months, label: Text('Months')),
              ],
              selected: {_selectedIntervalType},
              onSelectionChanged: (selected) {
                if (selected.isNotEmpty) {
                  setState(() => _selectedIntervalType = selected.first);
                }
              },
            ),
            const SizedBox(height: 12),

            // ── Interval value ────────────────────────────────────────────────
            TextFormField(
              key: const Key('interval_value_field'),
              controller: _intervalValueController,
              decoration: const InputDecoration(
                labelText: 'Interval',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                final v = int.tryParse(value ?? '');
                if (v == null || v < 1) {
                  return 'Enter a number greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── First due date ────────────────────────────────────────────────
            Text(
              'First due date',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_formatDate(_selectedDueDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            // ── Advance notice ────────────────────────────────────────────────
            TextFormField(
              key: const Key('advance_notice_field'),
              controller: _advanceNoticeController,
              decoration: const InputDecoration(
                labelText: 'Advance notice (days)',
                hintText: '1–30',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                final v = int.tryParse(value ?? '');
                if (v == null || v < 1 || v > 30) {
                  return 'Enter a number between 1 and 30';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Notes ─────────────────────────────────────────────────────────
            TextFormField(
              key: const Key('notes_field'),
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
