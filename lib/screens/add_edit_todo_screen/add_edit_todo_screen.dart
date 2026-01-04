import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import '../../models/todo.dart';
import '../../blocs/todo_bloc.dart';
import '../../blocs/add_edit_todo_bloc.dart';
import '../../utils/constants.dart';
import '../../widgets/primary_button.dart';

class AddEditTodoScreen extends StatelessWidget {
  final Todo? todo;
  const AddEditTodoScreen({super.key, this.todo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AddEditTodoBloc(todoBloc: context.read<TodoBloc>())
            ..add(InitializeTodoEvent(todo)),
      child: const _AddEditTodoView(),
    );
  }
}

class _AddEditTodoView extends StatefulWidget {
  const _AddEditTodoView();

  @override
  State<_AddEditTodoView> createState() => _AddEditTodoViewState();
}

class _AddEditTodoViewState extends State<_AddEditTodoView> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _reviewIntervalController;
  late TextEditingController _repeatCountController;
  final List<TextEditingController> _subtaskControllers = [];

  final List<String> _categories = [
    'General',
    'Work',
    'Personal',
    'Shopping',
    'Health',
    'Study',
    'Quran Memorization',
  ];

  static const List<String> _memorizationStatuses = [
    'UNLEARNED',
    'LEARNING',
    'REVIEW',
    'MASTERED',
    'NEEDS_REVIEW',
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<AddEditTodoBloc>().state;
    _titleController = TextEditingController(text: state.title);
    _descriptionController = TextEditingController(text: state.description);
    _reviewIntervalController = TextEditingController(
      text: state.reviewIntervalMinutes?.toString() ?? '',
    );
    _repeatCountController = TextEditingController(
      text: state.reviewRepeatCount?.toString() ?? '0',
    );

    for (final subtask in state.subtasks) {
      _subtaskControllers.add(TextEditingController(text: subtask.title));
    }

    _titleController.addListener(() {
      context.read<AddEditTodoBloc>().add(
        UpdateTodoFieldsEvent(title: _titleController.text),
      );
    });
    _descriptionController.addListener(() {
      context.read<AddEditTodoBloc>().add(
        UpdateTodoFieldsEvent(description: _descriptionController.text),
      );
    });
    _reviewIntervalController.addListener(() {
      final val = int.tryParse(_reviewIntervalController.text);
      context.read<AddEditTodoBloc>().add(
        UpdateTodoFieldsEvent(reviewIntervalMinutes: val),
      );
    });
    _repeatCountController.addListener(() {
      final val = int.tryParse(_repeatCountController.text);
      context.read<AddEditTodoBloc>().add(
        UpdateTodoFieldsEvent(reviewRepeatCount: val),
      );
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _reviewIntervalController.dispose();
    _repeatCountController.dispose();
    for (final c in _subtaskControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddEditTodoBloc, AddEditTodoState>(
      listener: (context, state) {
        if (state.isSuccess) Navigator.pop(context);
        if (state.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      child: BlocBuilder<AddEditTodoBloc, AddEditTodoState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                state.initialTodo == null ? "Add Task" : "Edit Task",
                style: AppTextStyles.heading2,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      style: AppTextStyles.heading2,
                      decoration: InputDecoration(
                        hintText: "What needs to be done?",
                        hintStyle: AppTextStyles.heading2.copyWith(
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _descriptionController,
                      style: AppTextStyles.bodyLarge,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Description (optional)",
                        hintStyle: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDateTimeRow(context, state),
                    const SizedBox(height: 25),
                    _buildPrioritySelector(context, state),
                    const SizedBox(height: 20),
                    _buildCategorySelector(context, state),
                    if (state.category == 'Quran Memorization') ...[
                      const SizedBox(height: 20),
                      _buildQuranSection(context, state),
                    ],
                    const SizedBox(height: 20),
                    _buildSubtasksSection(context, state),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: "Save Task",
                      onPressed: () =>
                          context.read<AddEditTodoBloc>().add(SaveTodoEvent()),
                      backgroundColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateTimeRow(BuildContext context, AddEditTodoState state) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            final picked = await _pickDateTime(context, state.date);
            if (!context.mounted) return;
            if (picked != null) {
              context.read<AddEditTodoBloc>().add(
                UpdateTodoFieldsEvent(date: picked),
              );
            }
          },
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
              const SizedBox(width: 10),
              Text(
                "Start Time: ${_formatDateTime(state.date)}",
                style: AppTextStyles.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: () async {
            final picked = await _pickDateTime(
              context,
              state.endDate ?? state.date,
            );
            if (!context.mounted) return;
            if (picked != null) {
              context.read<AddEditTodoBloc>().add(
                UpdateTodoFieldsEvent(endDate: picked),
              );
            }
          },
          child: Row(
            children: [
              Icon(
                Icons.event_available,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 10),
              Text(
                state.endDate != null
                    ? "End Time: ${_formatDateTime(state.endDate!)}"
                    : "End Time: Not set (tap to add)",
                style: AppTextStyles.bodyLarge.copyWith(
                  color: state.endDate == null
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector(BuildContext context, AddEditTodoState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Priority",
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildPriorityChip(
              context,
              0,
              'Low',
              Colors.green,
              state.priority == 0,
            ),
            const SizedBox(width: 10),
            _buildPriorityChip(
              context,
              1,
              'Medium',
              Colors.orange,
              state.priority == 1,
            ),
            const SizedBox(width: 10),
            _buildPriorityChip(
              context,
              2,
              'High',
              Colors.red,
              state.priority == 2,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityChip(
    BuildContext context,
    int priority,
    String label,
    Color color,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<AddEditTodoBloc>().add(
            UpdateTodoFieldsEvent(priority: priority),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? color
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context, AddEditTodoState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Category",
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = state.category == category;
            return GestureDetector(
              onTap: () {
                context.read<AddEditTodoBloc>().add(
                  UpdateTodoFieldsEvent(category: category),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuranSection(BuildContext context, AddEditTodoState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Memorization Status",
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _memorizationStatuses.map((status) {
            final isSelected = state.memorizationStatus == status;
            return GestureDetector(
              onTap: () {
                context.read<AddEditTodoBloc>().add(
                  UpdateTodoFieldsEvent(memorizationStatus: status),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildQuranRangeDropdowns(context, state),
        const SizedBox(height: 16),
        _buildQuranReviewFields(context, state),
      ],
    );
  }

  Widget _buildQuranRangeDropdowns(
    BuildContext context,
    AddEditTodoState state,
  ) {
    return Column(
      children: [
        DropdownButtonFormField<int>(
          initialValue: state.surahNumber,
          decoration: const InputDecoration(
            labelText: "Surah",
            border: OutlineInputBorder(),
          ),
          items: List.generate(quran.totalSurahCount, (i) {
            final n = i + 1;
            return DropdownMenuItem(
              value: n,
              child: Text("$n. ${quran.getSurahNameEnglish(n)}"),
            );
          }),
          onChanged: (val) {
            if (val != null) {
              context.read<AddEditTodoBloc>().add(
                UpdateTodoFieldsEvent(
                  surahNumber: val,
                  startAyah: 1,
                  endAyah: quran.getVerseCount(val),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: state.startAyah,
                decoration: const InputDecoration(
                  labelText: "Start",
                  border: OutlineInputBorder(),
                ),
                items: state.surahNumber == null
                    ? []
                    : List.generate(quran.getVerseCount(state.surahNumber!), (
                        i,
                      ) {
                        return DropdownMenuItem(
                          value: i + 1,
                          child: Text("${i + 1}"),
                        );
                      }),
                onChanged: (val) {
                  context.read<AddEditTodoBloc>().add(
                    UpdateTodoFieldsEvent(startAyah: val),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: state.endAyah,
                decoration: const InputDecoration(
                  labelText: "End",
                  border: OutlineInputBorder(),
                ),
                items: state.surahNumber == null
                    ? []
                    : List.generate(quran.getVerseCount(state.surahNumber!), (
                        i,
                      ) {
                        return DropdownMenuItem(
                          value: i + 1,
                          child: Text("${i + 1}"),
                        );
                      }),
                onChanged: (val) {
                  context.read<AddEditTodoBloc>().add(
                    UpdateTodoFieldsEvent(endAyah: val),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuranReviewFields(BuildContext context, AddEditTodoState state) {
    return Column(
      children: [
        TextField(
          controller: _reviewIntervalController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Review interval (min)",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _repeatCountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Repeat count",
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtasksSection(BuildContext context, AddEditTodoState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Subtasks",
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...List.generate(state.subtasks.length, (index) {
          if (_subtaskControllers.length <= index) {
            _subtaskControllers.add(
              TextEditingController(text: state.subtasks[index].title),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskControllers[index],
                    decoration: const InputDecoration(
                      hintText: "Subtask",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      context.read<AddEditTodoBloc>().add(
                        UpdateSubtaskEvent(index, val),
                      );
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _subtaskControllers[index].dispose();
                    _subtaskControllers.removeAt(index);
                    context.read<AddEditTodoBloc>().add(
                      RemoveSubtaskEvent(index),
                    );
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          );
        }),
        if (state.subtasks.length < 5)
          TextButton.icon(
            onPressed: () =>
                context.read<AddEditTodoBloc>().add(AddSubtaskEvent()),
            icon: const Icon(Icons.add),
            label: const Text("Add subtask"),
          ),
      ],
    );
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime current,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!context.mounted) return null;
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (!context.mounted) return null;
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDateTime(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
