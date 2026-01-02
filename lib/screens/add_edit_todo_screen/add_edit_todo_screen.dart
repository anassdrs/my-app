import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../models/todo.dart';
import '../../blocs/todo_bloc.dart';
import '../../utils/constants.dart';

class AddEditTodoScreen extends StatefulWidget {
  final Todo? todo;
  const AddEditTodoScreen({super.key, this.todo});

  @override
  State<AddEditTodoScreen> createState() => _AddEditTodoScreenState();
}

class _AddEditTodoScreenState extends State<AddEditTodoScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  DateTime? _selectedEndTime;
  late int _selectedPriority;
  late String _selectedCategory;

  final List<String> _categories = [
    'General',
    'Work',
    'Personal',
    'Shopping',
    'Health',
    'Study',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.todo?.description ?? '',
    );
    _selectedDate = widget.todo?.date ?? DateTime.now();
    _selectedEndTime = widget.todo?.endTime;
    _selectedPriority = widget.todo?.priority ?? 1;
    _selectedCategory = widget.todo?.category ?? 'General';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.todo == null ? "Add Task" : "Edit Task",
          style: AppTextStyles.heading2,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: AppTextStyles.heading2,
              decoration: InputDecoration(
                hintText: "What needs to be done?",
                hintStyle: AppTextStyles.heading2.copyWith(color: Colors.grey),
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
                hintStyle: AppTextStyles.bodyLarge.copyWith(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickDateTime,
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Start Time: ${_formatDateTime(_selectedDate)}",
                    style: AppTextStyles.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: _pickEndDateTime,
              child: Row(
                children: [
                  Icon(
                    Icons.event_available,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _selectedEndTime != null
                        ? "End Time: ${_formatDateTime(_selectedEndTime!)}"
                        : "End Time: Not set (tap to add)",
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: _selectedEndTime == null
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            // Priority Selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Priority",
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildPriorityChip(0, 'Low', Colors.green),
                    const SizedBox(width: 10),
                    _buildPriorityChip(1, 'Medium', Colors.orange),
                    const SizedBox(width: 10),
                    _buildPriorityChip(2, 'High', Colors.red),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Category Selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Category",
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
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
                                  ).colorScheme.onSurface.withOpacity(0.3),
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
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTodo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Save Task",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${TimeOfDay.fromDateTime(date).format(context)}";
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    if (!mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickEndDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedEndTime ?? _selectedDate,
      firstDate: _selectedDate,
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    if (!mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedEndTime ?? _selectedDate),
    );
    if (time == null) return;

    setState(() {
      _selectedEndTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Widget _buildPriorityChip(int priority, String label, Color color) {
    final isSelected = _selectedPriority == priority;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPriority = priority;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.2)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
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

  void _saveTodo() {
    if (_titleController.text.isEmpty) return;

    if (_selectedEndTime != null &&
        _selectedEndTime!.isBefore(_selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time cannot be before the start time.'),
        ),
      );
      return;
    }

    if (widget.todo != null) {
      widget.todo!.title = _titleController.text;
      widget.todo!.description = _descriptionController.text;
      widget.todo!.date = _selectedDate;
      widget.todo!.endTime = _selectedEndTime;
      widget.todo!.priority = _selectedPriority;
      widget.todo!.category = _selectedCategory;
      context.read<TodoBloc>().add(UpdateTodoEvent(widget.todo!));
    } else {
      final newTodo = Todo(
        id: const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        date: _selectedDate,
        endTime: _selectedEndTime,
        priority: _selectedPriority,
        category: _selectedCategory,
      );
      context.read<TodoBloc>().add(AddTodoEvent(newTodo));
    }

    Navigator.pop(context);
  }
}
