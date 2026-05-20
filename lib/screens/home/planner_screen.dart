import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/database_providers.dart';
import '../../services/ai_service.dart';
import '../../models/study_task_model.dart';
import 'package:intl/intl.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  bool _isGenerating = false;

  void _addTask() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDate;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Task',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Task Title'),
                      validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description (Optional)'),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                      title: Text(
                        selectedDate == null
                            ? 'Select Due Date'
                            : DateFormat('MMM dd, yyyy').format(selectedDate!),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setModalState(() {
                            selectedDate = date;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final user = ref.read(currentUserProvider);
                            if (user == null) return;

                            final newTask = StudyTaskModel(
                              id: '',
                              userId: user.id,
                              taskTitle: titleController.text.trim(),
                              taskDescription: descController.text.trim().isEmpty ? null : descController.text.trim(),
                              dueDate: selectedDate,
                              completed: false,
                              createdAt: DateTime.now(),
                            );

                            await ref.read(plannerRepositoryProvider).createTask(newTask);

                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          }
                        },
                        child: const Text('Add Task'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _toggleTask(StudyTaskModel task, bool completed) async {
    final updatedTask = task.copyWith(completed: completed);
    await ref.read(plannerRepositoryProvider).updateTask(updatedTask);
  }

  void _deleteTask(String taskId) async {
    await ref.read(plannerRepositoryProvider).deleteTask(taskId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted')),
      );
    }
  }

  Future<void> _generateAISchedule() async {
    setState(() => _isGenerating = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('No user');

      // Get the user's notes to use as context
      final notesRepo = ref.read(notesRepositoryProvider);
      final notesStream = notesRepo.getNotesStream(user.id);
      final notes = await notesStream.first;

      if (notes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload some notes first so AI can build your study plan!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final notesText = notes
          .map((n) => '${n.title}\n${n.content}')
          .join('\n\n---\n\n');

      final aiService = ref.read(aiServiceProvider);
      final tasks = await aiService.generateStudyTasks(notesText);

      for (final task in tasks) {
        final newTask = StudyTaskModel(
          id: '',
          userId: user.id,
          taskTitle: task['title'] ?? 'Study Task',
          taskDescription: task['description'],
          dueDate: DateTime.now().add(const Duration(days: 3)),
          completed: false,
          createdAt: DateTime.now(),
        );
        await ref.read(plannerRepositoryProvider).createTask(newTask);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tasks.length} AI study tasks added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI plan failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Planner'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progression Meter
            tasksAsync.when(
              data: (tasks) {
                final total = tasks.length;
                final completed = tasks.where((t) => t.completed).length;
                final ratio = total > 0 ? completed / total : 0.0;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daily Progress',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${(ratio * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 8,
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$completed of $total tasks completed',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),

            Text(
              'Active Tasks',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateAISchedule,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_isGenerating ? 'Generating...' : 'AI Study Plan'),
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tasks List
            Expanded(
              child: tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'All caught up! Add a new study task.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final dateStr = task.dueDate != null
                          ? DateFormat('MMM dd, yyyy').format(task.dueDate!)
                          : 'No due date';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Checkbox(
                            value: task.completed,
                            onChanged: (val) {
                              if (val != null) {
                                _toggleTask(task, val);
                              }
                            },
                          ),
                          title: Text(
                            task.taskTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: task.completed ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (task.taskDescription != null)
                                Text(
                                  task.taskDescription!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 12, color: Theme.of(context).colorScheme.secondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteTask(task.id),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Failed to load tasks: $err')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}
