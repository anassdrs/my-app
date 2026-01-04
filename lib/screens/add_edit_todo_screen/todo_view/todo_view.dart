import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../../blocs/todo_bloc.dart';
import '../../../models/todo.dart';
import '../../../utils/constants.dart';
import '../add_edit_todo_screen.dart';
import '../../profile_screen/profile_screen.dart';
import '../../quran_screen/quran_screen.dart';

class TodoView extends StatefulWidget {
  const TodoView({super.key});

  @override
  State<TodoView> createState() => _TodoViewState();
}

class _TodoViewState extends State<TodoView> {
  String _statusFilter = 'all';
  final Set<String> _pendingIds = {};

  void _setFilter(String value) {
    setState(() => _statusFilter = value);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(
      builder: (context, state) {
        if (state is TodoInitial || state is TodoLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TodoLoaded) {
          return _buildTodoView(context, state.todos);
        } else if (state is TodoError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const Center(child: Text('Unknown state'));
      },
    );
  }

  Widget _buildTodoView(BuildContext context, List<Todo> todos) {
    final dailyTodos = todos
        .where(
          (todo) => todo.status == 'active' || todo.status == 'in_progress',
        )
        .toList();
    final visibleTodos = _statusFilter == 'all'
        ? dailyTodos
        : todos.where((todo) => todo.status == _statusFilter).toList();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'todo_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditTodoScreen()),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    "Tasks",
                    style: AppTextStyles.heading1.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusFilter(context),
            Expanded(
              child: visibleTodos.isEmpty
                  ? Center(
                      child: Text(
                        "No tasks yet!",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount:
                          visibleTodos.length + 1, // +1 for spacing at bottom
                      itemBuilder: (context, index) {
                        if (index == visibleTodos.length) {
                          return const SizedBox(height: 100);
                        }
                        final todo = visibleTodos[index];
                        return _buildTodoItem(context, todo);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Active', 'active'),
          const SizedBox(width: 8),
          _buildFilterChip('In Progress', 'in_progress'),
          const SizedBox(width: 8),
          _buildFilterChip('Paused', 'paused'),
          const SizedBox(width: 8),
          _buildFilterChip('Missed', 'missed'),
          const SizedBox(width: 8),
          _buildFilterChip('Done', 'done'),
          const SizedBox(width: 8),
          _buildFilterChip('Archived', 'archived'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () => _setFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTodoItem(BuildContext context, Todo todo) {
    bool isOverdue =
        todo.status != 'done' && todo.date.isBefore(DateTime.now());
    final isDone = todo.status == 'done';
    final isPending = _pendingIds.contains(todo.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) =>
                  context.read<TodoBloc>().add(DeleteTodoEvent(todo)),
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: BorderRadius.circular(15),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border(
              left: BorderSide(
                color: _getPriorityColor(todo.priority),
                width: 4,
              ),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            leading: _buildStatusIcon(todo.status),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    todo.title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5)
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!isDone)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      todo.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (!isDone) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      todo.status.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (todo.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      todo.description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: isOverdue ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _getFormattedDate(context, todo),
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? Colors.red : Colors.grey,
                          fontWeight: isOverdue
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isQuranMemorization(todo)) ...[
                  const SizedBox(height: 6),
                  Text(
                    _reviewLabel(todo),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _memorizationRangeLabel(todo),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openQuranRange(context, todo),
                        child: const Text('Read'),
                      ),
                    ],
                  ),
                ],
                if (todo.subtasks.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildSubtasks(context, todo, isPending),
                ],
                const SizedBox(height: 10),
                _buildStatusActions(context, todo, isPending),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditTodoScreen(todo: todo),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSubtasks(BuildContext context, Todo todo, bool isPending) {
    final readOnly =
        todo.status == 'paused' ||
        todo.status == 'archived' ||
        todo.status == 'done';
    return Column(
      children: todo.subtasks.map((subtask) {
        return Row(
          children: [
            Checkbox(
              value: subtask.completed,
              onChanged: readOnly || isPending
                  ? null
                  : (value) {
                      final updated = todo.subtasks
                          .map(
                            (item) => item.id == subtask.id
                                ? TodoSubtask(
                                    id: item.id,
                                    title: item.title,
                                    completed: value ?? false,
                                  )
                                : item,
                          )
                          .toList();
                      _updateSubtasks(context, todo, updated);
                    },
            ),
            Expanded(
              child: Text(
                subtask.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  decoration: subtask.completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _updateSubtasks(
    BuildContext context,
    Todo todo,
    List<TodoSubtask> updated,
  ) async {
    setState(() => _pendingIds.add(todo.id));
    final result = await context.read<TodoBloc>().updateTodoSubtasks(
      todo,
      updated,
      DateTime.now(),
    );
    if (!context.mounted) return;
    setState(() => _pendingIds.remove(todo.id));
    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Subtask update failed.')));
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 2:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 0:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getFormattedDate(BuildContext context, Todo todo) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todoDate = DateTime(todo.date.year, todo.date.month, todo.date.day);
    final difference = todoDate.difference(today).inDays;

    String dateStr;
    if (difference == 0) {
      dateStr = "Today";
    } else if (difference == 1) {
      dateStr = "Tomorrow";
    } else if (difference == -1) {
      dateStr = "Yesterday";
    } else {
      dateStr = DateFormat.yMMMd().format(todo.date);
    }

    final timeStr = TimeOfDay.fromDateTime(todo.date).format(context);
    String result = "$dateStr at $timeStr";

    if (todo.endTime != null) {
      final endTimeStr = TimeOfDay.fromDateTime(todo.endTime!).format(context);
      result += " - $endTimeStr";
    }

    return result;
  }

  Widget _buildStatusActions(BuildContext context, Todo todo, bool isPending) {
    final actions = _actionsForTodo(todo);
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      children: actions.map((action) {
        return TextButton(
          onPressed: isPending
              ? null
              : () => _handleStatusAction(context, todo, action),
          child: Text(action.label),
        );
      }).toList(),
    );
  }

  List<_TodoAction> _actionsForTodo(Todo todo) {
    if (_isQuranMemorization(todo)) {
      if (todo.status == 'archived') {
        return const [];
      }
      return const [
        _TodoAction('Start', 'start_review'),
        _TodoAction('Complete', 'complete_review'),
        _TodoAction('Archive', 'archived'),
      ];
    }
    return _actionsForStatus(todo.status);
  }

  List<_TodoAction> _actionsForStatus(String status) {
    switch (status) {
      case 'active':
        return const [
          _TodoAction('Start', 'in_progress'),
          _TodoAction('Complete', 'done'),
          _TodoAction('Pause', 'paused'),
          _TodoAction('Archive', 'archived'),
        ];
      case 'in_progress':
        return const [
          _TodoAction('Complete', 'done'),
          _TodoAction('Pause', 'paused'),
          _TodoAction('Archive', 'archived'),
        ];
      case 'paused':
        return const [
          _TodoAction('Resume', 'active'),
          _TodoAction('Archive', 'archived'),
        ];
      case 'missed':
        return const [
          _TodoAction('Reschedule', 'active'),
          _TodoAction('Archive', 'archived'),
        ];
      case 'done':
        return const [_TodoAction('Archive', 'archived')];
      case 'archived':
      default:
        return const [];
    }
  }

  Future<void> _handleStatusAction(
    BuildContext context,
    Todo todo,
    _TodoAction action,
  ) async {
    if (_isQuranMemorization(todo)) {
      if (action.targetStatus == 'start_review') {
        await _handleMemorizationStart(context, todo);
        return;
      }
      if (action.targetStatus == 'complete_review') {
        await _handleMemorizationComplete(context, todo);
        return;
      }
    }
    if (action.targetStatus == 'done' || action.targetStatus == 'archived') {
      final confirmed = await _confirmAction(
        context,
        action.targetStatus == 'done' ? 'Complete task?' : 'Archive task?',
      );
      if (confirmed != true) return;
    }

    if (!context.mounted) return;
    setState(() => _pendingIds.add(todo.id));
    final todoBloc = context.read<TodoBloc>();
    final result = await todoBloc.updateTodoStatus(
      todo,
      action.targetStatus,
      DateTime.now(),
    );
    if (!context.mounted) return;

    setState(() => _pendingIds.remove(todo.id));

    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Action failed.')));
      return;
    }

    final xpSuffix = result.xpDelta == 0
        ? ''
        : result.xpDelta > 0
        ? ' +${result.xpDelta} XP'
        : ' ${result.xpDelta} XP';
    final message = switch (action.targetStatus) {
      'in_progress' => 'Task started',
      'done' => 'Task completed$xpSuffix',
      'paused' => 'Task paused',
      'active' => 'Task resumed',
      'missed' => 'Task missed$xpSuffix',
      'archived' => 'Task archived',
      _ => 'Task updated',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool?> _confirmAction(BuildContext context, String title) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: const Text('Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusIcon(String status) {
    final icon = switch (status) {
      'active' => Icons.radio_button_unchecked,
      'in_progress' => Icons.timelapse,
      'paused' => Icons.pause_circle_outline,
      'done' => Icons.check_circle,
      'missed' => Icons.error_outline,
      'archived' => Icons.archive_outlined,
      _ => Icons.radio_button_unchecked,
    };
    final color = switch (status) {
      'done' => Colors.green,
      'missed' => Colors.redAccent,
      'paused' => Colors.orange,
      'in_progress' => Colors.blue,
      'archived' => Colors.grey,
      _ => Colors.grey,
    };
    return Icon(icon, color: color);
  }

  bool _isQuranMemorization(Todo todo) {
    return todo.category == 'Quran Memorization';
  }

  String _reviewLabel(Todo todo) {
    final due = todo.reviewDueDate;
    if (due == null) return 'Not scheduled';
    final diff = due.difference(DateTime.now());
    if (diff.isNegative) return '🔴 Review overdue';
    if (diff.inHours < 24) return '🕒 Review due today';
    return '🟢 Next review in ${diff.inDays} days';
  }

  String _memorizationRangeLabel(Todo todo) {
    final surah = todo.surahNumber;
    final start = todo.startAyah;
    final end = todo.endAyah;
    if (surah == null || start == null || end == null) {
      return 'Range not set';
    }
    return 'Surah $surah • Ayah $start-$end';
  }

  void _openQuranRange(BuildContext context, Todo todo) {
    final surah = todo.surahNumber;
    final start = todo.startAyah;
    final end = todo.endAyah;
    if (surah == null || start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set surah and ayah range first.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuranSurahScreen(
          surahNumber: surah,
          startAyah: start,
          endAyah: end,
        ),
      ),
    );
  }

  Future<void> _handleMemorizationStart(BuildContext context, Todo todo) async {
    final due = todo.reviewDueDate;
    final isDue = due != null && !due.isAfter(DateTime.now());
    if (!isDue) {
      final confirmed = await _confirmAction(context, 'Review early?');
      if (confirmed != true) return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Review session started')));
  }

  Future<void> _handleMemorizationComplete(
    BuildContext context,
    Todo todo,
  ) async {
    final outcome = await _showReviewOutcomeSheet(context);
    if (outcome == null) return;

    if (!context.mounted) return;
    setState(() => _pendingIds.add(todo.id));
    final todoBloc = context.read<TodoBloc>();
    final result = await todoBloc.applyMemorizationOutcome(
      todo,
      outcome: outcome,
      timestamp: DateTime.now(),
    );
    if (!context.mounted) return;
    setState(() => _pendingIds.remove(todo.id));
    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Review update failed.')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Review saved. ${_reviewLabel(todo)}')),
    );
  }

  Future<ReviewOutcome?> _showReviewOutcomeSheet(BuildContext context) {
    return showModalBottomSheet<ReviewOutcome>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Review outcome',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildOutcomeButton(
                  sheetContext,
                  label: '😃 Easy',
                  outcome: ReviewOutcome.easy,
                ),
                _buildOutcomeButton(
                  sheetContext,
                  label: '🙂 Good',
                  outcome: ReviewOutcome.good,
                ),
                _buildOutcomeButton(
                  sheetContext,
                  label: '😐 Hard',
                  outcome: ReviewOutcome.hard,
                ),
                _buildOutcomeButton(
                  sheetContext,
                  label: '❌ Forgot',
                  outcome: ReviewOutcome.forgot,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutcomeButton(
    BuildContext context, {
    required String label,
    required ReviewOutcome outcome,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, outcome),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        child: Text(label),
      ),
    );
  }
}

class _TodoAction {
  final String label;
  final String targetStatus;

  const _TodoAction(this.label, this.targetStatus);
}
