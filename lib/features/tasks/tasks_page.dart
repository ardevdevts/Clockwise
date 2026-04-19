import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database_provider.dart';
import '../../database/crud.dart';
import '../../database.dart' show Priority;
import '../../core/theme/colors.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/services/service_providers.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:hugeicons/hugeicons.dart';
import 'dart:io';
import '../notes/note_editor_page.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  String _sortBy = 'created'; // created, name, progress

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<Project>>(
          stream: database.watchProjects(),
          builder: (context, snapshot) {
            final isLoading =
                !snapshot.hasData &&
                snapshot.connectionState == ConnectionState.waiting;

            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textMuted,
                ),
              );
            }

            var projects = snapshot.data ?? [];

            if (projects.isEmpty) {
              return Column(
                children: [
                  // Header with sort options
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Projects',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        // Sort button
                        PopupMenuButton<String>(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedSorting01,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                          color: AppColors.elevatedSurface,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSelected: (value) {
                            setState(() => _sortBy = value);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'created',
                              child: Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedClock01,
                                    size: 18,
                                    color: _sortBy == 'created'
                                        ? AppColors.accentBlue
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Recent',
                                    style: TextStyle(
                                      color: _sortBy == 'created'
                                          ? AppColors.accentBlue
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'name',
                              child: Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedSortingAZ01,
                                    size: 18,
                                    color: _sortBy == 'name'
                                        ? AppColors.accentBlue
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Name',
                                    style: TextStyle(
                                      color: _sortBy == 'name'
                                          ? AppColors.accentBlue
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'progress',
                              child: Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedArrowUp01,
                                    size: 18,
                                    color: _sortBy == 'progress'
                                        ? AppColors.accentBlue
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Progress',
                                    style: TextStyle(
                                      color: _sortBy == 'progress'
                                          ? AppColors.accentBlue
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedFolder01,
                            size: 64,
                            color: AppColors.gray500,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No projects yet',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to start your first one!',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // Sort projects
            if (_sortBy == 'name') {
              projects.sort((a, b) => a.name.compareTo(b.name));
            } else if (_sortBy == 'created') {
              projects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            }

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: AppColors.background,
                  floating: true,
                  snap: true,
                  toolbarHeight: 72,
                  automaticallyImplyLeading: false,
                  flexibleSpace: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Projects',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        // Sort button
                        PopupMenuButton<String>(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedSorting01,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                          color: AppColors.elevatedSurface,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSelected: (value) {
                            setState(() => _sortBy = value);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'created',
                              child: Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedClock01,
                                    size: 18,
                                    color: _sortBy == 'created'
                                        ? AppColors.accentBlue
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Recent',
                                    style: TextStyle(
                                      color: _sortBy == 'created'
                                          ? AppColors.accentBlue
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'name',
                              child: Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedSortingAZ01,
                                    size: 18,
                                    color: _sortBy == 'name'
                                        ? AppColors.accentBlue
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Name',
                                    style: TextStyle(
                                      color: _sortBy == 'name'
                                          ? AppColors.accentBlue
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'progress',
                              child: Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedArrowUp01,
                                    size: 18,
                                    color: _sortBy == 'progress'
                                        ? AppColors.accentBlue
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Progress',
                                    style: TextStyle(
                                      color: _sortBy == 'progress'
                                          ? AppColors.accentBlue
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index.isOdd) {
                        return const SizedBox(height: 16);
                      }
                      final projectIndex = index ~/ 2;
                      final project = projects[projectIndex];
                      return _ProjectCard(
                        project: project,
                        database: database,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProjectTasksPage(project: project),
                            ),
                          );
                        },
                        onEdit: () => _showProjectDialog(
                          context,
                          database,
                          project: project,
                        ),
                        onDelete: () =>
                            _deleteProject(context, database, project),
                      );
                    }, childCount: projects.length * 2 - 1),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProjectDialog(context, database),
        backgroundColor: AppColors.accentBlue,
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showProjectDialog(
    BuildContext context,
    AppDatabase database, {
    Project? project,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) =>
          _ProjectDialog(project: project, database: database),
    );
  }

  void _deleteProject(
    BuildContext context,
    AppDatabase database,
    Project project,
  ) {
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
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
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

// Project Dialog
class _ProjectDialog extends StatefulWidget {
  final Project? project;
  final AppDatabase database;

  const _ProjectDialog({this.project, required this.database});

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedColor;
  late String _selectedIcon;

  final List<String> _availableColors = [
    '00ADEF', // Blue
    '00BFA5', // Teal
    'FFB300', // Amber
    'D32F2F', // Red
    '00C853', // Green
    '9C27B0', // Purple
    'FF6F00', // Orange
    '607D8B', // Blue Grey
  ];

  final List<String> _availableIcons = [
    '📁',
    '💼',
    '🎯',
    '🚀',
    '💡',
    '🎨',
    '📚',
    '🏆',
    '⚡',
    '🔥',
    '🎮',
    '🎵',
    '🏋️',
    '🧪',
    '🌟',
    '✨',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.project?.description ?? '',
    );
    _selectedColor = widget.project?.color ?? '00ADEF';
    _selectedIcon = widget.project?.icon ?? '📁';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.elevatedSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.project == null ? 'New Project' : 'Edit Project',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // Icon Selector
              const Text(
                'Icon',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableIcons.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final icon = _availableIcons[index];
                    final isSelected = icon == _selectedIcon;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = icon),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _hexToColor(_selectedColor).withOpacity(0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? _hexToColor(_selectedColor)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            icon,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Color Selector
              const Text(
                'Color',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _availableColors.map((colorHex) {
                  final isSelected = colorHex == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = colorHex),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _hexToColor(colorHex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: isSelected
                          ? HugeIcon(
                              icon: HugeIcons.strokeRoundedTick02,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Name Field
              _MinimalTextField(
                controller: _nameController,
                hint: 'Project name',
                autofocus: true,
              ),
              const SizedBox(height: 16),

              // Description Field
              _MinimalTextField(
                controller: _descriptionController,
                hint: 'Description (optional)',
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _MinimalButton(
                    label: widget.project == null ? 'Create' : 'Update',
                    onPressed: () async {
                      if (_nameController.text.trim().isEmpty) return;

                      if (widget.project == null) {
                        await widget.database.insertProject(
                          ProjectsCompanion.insert(
                            name: _nameController.text.trim(),
                            description: drift.Value(
                              _descriptionController.text.trim().isEmpty
                                  ? null
                                  : _descriptionController.text.trim(),
                            ),
                            color: drift.Value(_selectedColor),
                            icon: drift.Value(_selectedIcon),
                          ),
                        );
                      } else {
                        await widget.database.updateProject(
                          widget.project!.copyWith(
                            name: _nameController.text.trim(),
                            description: drift.Value(
                              _descriptionController.text.trim().isEmpty
                                  ? null
                                  : _descriptionController.text.trim(),
                            ),
                            color: _selectedColor,
                            icon: drift.Value(_selectedIcon),
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
}

// Project Card Widget
class _ProjectCard extends StatelessWidget {
  final Project project;
  final AppDatabase database;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.database,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color _hexToColor(String hex) {
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, int>>(
      stream: database.watchProjectStats(project.uuid),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'total': 0, 'completed': 0};
        final total = stats['total'] ?? 0;
        final completed = stats['completed'] ?? 0;
        final progress = total > 0 ? completed / total : 0.0;

        return Dismissible(
          key: Key('project_${project.uuid}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              color: Colors.white,
              size: 28,
            ),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              barrierColor: Colors.black87,
              builder: (context) => Dialog(
                backgroundColor: AppColors.elevatedSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _MinimalButton(
                            label: 'Delete',
                            onPressed: () => Navigator.pop(context, true),
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          onDismissed: (_) => onDelete(),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _hexToColor(
                                project.color,
                              ).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                project.icon ?? '📁',
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Title and description
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                if (project.description != null &&
                                    project.description!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    project.description!,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // More menu
                          PopupMenuButton<String>(
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedMoreVertical,
                              color: AppColors.textMuted,
                              size: 22,
                            ),
                            color: AppColors.elevatedSurface,
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            offset: const Offset(-12, 0),
                            onSelected: (value) {
                              if (value == 'edit') {
                                onEdit();
                              } else if (value == 'delete') {
                                onDelete();
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                height: 44,
                                child: Row(
                                  children: [
                                    HugeIcon(
                                      icon: HugeIcons.strokeRoundedEdit02,
                                      size: 18,
                                      color: AppColors.textPrimary,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Edit',
                                      style: TextStyle(fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                height: 44,
                                child: Row(
                                  children: [
                                    HugeIcon(
                                      icon: HugeIcons.strokeRoundedDelete02,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                total > 0
                                    ? '$completed of $total tasks'
                                    : 'No tasks yet',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (total > 0)
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: TextStyle(
                                    color: _hexToColor(project.color),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.gray600,
                              valueColor: AlwaysStoppedAnimation(
                                _hexToColor(project.color),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),

                      // Last updated
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedClock01,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(project.createdAt),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Created today';
    } else if (difference.inDays == 1) {
      return 'Created yesterday';
    } else if (difference.inDays < 7) {
      return 'Created ${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Created ${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return 'Created ${months}mo ago';
    }
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
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
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
                      if (project.description != null &&
                          project.description!.isNotEmpty) ...[
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
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedMoreHorizontal,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  color: AppColors.elevatedSurface,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  offset: const Offset(-12, 0),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete')
                      onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      height: 40,
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedEdit02,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
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
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedDelete02,
                            size: 18,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 15,
                            ),
                          ),
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
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowLeft01,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
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
                    onPressed: () =>
                        _showTaskDialog(context, database, project.uuid),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      color: AppColors.textPrimary,
                      size: 28,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Tasks List
            Expanded(
              child: StreamBuilder<List<Todo>>(
                stream: database.watchRootTasksByProject(project.uuid),
                builder: (context, snapshot) {
                  // Show loading only if waiting AND no data yet
                  final isLoading =
                      !snapshot.hasData &&
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
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                            size: 48,
                            color: AppColors.gray500,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    itemCount: tasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 1),
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

  void _showTaskDialog(
    BuildContext context,
    AppDatabase database,
    String projectUuid, {
    String? parentUuid,
  }) {
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
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _MinimalButton(
                      label: 'Create',
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;
                        await database.insertTodo(
                          TodosCompanion.insert(
                            projectUuid: projectUuid,
                            parentUuid: drift.Value(parentUuid),
                            title: titleController.text.trim(),
                            description: drift.Value(
                              descriptionController.text.trim().isEmpty
                                  ? null
                                  : descriptionController.text.trim(),
                            ),
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
                // Sticky Header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.border.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowLeft01,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () =>
                                _showEditTaskDialog(context, database),
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedEdit02,
                              color: AppColors.accentBlue,
                              size: 22,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedMoreVertical,
                              color: AppColors.textSecondary,
                              size: 22,
                            ),
                            color: AppColors.elevatedSurface,
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteTask(context, database);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    HugeIcon(
                                      icon: HugeIcons.strokeRoundedDelete02,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Delete Task',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              database.updateTodo(
                                task.copyWith(completed: !task.completed),
                              );
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: task.completed
                                      ? AppColors.accentBlue
                                      : AppColors.border,
                                  width: 2.5,
                                ),
                                color: task.completed
                                    ? AppColors.accentBlue
                                    : Colors.transparent,
                              ),
                              child: task.completed
                                  ? HugeIcon(
                                      icon: HugeIcons.strokeRoundedTick02,
                                      size: 18,
                                      color: AppColors.background,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                                decoration: task.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _enhancedPriorityBadge(task.priority),
                        ],
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),

                        // Description Card
                        if (task.description != null &&
                            task.description!.isNotEmpty)
                          _SectionCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                task.description!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  height: 1.6,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),

                        // Reminders Section
                        _RemindersSection(
                          task: task,
                          remindersListKey: _remindersListKey,
                          onAddReminder: () async {
                            final saved = await _showAddReminderDialog(
                              context,
                              ref,
                            );
                            if (saved) {
                              _remindersListKey.currentState?._loadReminders();
                            }
                          },
                        ),

                        // Notes Section
                        _NotesSection(
                          task: task,
                          onEdit: () => _showNotesDialog(context, database),
                        ),

                        // Links Section
                        _LinksSection(
                          taskUuid: task.uuid,
                          onAddLink: () =>
                              _showAddLinkDialog(context, database),
                        ),

                        // Images Section
                        _ImagesSection(
                          taskUuid: task.uuid,
                          onAddImage: () =>
                              _showAddImageDialog(context, database),
                        ),

                        // Subtasks Section
                        _SubtasksSection(
                          task: task,
                          database: database,
                          project: widget.project,
                          onAddSubtask: () =>
                              _showSubtaskDialog(context, database),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showNotesDialog(
    BuildContext context,
    AppDatabase database,
  ) async {
    // If task already has a linked note, navigate to edit it
    if (widget.task.noteUuid != null) {
      final note = await database.getNoteByUuid(widget.task.noteUuid!);
      if (note != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => NoteEditorPage(note: note)),
        );
        return;
      }
    }

    // Otherwise, create a new note
    final titleController = TextEditingController(
      text: 'Note for: ${widget.task.title}',
    );
    final notesController = TextEditingController(
      text: widget.task.notes ?? '',
    );

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Task Note',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Note Title',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.accentBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 8,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Initial Content',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  hintText: 'Add initial notes content...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.accentBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;

                      // Convert plain text to Quill Delta format
                      final content = notesController.text.trim().isEmpty
                          ? '[{"insert":"\\n"}]'
                          : '[{"insert":"${notesController.text.trim().replaceAll('"', '\\"').replaceAll('\n', '\\n')}\\n"}]';

                      // Create the note
                      final noteId = await database.insertNote(
                        NotesCompanion.insert(
                          title: titleController.text.trim(),
                          content: content,
                        ),
                      );

                      // Get the newly created note to access its UUID
                      final newNote = await database.getNoteById(noteId);

                      // Link the note to the task
                      await database.updateTodo(
                        widget.task.copyWith(
                          noteUuid: drift.Value(newNote!.uuid),
                          notes: drift.Value(
                            notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                          ),
                        ),
                      );

                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Create Note'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddLinkDialog(BuildContext context, AppDatabase database) {
    final urlController = TextEditingController();
    final titleController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Link',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: urlController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://example.com',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.accentBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Title (optional)',
                  hintText: 'Link name',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.accentBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (urlController.text.trim().isEmpty) return;
                      await database.insertTodoLink(
                        TodoLinksCompanion.insert(
                          todoUuid: widget.task.uuid,
                          url: urlController.text.trim(),
                          title: drift.Value(
                            titleController.text.trim().isEmpty
                                ? null
                                : titleController.text.trim(),
                          ),
                        ),
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddImageDialog(BuildContext context, AppDatabase database) async {
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Image',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ImageSourceButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (image != null) {
                        await database.insertTodoImage(
                          TodoImagesCompanion.insert(
                            todoUuid: widget.task.uuid,
                            imagePath: image.path,
                          ),
                        );
                      }
                    },
                  ),
                  _ImageSourceButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        await database.insertTodoImage(
                          TodoImagesCompanion.insert(
                            todoUuid: widget.task.uuid,
                            imagePath: image.path,
                          ),
                        );
                      }
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

  void _showEditTaskDialog(BuildContext context, AppDatabase database) {
    final titleController = TextEditingController(text: widget.task.title);
    final descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );
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
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _MinimalButton(
                      label: 'Update',
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;
                        await database.updateTodo(
                          widget.task.copyWith(
                            title: titleController.text.trim(),
                            description: drift.Value(
                              descriptionController.text.trim().isEmpty
                                  ? null
                                  : descriptionController.text.trim(),
                            ),
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
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _MinimalButton(
                      label: 'Create',
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;
                        await database.insertTodo(
                          TodosCompanion.insert(
                            projectUuid: widget.task.projectUuid,
                            parentUuid: drift.Value(widget.task.uuid),
                            title: titleController.text.trim(),
                            description: drift.Value(
                              descriptionController.text.trim().isEmpty
                                  ? null
                                  : descriptionController.text.trim(),
                            ),
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
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _MinimalButton(
                    label: 'Delete',
                    onPressed: () async {
                      await database.deleteTodo(widget.task.id);
                      if (context.mounted) {
                        context.pop(); // Close dialog
                        context.pop(); // Close task detail page
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

  Future<bool> _showAddReminderDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar03,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('MMM dd, yyyy').format(selectedDate),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedClock01,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          selectedTime.format(context),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
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
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _MinimalButton(
                      label: 'Add',
                      onPressed: () async {
                        final reminderService = ref.read(
                          reminderServiceProvider,
                        );
                        final reminderTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        await reminderService.addTaskReminder(
                          widget.task.uuid,
                          reminderTime,
                        );
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
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: 12,
              horizontal: isSubtask ? 16 : 0,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    database.updateTodo(
                      task.copyWith(completed: !task.completed),
                    );
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.completed
                            ? AppColors.accentBlue
                            : AppColors.border,
                        width: 2,
                      ),
                      color: task.completed
                          ? AppColors.accentBlue
                          : Colors.transparent,
                    ),
                    child: task.completed
                        ? HugeIcon(
                            icon: HugeIcons.strokeRoundedTick02,
                            size: 12,
                            color: AppColors.background,
                          )
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
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppColors.textMuted,
                        ),
                      ),
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
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
                _priorityBadge(task.priority),
                const SizedBox(width: 4),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: AppColors.textMuted,
                  size: 18,
                ),
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
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
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
        backgroundColor: isDestructive
            ? AppColors.error.withOpacity(0.15)
            : AppColors.accentBlue.withOpacity(0.15),
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

  const _PrioritySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: DropdownButton<Priority>(
        value: selected,
        onChanged: (Priority? newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
        underline: const SizedBox.shrink(),
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedArrowDown01,
          color: AppColors.textSecondary,
        ),
        dropdownColor: AppColors.elevatedSurface,
        isExpanded: true,
        items: Priority.values.map((priority) {
          return DropdownMenuItem<Priority>(
            value: priority,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _priorityColor(priority),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _priorityLabel(priority),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

Widget _priorityBadge(Priority priority) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _priorityColor(priority),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      _priorityLabel(priority),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
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

// Enhanced Priority Badge
Widget _enhancedPriorityBadge(Priority priority) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: _priorityColor(priority).withOpacity(0.15),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _priorityColor(priority), width: 1.5),
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
            color: _priorityColor(priority),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

// Section Card Widget
class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
      ),
      child: child,
    );
  }
}

// Section Header Widget
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onAdd;
  final VoidCallback? onEdit;
  final int? count;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.onAdd,
    this.onEdit,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: AppColors.accentBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedEdit02,
                size: 20,
                color: AppColors.accentBlue,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (onAdd != null) ...[
            if (onEdit != null) const SizedBox(width: 12),
            IconButton(
              onPressed: onAdd,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedAddCircle,
                size: 22,
                color: AppColors.accentBlue,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

// Reminders Section
class _RemindersSection extends ConsumerWidget {
  final Todo task;
  final GlobalKey<_TaskRemindersListState> remindersListKey;
  final VoidCallback onAddReminder;

  const _RemindersSection({
    required this.task,
    required this.remindersListKey,
    required this.onAddReminder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _TaskRemindersList(
      key: remindersListKey,
      taskUuid: task.uuid,
      onAdd: onAddReminder,
    );
  }
}

// Task Reminders List
class _TaskRemindersList extends ConsumerStatefulWidget {
  final String taskUuid;
  final VoidCallback onAdd;

  const _TaskRemindersList({
    super.key,
    required this.taskUuid,
    required this.onAdd,
  });

  @override
  ConsumerState<_TaskRemindersList> createState() => _TaskRemindersListState();
}

class _TaskRemindersListState extends ConsumerState<_TaskRemindersList> {
  List<Reminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final reminderService = ref.read(reminderServiceProvider);
    final reminders = await reminderService.getTaskReminders(widget.taskUuid);
    if (mounted) {
      setState(() => _reminders = reminders);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Reminders',
          icon: Icons.notifications_outlined,
          count: _reminders.isEmpty ? null : _reminders.length,
          onAdd: widget.onAdd,
        ),
        if (_reminders.isNotEmpty)
          _SectionCard(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: _reminders.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 16, color: AppColors.border),
              itemBuilder: (context, index) {
                final reminder = _reminders[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedClock01,
                        size: 18,
                        color: AppColors.accentTeal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat(
                              'MMM dd, yyyy',
                            ).format(reminder.remindAt),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            DateFormat('hh:mm a').format(reminder.remindAt),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        size: 18,
                        color: AppColors.error,
                      ),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        final reminderService = ref.read(
                          reminderServiceProvider,
                        );
                        await reminderService.removeReminder(reminder.id);
                        await _loadReminders();
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// Notes Section
class _NotesSection extends ConsumerWidget {
  final Todo task;
  final VoidCallback onEdit;

  const _NotesSection({required this.task, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Notes',
          icon: Icons.note_outlined,
          onEdit: onEdit,
        ),
        if (task.noteUuid != null)
          FutureBuilder<Note?>(
            future: database.getNoteByUuid(task.noteUuid!),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final note = snapshot.data!;
              return _SectionCard(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NoteEditorPage(note: note),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedNote,
                          color: AppColors.accentBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (task.notes != null &&
                                  task.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  task.notes!,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          color: AppColors.accentBlue,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// Links Section
class _LinksSection extends ConsumerWidget {
  final String taskUuid;
  final VoidCallback onAddLink;

  const _LinksSection({required this.taskUuid, required this.onAddLink});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);

    return StreamBuilder<List<TodoLink>>(
      stream: database.watchTodoLinks(taskUuid),
      builder: (context, snapshot) {
        final links = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Links',
              icon: Icons.link,
              count: links.isEmpty ? null : links.length,
              onAdd: onAddLink,
            ),
            if (links.isNotEmpty)
              _SectionCard(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  itemCount: links.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final link = links[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final uri = Uri.parse(link.url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.accentBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedLinkSquare02,
                                  size: 16,
                                  color: AppColors.accentBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (link.title != null &&
                                        link.title!.isNotEmpty)
                                      Text(
                                        link.title!,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    Text(
                                      link.url,
                                      style: TextStyle(
                                        color:
                                            link.title != null &&
                                                link.title!.isNotEmpty
                                            ? AppColors.textMuted
                                            : AppColors.textPrimary,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: HugeIcon(
                                  icon: HugeIcons.strokeRoundedDelete02,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  await database.deleteTodoLink(link.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// Images Section
class _ImagesSection extends ConsumerWidget {
  final String taskUuid;
  final VoidCallback onAddImage;

  const _ImagesSection({required this.taskUuid, required this.onAddImage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);

    return StreamBuilder<List<TodoImage>>(
      stream: database.watchTodoImages(taskUuid),
      builder: (context, snapshot) {
        final images = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Images',
              icon: Icons.image_outlined,
              count: images.isEmpty ? null : images.length,
              onAdd: onAddImage,
            ),
            if (images.isNotEmpty)
              _SectionCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final image = images[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _ImageViewerPage(
                                images: images,
                                initialIndex: index,
                                onDelete: (id) async {
                                  await database.deleteTodoImage(id);
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.border.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(image.imagePath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.elevatedSurface,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: AppColors.textMuted,
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor:
                                            AppColors.elevatedSurface,
                                        title: const Text(
                                          'Delete Image',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        content: const Text(
                                          'Are you sure?',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await database.deleteTodoImage(image.id);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// Subtasks Section
class _SubtasksSection extends StatelessWidget {
  final Todo task;
  final AppDatabase database;
  final Project project;
  final VoidCallback onAddSubtask;

  const _SubtasksSection({
    required this.task,
    required this.database,
    required this.project,
    required this.onAddSubtask,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Todo>>(
      stream: database.watchSubtasks(task.uuid),
      builder: (context, snapshot) {
        final subtasks = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Subtasks',
              icon: Icons.checklist_outlined,
              count: subtasks.isEmpty ? null : subtasks.length,
              onAdd: onAddSubtask,
            ),
            if (subtasks.isNotEmpty)
              _SectionCard(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  itemCount: subtasks.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.border),
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
                              project: project,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// Image Source Button
class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accentBlue, size: 36),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Image Viewer Page
class _ImageViewerPage extends StatefulWidget {
  final List<TodoImage> images;
  final int initialIndex;
  final Function(int) onDelete;

  const _ImageViewerPage({
    required this.images,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              color: Colors.white,
            ),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.elevatedSurface,
                  title: const Text(
                    'Delete Image',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  content: const Text(
                    'Are you sure you want to delete this image?',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true && mounted) {
                await widget.onDelete(widget.images[_currentIndex].id);
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: widget.images.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: FileImage(File(widget.images[index].imagePath)),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image, color: Colors.white, size: 64),
              );
            },
          );
        },
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (context, event) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}
