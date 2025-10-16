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
                          icon: const Icon(Icons.sort, color: AppColors.textSecondary, size: 24),
                          color: AppColors.elevatedSurface,
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onSelected: (value) {
                            setState(() => _sortBy = value);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'created',
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, size: 18, color: _sortBy == 'created' ? AppColors.accentBlue : AppColors.textSecondary),
                                  const SizedBox(width: 12),
                                  Text('Recent', style: TextStyle(color: _sortBy == 'created' ? AppColors.accentBlue : AppColors.textPrimary)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'name',
                              child: Row(
                                children: [
                                  Icon(Icons.sort_by_alpha, size: 18, color: _sortBy == 'name' ? AppColors.accentBlue : AppColors.textSecondary),
                                  const SizedBox(width: 12),
                                  Text('Name', style: TextStyle(color: _sortBy == 'name' ? AppColors.accentBlue : AppColors.textPrimary)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'progress',
                              child: Row(
                                children: [
                                  Icon(Icons.trending_up, size: 18, color: _sortBy == 'progress' ? AppColors.accentBlue : AppColors.textSecondary),
                                  const SizedBox(width: 12),
                                  Text('Progress', style: TextStyle(color: _sortBy == 'progress' ? AppColors.accentBlue : AppColors.textPrimary)),
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
                          Icon(
                            Icons.folder_open_outlined,
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
                          icon: const Icon(Icons.sort, color: AppColors.textSecondary, size: 24),
                          color: AppColors.elevatedSurface,
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onSelected: (value) {
                            setState(() => _sortBy = value);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'created',
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, size: 18, color: _sortBy == 'created' ? AppColors.accentBlue : AppColors.textSecondary),
                                  const SizedBox(width: 12),
                                  Text('Recent', style: TextStyle(color: _sortBy == 'created' ? AppColors.accentBlue : AppColors.textPrimary)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'name',
                              child: Row(
                                children: [
                                  Icon(Icons.sort_by_alpha, size: 18, color: _sortBy == 'name' ? AppColors.accentBlue : AppColors.textSecondary),
                                  const SizedBox(width: 12),
                                  Text('Name', style: TextStyle(color: _sortBy == 'name' ? AppColors.accentBlue : AppColors.textPrimary)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'progress',
                              child: Row(
                                children: [
                                  Icon(Icons.trending_up, size: 18, color: _sortBy == 'progress' ? AppColors.accentBlue : AppColors.textSecondary),
                                  const SizedBox(width: 12),
                                  Text('Progress', style: TextStyle(color: _sortBy == 'progress' ? AppColors.accentBlue : AppColors.textPrimary)),
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
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
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
                                builder: (context) => ProjectTasksPage(project: project),
                              ),
                            );
                          },
                          onEdit: () => _showProjectDialog(context, database, project: project),
                          onDelete: () => _deleteProject(context, database, project),
                        );
                      },
                      childCount: projects.length * 2 - 1,
                    ),
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
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showProjectDialog(BuildContext context, AppDatabase database, {Project? project}) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _ProjectDialog(project: project, database: database),
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
    '📁', '💼', '🎯', '🚀', '💡', '🎨', '📚', '🏆',
    '⚡', '🔥', '🎮', '🎵', '🏋️', '🧪', '🌟', '✨',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController = TextEditingController(text: widget.project?.description ?? '');
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
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final icon = _availableIcons[index];
                    final isSelected = icon == _selectedIcon;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = icon),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected ? _hexToColor(_selectedColor).withOpacity(0.15) : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? _hexToColor(_selectedColor) : Colors.transparent,
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
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
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
                            description: drift.Value(_descriptionController.text.trim().isEmpty
                                ? null
                                : _descriptionController.text.trim()),
                            color: drift.Value(_selectedColor),
                            icon: drift.Value(_selectedIcon),
                          ),
                        );
                      } else {
                        await widget.database.updateProject(
                          widget.project!.copyWith(
                            name: _nameController.text.trim(),
                            description: drift.Value(_descriptionController.text.trim().isEmpty
                                ? null
                                : _descriptionController.text.trim()),
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
      stream: database.watchProjectStats(project.id),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'total': 0, 'completed': 0};
        final total = stats['total'] ?? 0;
        final completed = stats['completed'] ?? 0;
        final progress = total > 0 ? completed / total : 0.0;
        
        return Dismissible(
          key: Key('project_${project.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
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
                        style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
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
                              color: _hexToColor(project.color).withOpacity(0.15),
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
                                if (project.description != null && project.description!.isNotEmpty) ...[
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
                            icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 22),
                            color: AppColors.elevatedSurface,
                            elevation: 8,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                                    Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                                    SizedBox(width: 12),
                                    Text('Edit', style: TextStyle(fontSize: 15)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                height: 44,
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                    SizedBox(width: 12),
                                    Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 15)),
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
                                total > 0 ? '$completed of $total tasks' : 'No tasks yet',
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
                              valueColor: AlwaysStoppedAnimation(_hexToColor(project.color)),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                      
                      // Last updated
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
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
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') onDelete();
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
                      _priorityBadge(task.priority),
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
                _priorityBadge(task.priority),
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
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
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


