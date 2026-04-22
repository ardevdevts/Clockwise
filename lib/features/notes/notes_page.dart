import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import 'file_notes_models.dart';
import 'file_notes_repository.dart';
import 'note_editor_page.dart';
import 'notes_providers.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  final Set<String> _expandedNodeUris = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repository = ref.read(fileNotesRepositoryProvider);
      final workspaces = await repository.getWorkspaces();
      if (workspaces.isNotEmpty) {
        ref.read(selectedWorkspaceIdProvider.notifier).state = workspaces.first.id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final workspacesAsync = ref.watch(workspacesProvider);
    final selectedWorkspaceId = ref.watch(selectedWorkspaceIdProvider);
    final selectedFile = ref.watch(selectedFileNodeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Notes',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: SafeArea(
          child: workspacesAsync.when(
            data: (workspaces) => _buildDrawer(context, workspaces, selectedWorkspaceId),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.textMuted),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load workspaces: $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ),
      ),
      body: selectedFile == null
          ? const _EmptyNoteSelection()
          : _SelectedFileView(node: selectedFile),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addWorkspace,
        backgroundColor: AppColors.accentBlue,
        icon: const Icon(Icons.create_new_folder, color: Colors.white),
        label: const Text('Add Workspace', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    List<NoteWorkspace> workspaces,
    String? selectedWorkspaceId,
  ) {
    final repository = ref.read(fileNotesRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Workspaces',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              IconButton(
                onPressed: _addWorkspace,
                icon: const Icon(Icons.add, color: AppColors.accentBlue),
              ),
            ],
          ),
        ),
        if (workspaces.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'No workspace added yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        Expanded(
          child: ListView(
            children: [
              ...workspaces.map((workspace) {
                final selected = workspace.id == selectedWorkspaceId;
                return ExpansionTile(
                  key: ValueKey(workspace.id),
                  initiallyExpanded: selected,
                  iconColor: AppColors.textSecondary,
                  collapsedIconColor: AppColors.textSecondary,
                  title: Text(
                    workspace.name,
                    style: TextStyle(
                      color: selected ? AppColors.accentBlue : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    workspace.treeUri,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  onExpansionChanged: (expanded) {
                    if (expanded) {
                      ref.read(selectedWorkspaceIdProvider.notifier).state = workspace.id;
                    }
                  },
                  trailing: PopupMenuButton<String>(
                    color: AppColors.elevatedSurface,
                    onSelected: (value) async {
                      switch (value) {
                        case 'new_note':
                          await _createMarkdownAtRoot(workspace);
                          break;
                        case 'new_folder':
                          await _createFolderAtRoot(workspace);
                          break;
                        case 'remove':
                          await repository.removeWorkspace(workspace.id);
                          if (ref.read(selectedWorkspaceIdProvider) == workspace.id) {
                            ref.read(selectedWorkspaceIdProvider.notifier).state = null;
                            ref.read(selectedFileNodeProvider.notifier).state = null;
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'new_note', child: Text('New note (.md)')),
                      PopupMenuItem(value: 'new_folder', child: Text('New folder')),
                      PopupMenuItem(value: 'remove', child: Text('Remove workspace')),
                    ],
                  ),
                  children: [
                    _WorkspaceTree(
                      workspace: workspace,
                      expandedNodeUris: _expandedNodeUris,
                      onOpenFile: (node) {
                        ref.read(selectedWorkspaceIdProvider.notifier).state = workspace.id;
                        ref.read(selectedFileNodeProvider.notifier).state = node;
                        Navigator.of(context).pop();
                      },
                      onChanged: () => setState(() {}),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addWorkspace() async {
    final repository = ref.read(fileNotesRepositoryProvider);
    final workspace = await repository.addWorkspaceFromPicker();
    if (workspace == null) return;

    ref.read(selectedWorkspaceIdProvider.notifier).state = workspace.id;
    if (mounted) setState(() {});
  }

  Future<void> _createMarkdownAtRoot(NoteWorkspace workspace) async {
    final name = await _promptForName('New note name', hint: 'meeting-notes');
    if (name == null || name.trim().isEmpty) return;

    final repository = ref.read(fileNotesRepositoryProvider);
    final rootUri = await repository.getRootUri(workspace);
    await repository.createMarkdownNote(
      workspace: workspace,
      parentUri: rootUri,
      title: name,
    );

    if (mounted) setState(() {});
  }

  Future<void> _createFolderAtRoot(NoteWorkspace workspace) async {
    final name = await _promptForName('New folder name', hint: 'research');
    if (name == null || name.trim().isEmpty) return;

    final repository = ref.read(fileNotesRepositoryProvider);
    final rootUri = await repository.getRootUri(workspace);
    await repository.createFolder(
      workspace: workspace,
      parentUri: rootUri,
      name: name,
    );

    if (mounted) setState(() {});
  }

  Future<String?> _promptForName(String title, {String? hint}) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create', style: TextStyle(color: AppColors.accentBlue)),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceTree extends ConsumerWidget {
  const _WorkspaceTree({
    required this.workspace,
    required this.expandedNodeUris,
    required this.onOpenFile,
    required this.onChanged,
  });

  final NoteWorkspace workspace;
  final Set<String> expandedNodeUris;
  final ValueChanged<NoteFileNode> onOpenFile;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _TreeChildren(
      workspace: workspace,
      directoryUri: null,
      depth: 0,
      expandedNodeUris: expandedNodeUris,
      onOpenFile: onOpenFile,
      onChanged: onChanged,
    );
  }
}

class _TreeChildren extends ConsumerWidget {
  const _TreeChildren({
    required this.workspace,
    required this.directoryUri,
    required this.depth,
    required this.expandedNodeUris,
    required this.onOpenFile,
    required this.onChanged,
  });

  final NoteWorkspace workspace;
  final String? directoryUri;
  final int depth;
  final Set<String> expandedNodeUris;
  final ValueChanged<NoteFileNode> onOpenFile;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(fileNotesRepositoryProvider);

    return FutureBuilder<List<NoteFileNode>>(
      future: repository.listChildren(workspace, directoryUri: directoryUri),
      builder: (context, snapshot) {
        final nodes = snapshot.data ?? const <NoteFileNode>[];
        if (snapshot.connectionState == ConnectionState.waiting && nodes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return Column(
          children: nodes.map((node) {
            final expanded = expandedNodeUris.contains(node.uri);
            return Column(
              children: [
                InkWell(
                  onTap: () {
                    if (node.isDirectory) {
                      if (expanded) {
                        expandedNodeUris.remove(node.uri);
                      } else {
                        expandedNodeUris.add(node.uri);
                      }
                      onChanged();
                    } else {
                      onOpenFile(node);
                    }
                  },
                  onLongPress: () => _showNodeMenu(context, ref, repository, node),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12 + (depth * 16), 6, 8, 6),
                    child: Row(
                      children: [
                        Icon(
                          node.isDirectory
                              ? (expanded ? Icons.folder_open : Icons.folder)
                              : Icons.description,
                          size: 18,
                          color: node.isDirectory
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            node.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (node.isDirectory && expanded)
                  _TreeChildren(
                    workspace: workspace,
                    directoryUri: node.uri,
                    depth: depth + 1,
                    expandedNodeUris: expandedNodeUris,
                    onOpenFile: onOpenFile,
                    onChanged: onChanged,
                  ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _showNodeMenu(
    BuildContext context,
    WidgetRef ref,
    FileNotesRepository repository,
    NoteFileNode node,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.note_add, color: AppColors.textPrimary),
              title: const Text('New note here', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.of(context).pop('new_note'),
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder, color: AppColors.textPrimary),
              title: const Text('New folder here', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.of(context).pop('new_folder'),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.textPrimary),
              title: const Text('Rename', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.of(context).pop('rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete', style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (action == null) return;

    switch (action) {
      case 'new_note':
        final name = await _prompt(context, 'New note name');
        if (name == null || name.trim().isEmpty) return;
        final parent = node.isDirectory ? node.uri : directoryUri;
        if (parent == null) return;
        await repository.createMarkdownNote(
          workspace: workspace,
          parentUri: parent,
          title: name,
        );
        onChanged();
        break;
      case 'new_folder':
        final name = await _prompt(context, 'New folder name');
        if (name == null || name.trim().isEmpty) return;
        final parent = node.isDirectory ? node.uri : directoryUri;
        if (parent == null) return;
        await repository.createFolder(
          workspace: workspace,
          parentUri: parent,
          name: name,
        );
        onChanged();
        break;
      case 'rename':
        final rename = await _prompt(context, 'Rename', initialValue: node.name);
        if (rename == null || rename.trim().isEmpty) return;
        await repository.renameNode(uri: node.uri, newName: rename.trim());
        onChanged();
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete', style: TextStyle(color: AppColors.textPrimary)),
            content: Text(
              'Delete "${node.name}"?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await repository.deleteNode(node.uri);
          final selected = ref.read(selectedFileNodeProvider);
          if (selected?.uri == node.uri) {
            ref.read(selectedFileNodeProvider.notifier).state = null;
          }
          onChanged();
        }
        break;
    }
  }

  Future<String?> _prompt(
    BuildContext context,
    String title, {
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SelectedFileView extends ConsumerWidget {
  const _SelectedFileView({required this.node});

  final NoteFileNode node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaces = ref.watch(workspacesProvider).value ?? const [];
    final selectedWorkspaceId = ref.watch(selectedWorkspaceIdProvider);
    final workspace = workspaces.where((w) => w.id == selectedWorkspaceId).firstOrNull;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                node.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                node.relativePath,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              Text(
                node.lastModified?.toIso8601String() ?? 'Unknown last modified',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: workspace == null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NoteEditorPage(
                                workspace: workspace,
                                node: node,
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.edit),
                  label: const Text('Open Editor'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNoteSelection extends StatelessWidget {
  const _EmptyNoteSelection();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Open the sidebar and pick a markdown file from a workspace.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
