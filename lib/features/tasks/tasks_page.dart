import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database_provider.dart';
import '../../database/crud.dart';
import '../../database.dart' show Priority;
import '../../core/theme/colors.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/services/service_providers.dart';
import 'package:intl/intl.dart';

class TasksPage extends ConsumerWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Projects',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showProjectDialog(context, ref, database),
                    icon: const Icon(Icons.add, color: AppColors.textPrimary, size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Projects List
            Expanded(
              child: StreamBuilder<List<Project>>(
                stream: database.watchProjects(),
                builder: (context, snapshot) {
                  // Show loading only if waiting AND no data yet
                  final isLoading = !snapshot.hasData && 
                                   snapshot.connectionState == ConnectionState.waiting;
                  
                  if (isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textMuted,
                      ),
                    );
                  }

                  final projects = snapshot.data ?? [];

                  if (projects.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 48,
                            color: AppColors.gray500,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No projects',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: projects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 1),
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return _ProjectItem(
                        project: project,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProjectTasksPage(project: project),
                            ),
                          );
                        },
                        onEdit: () => _showProjectDialog(context, ref, database, project: project),
                        onDelete: () => _deleteProject(context, database, project),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectDialog(BuildContext context, WidgetRef ref, AppDatabase database,
      {Project? project}) {
    final nameController = TextEditingController(text: project?.name ?? '');
    final descriptionController = TextEditingController(text: project?.description ?? '');

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project == null ? 'New Project' : 'Edit Project',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              _MinimalTextField(
                controller: nameController,
                hint: 'Project name',
                autofocus: true,
              ),
              const SizedBox(height: 16),
              _MinimalTextField(
                controller: descriptionController,
                hint: 'Description (optional)',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _MinimalButton(
                    label: project == null ? 'Create' : 'Update',
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;

                      if (project == null) {
                        await database.insertProject(
                          ProjectsCompanion.insert(
                            name: nameController.text.trim(),
                            description: drift.Value(descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim()),
                          ),
                        );
                      } else {
                        await database.updateProject(
                          project.copyWith(
                            name: nameController.text.trim(),
                            description: drift.Value(descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim()),
                          ),
                        );
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteProject(BuildContext context, AppDatabase database, Project project) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delete Project',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete "${project.name}"?\nAll tasks will be removed.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  _MinimalButton(
                    label: 'Delete',
                    onPressed: () async {
                      await database.deleteProject(project.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectItem extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProjectItem({
    required this.project,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (project.description != null && project.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          project.description!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: AppColors.textMuted, size: 20),
                  color: AppColors.elevatedSurface,
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  offset: const Offset(-12, 0),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    else if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      height: 40,
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                          const SizedBox(width: 12),
                          Text('Edit', style: TextStyle(fontSize: 15)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      height: 40,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          const SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 15)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Project Tasks Page
class ProjectTasksPage extends ConsumerWidget {
  final Project project;

  const ProjectTasksPage({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showTaskDialog(context, database, project.id),
                    icon: const Icon(Icons.add, color: AppColors.textPrimary, size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Tasks List
            Expanded(
              child: StreamBuilder<List<Todo>>(
                stream: database.watchRootTasksByProject(project.id),
                builder: (context, snapshot) {
                  // Show loading only if waiting AND no data yet
                  final isLoading = !snapshot.hasData && 
                                   snapshot.connectionState == ConnectionState.waiting;
                  
                  if (isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textMuted,
                      ),
                    );
                  }

                  final tasks = snapshot.data ?? [];

                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 48, color: AppColors.gray500),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 1),
                    itemBuilder: (context, index) {
                      return _TaskItem(
                        task: tasks[index],
                        database: database,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailPage(
                                task: tasks[index],
                                project: project,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDialog(BuildContext context, AppDatabase database, int projectId, {int? parentId}) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    Priority selectedPriority = Priority.medium;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppColors.elevatedSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Task',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                _MinimalTextField(
                  controller: titleController,
                  hint: 'Task title',
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                _MinimalTextField(
                  controller: descriptionController,
                  hint: 'Description (optional)',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _PrioritySelector(
                  selected: selectedPriority,
                  onChanged: (p) => setState(() => selectedPriority = p),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    _MinimalButton(
                      label: 'Create',
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;
                        await database.insertTodo(
                          TodosCompanion.insert(
                            projectId: projectId,
                            parentId: drift.Value(parentId),
                            title: titleController.text.trim(),
                            description: drift.Value(descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim()),
                            priority: selectedPriority,
                          ),
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Task Detail Page
class TaskDetailPage extends ConsumerStatefulWidget {
  final Todo task;
  final Project project;

  const TaskDetailPage({super.key, required this.task, required this.project});

  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  final GlobalKey<_TaskRemindersListState> _remindersListKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);

    return StreamBuilder<Todo?>(
      stream: database.watchTodoById(widget.task.id),
      initialData: widget.task,
      builder: (context, snapshot) {
        final task = snapshot.data ?? widget.task;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _showEditTaskDialog(context, database),
                        icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary, size: 22),
                      ),
                      IconButton(
                        onPressed: () => _deleteTask(context, database),
                        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
                      ),
                    ],
                  ),
                ),

                // Task Details
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          database.updateTodo(task.copyWith(completed: !task.completed));
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: task.completed ? AppColors.accentBlue : AppColors.border,
                              width: 2,
                            ),
                            color: task.completed ? AppColors.accentBlue : Colors.transparent,
                          ),
                          child: task.completed
                              ? const Icon(Icons.check, size: 16, color: AppColors.background)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                                decoration: task.completed ? TextDecoration.lineThrough : null,
                                decorationColor: AppColors.textMuted,
                              ),
                            ),
                            if (task.description != null && task.description!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                task.description!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _priorityDot(task.priority),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 0.5,
                    color: AppColors.border,
                  ),
                ],
              ),
            ),

            // Reminders Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Text(
                    'Reminders',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      final saved = await _showAddReminderDialog(context, ref);
                      if (saved) {
                        _remindersListKey.currentState?._loadReminders();
                      }
                    },
                    icon: const Icon(Icons.add, color: AppColors.textSecondary, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Reminders List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: _TaskRemindersList(
                key: _remindersListKey,
                taskId: task.id,
              ),
            ),

            // Subtasks Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Text(
                    'Subtasks',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showSubtaskDialog(context, database),
                    icon: const Icon(Icons.add, color: AppColors.textSecondary, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Subtasks List
            Expanded(
              child: StreamBuilder<List<Todo>>(
                stream: database.watchSubtasks(task.id),
                builder: (context, snapshot) {
                  final subtasks = snapshot.data ?? [];

                  if (subtasks.isEmpty) {
                    return Center(
                      child: Text(
                        'No subtasks',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: subtasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 1),
                    itemBuilder: (context, index) {
                      return _TaskItem(
                        task: subtasks[index],
                        database: database,
                        isSubtask: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailPage(
                                task: subtasks[index],
                                project: widget.project,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }

  void _showEditTaskDialog(BuildContext context, AppDatabase database) {
    final titleController = TextEditingController(text: widget.task.title);
    final descriptionController = TextEditingController(text: widget.task.description ?? '');
    Priority selectedPriority = widget.task.priority;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppColors.elevatedSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Task',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                _MinimalTextField(
                  controller: titleController,
                  hint: 'Task title',
                ),
                const SizedBox(height: 16),
                _MinimalTextField(
                  controller: descriptionController,
                  hint: 'Description',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _PrioritySelector(
                  selected: selectedPriority,
                  onChanged: (p) => setState(() => selectedPriority = p),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    _MinimalButton(
                      label: 'Update',
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;
                        await database.updateTodo(
                          widget.task.copyWith(
                            title: titleController.text.trim(),
                            description: drift.Value(descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim()),
                            priority: selectedPriority,
                          ),
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSubtaskDialog(BuildContext context, AppDatabase database) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    Priority selectedPriority = Priority.medium;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppColors.elevatedSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Subtask',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                _MinimalTextField(
                  controller: titleController,
                  hint: 'Subtask title',
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                _MinimalTextField(
                  controller: descriptionController,
                  hint: 'Description (optional)',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _PrioritySelector(
                  selected: selectedPriority,
                  onChanged: (p) => setState(() => selectedPriority = p),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    _MinimalButton(
                      label: 'Create',
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;
                        await database.insertTodo(
                          TodosCompanion.insert(
                            projectId: widget.task.projectId,
                            parentId: drift.Value(widget.task.id),
                            title: titleController.text.trim(),
                            description: drift.Value(descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim()),
                            priority: selectedPriority,
                          ),
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteTask(BuildContext context, AppDatabase database) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delete Task',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete this task?\nAll subtasks will be removed.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  _MinimalButton(
                    label: 'Delete',
                    onPressed: () async {
                      await database.deleteTodo(widget.task.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showAddReminderDialog(BuildContext context, WidgetRef ref) async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppColors.elevatedSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Reminder',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Date selector
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.accentBlue,
                              surface: AppColors.elevatedSurface,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('MMM dd, yyyy').format(selectedDate),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Time selector
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.accentBlue,
                              surface: AppColors.elevatedSurface,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Text(
                          selectedTime.format(context),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    _MinimalButton(
                      label: 'Add',
                      onPressed: () async {
                        final reminderService = ref.read(reminderServiceProvider);
                        final reminderTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        await reminderService.addTaskReminder(widget.task.id, reminderTime);
                        if (context.mounted) Navigator.pop(context, true);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    return result ?? false;
  }
}

// Task Reminders List Widget
class _TaskRemindersList extends ConsumerStatefulWidget {
  final int taskId;

  const _TaskRemindersList({super.key, required this.taskId});

  @override
  ConsumerState<_TaskRemindersList> createState() => _TaskRemindersListState();
}

class _TaskRemindersListState extends ConsumerState<_TaskRemindersList> {
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    final reminderService = ref.read(reminderServiceProvider);
    final reminders = await reminderService.getTaskReminders(widget.taskId);
    if (mounted) {
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
          ),
        ),
      );
    }

    if (_reminders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: _reminders.map((reminder) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_outlined, size: 18, color: AppColors.accentBlue),
              const SizedBox(width: 12),
              Text(
                DateFormat('MMM dd, yyyy - hh:mm a').format(reminder.remindAt),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                onPressed: () async {
                  final reminderService = ref.read(reminderServiceProvider);
                  await reminderService.removeReminder(reminder.id);
                  await _loadReminders(); // Refresh the list
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
class _TaskItem extends StatelessWidget {
  final Todo task;
  final AppDatabase database;
  final bool isSubtask;
  final VoidCallback onTap;

  const _TaskItem({
    required this.task,
    required this.database,
    this.isSubtask = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: isSubtask ? 16 : 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    database.updateTodo(task.copyWith(completed: !task.completed));
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.completed ? AppColors.accentBlue : AppColors.border,
                        width: 2,
                      ),
                      color: task.completed ? AppColors.accentBlue : Colors.transparent,
                    ),
                    child: task.completed
                        ? const Icon(Icons.check, size: 12, color: AppColors.background)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          decoration: task.completed ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.textMuted,
                        ),
                      ),
                      if (task.description != null && task.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _priorityDot(task.priority),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Minimal UI Components
class _MinimalTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool autofocus;

  const _MinimalTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _MinimalButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  const _MinimalButton({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isDestructive ? AppColors.error.withOpacity(0.15) : AppColors.accentBlue.withOpacity(0.15),
        foregroundColor: isDestructive ? AppColors.error : AppColors.accentBlue,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  final Priority selected;
  final ValueChanged<Priority> onChanged;

  const _PrioritySelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Priority.values.map((priority) {
        final isSelected = Priority == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(priority),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? _priorityColor(priority).withOpacity(0.2) : AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? _priorityColor(priority) : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _priorityColor(priority),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _priorityLabel(priority),
                    style: TextStyle(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

Widget _priorityDot(Priority priority) {
  return Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: _priorityColor(priority),
      shape: BoxShape.circle,
    ),
  );
}

Color _priorityColor(Priority priority) {
  switch (priority) {
    case Priority.urgent:
      return AppColors.error;
    case Priority.high:
      return AppColors.warning;
    case Priority.medium:
      return AppColors.accentTeal;
    case Priority.low:
      return AppColors.textMuted;
  }
}

String _priorityLabel(Priority priority) {
  switch (priority) {
    case Priority.urgent:
      return 'Urgent';
    case Priority.high:
      return 'High';
    case Priority.medium:
      return 'Medium';
    case Priority.low:
      return 'Low';
  }
}


