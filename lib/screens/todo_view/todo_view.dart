import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../blocs/todo_bloc.dart';
import '../../models/todo.dart';
import '../../utils/constants.dart';
import '../add_edit_todo_screen/add_edit_todo_screen.dart';
import '../profile_screen/profile_screen.dart';

class TodoView extends StatelessWidget {
  const TodoView({super.key});

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
            Expanded(
              child: todos.isEmpty
                  ? Center(
                      child: Text(
                        "No tasks yet!",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: todos.length + 1, // +1 for spacing at bottom
                      itemBuilder: (context, index) {
                        if (index == todos.length) {
                          return const SizedBox(height: 100);
                        }
                        final todo = todos[index];
                        return _buildTodoItem(context, todo);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoItem(BuildContext context, Todo todo) {
    bool isOverdue = !todo.isCompleted && todo.date.isBefore(DateTime.now());

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
            leading: Checkbox(
              value: todo.isCompleted,
              activeColor: Theme.of(context).primaryColor,
              checkColor: Colors.white,
              side: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (_) =>
                  context.read<TodoBloc>().add(ToggleTodoEvent(todo)),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    todo.title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      decoration: todo.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: todo.isCompleted
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5)
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!todo.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
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
                        ).colorScheme.onSurface.withOpacity(0.7),
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
}
