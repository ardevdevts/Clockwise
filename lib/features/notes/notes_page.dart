import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:financialtracker/core/theme/colors.dart';
import 'package:financialtracker/database/crud.dart';
import 'package:financialtracker/features/notes/note_editor_page.dart';
import 'package:financialtracker/features/notes/notes_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../database/database_provider.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSidebarOpen = false;
  bool _isSelectionMode = false;
  final Set<int> _selectedNoteIds = {};
  final Set<String> _expandedFolderIds =
      {}; // Track which folders are expanded (using UUID)

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedNoteIds.clear();
      }
    });
  }

  void _toggleNoteSelection(int noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
      } else {
        _selectedNoteIds.add(noteId);
      }
    });
  }

  Future<void> _deleteSelectedNotes(AppDatabase database) async {
    if (_selectedNoteIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Notes',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedNoteIds.length} note${_selectedNoteIds.length > 1 ? 's' : ''}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final noteId in _selectedNoteIds) {
        await database.deleteNote(noteId);
      }
      setState(() {
        _selectedNoteIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final selectedFolder = ref.watch(selectedFolderProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            _buildMainContent(database, selectedFolder),

            // Sidebar overlay
            if (_isSidebarOpen)
              GestureDetector(
                onTap: _toggleSidebar,
                child: Container(color: Colors.black.withValues(alpha: 0.5)),
              ),

            // Sidebar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              left: _isSidebarOpen ? 0 : -250,
              top: 0,
              bottom: 0,
              width: 250,
              child: _buildSidebar(database),
            ),
          ],
        ),
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => _createNewNote(context, selectedFolder),
              backgroundColor: AppColors.accentBlue,
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                color: AppColors.textPrimary,
              ),
            ),
    );
  }

  Widget _buildSidebar(AppDatabase database) {
    final selectedFolder = ref.watch(selectedFolderProvider);

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notes',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: _toggleSidebar,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Quick filters
          _buildSidebarItem(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedNote02,
              size: 20,
              color: AppColors.textSecondary,
            ),
            label: 'All Notes',
            isSelected: selectedFolder == null,
            onTap: () {
              ref.read(selectedFolderProvider.notifier).state = null;
            },
          ),
          _buildSidebarItem(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedPin,
              size: 20,
              color: AppColors.textSecondary,
            ),
            label: 'Pinned',
            isSelected: selectedFolder == 'pinned',
            onTap: () {
              ref.read(selectedFolderProvider.notifier).state =
                  'pinned'; // Special: pinned
            },
          ),
          _buildSidebarItem(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedChart01,
              size: 20,
              color: AppColors.textSecondary,
            ),
            label: 'Favorites',
            isSelected: selectedFolder == 'favorites',
            onTap: () {
              ref.read(selectedFolderProvider.notifier).state =
                  'favorites'; // Special: favorites
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'FOLDERS',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Folders list
          Expanded(
            child: StreamBuilder<List<NoteFolder>>(
              stream: database.watchNoteFolders(),
              builder: (context, snapshot) {
                final folders = snapshot.data ?? [];
                return _buildFolderTree(folders);
              },
            ),
          ),

          // Add folder button
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton.icon(
              onPressed: () => _showAddFolderDialog(context, database),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedHdd,
                size: 16,
                color: AppColors.accentBlue,
              ),
              label: const Text(
                'New Folder',
                style: TextStyle(color: AppColors.accentBlue, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required Widget icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        onTap();
        _toggleSidebar(); // Close sidebar after selection
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isSelected ? AppColors.elevatedSurface : Colors.transparent,
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build hierarchical folder tree
  Widget _buildFolderTree(List<NoteFolder> allFolders) {
    // Organize folders by parent
    final Map<String?, List<NoteFolder>> foldersByParent = {};
    for (final folder in allFolders) {
      foldersByParent.putIfAbsent(folder.parentUuid, () => []).add(folder);
    }

    // Build tree starting from root folders (parentUuid == null)
    final rootFolders = foldersByParent[null] ?? [];

    return ListView(
      children: rootFolders
          .map((folder) => _buildFolderTreeItem(folder, foldersByParent, 0))
          .toList(),
    );
  }

  Widget _buildFolderTreeItem(
    NoteFolder folder,
    Map<String?, List<NoteFolder>> foldersByParent,
    int depth,
  ) {
    final selectedFolder = ref.watch(selectedFolderProvider);
    final isSelected = selectedFolder == folder.uuid;
    final hasChildren = foldersByParent[folder.uuid]?.isNotEmpty ?? false;
    final isExpanded = _expandedFolderIds.contains(folder.uuid);
    final children = foldersByParent[folder.uuid] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            ref.read(selectedFolderProvider.notifier).state = folder.uuid;
            _toggleSidebar(); // Close sidebar after selection
          },
          onLongPress: () => _showFolderContextMenu(context, folder),
          child: Container(
            padding: EdgeInsets.only(
              left: 16.0 + (depth * 20.0),
              right: 16,
              top: 10,
              bottom: 10,
            ),
            color: isSelected ? AppColors.elevatedSurface : Colors.transparent,
            child: Row(
              children: [
                if (hasChildren)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedFolderIds.remove(folder.uuid);
                        } else {
                          _expandedFolderIds.add(folder.uuid);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: HugeIcon(
                        icon: isExpanded
                            ? HugeIcons.strokeRoundedArrowDown01
                            : HugeIcons.strokeRoundedArrowRight01,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 20),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedFolder01,
                  size: 20,
                  color: Color(int.parse('FF${folder.color}', radix: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    folder.name,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasChildren && isExpanded)
          ...children.map(
            (child) => _buildFolderTreeItem(child, foldersByParent, depth + 1),
          ),
      ],
    );
  }

  void _showFolderContextMenu(BuildContext context, NoteFolder folder) {
    final database = ref.read(databaseProvider);
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          folder.name,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedFolderAdd,
                size: 20,
                color: AppColors.accentBlue,
              ),
              title: const Text(
                'New Subfolder',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showAddFolderDialog(context, database, parentFolder: folder);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedDelete02,
                size: 20,
                color: Colors.red,
              ),
              title: const Text(
                'Delete Folder',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await _deleteFolder(context, database, folder);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFolder(
    BuildContext context,
    AppDatabase database,
    NoteFolder folder,
  ) async {
    // Check if folder has subfolders
    final allFolders = await database.allNoteFolders;
    final subfolders = allFolders
        .where((f) => f.parentUuid == folder.uuid)
        .toList();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Folder',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: Text(
          subfolders.isNotEmpty
              ? 'Are you sure you want to delete "${folder.name}" and its ${subfolders.length} subfolder${subfolders.length > 1 ? 's' : ''}? All notes in these folders will be permanently deleted.'
              : 'Are you sure you want to delete "${folder.name}"? All notes in this folder will be permanently deleted.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete all subfolders recursively first
      await _deleteSubfoldersRecursively(database, folder.uuid);
      // Delete all notes in this folder
      final notesInFolder = await database.getNotesByFolder(folder.uuid);
      for (final note in notesInFolder) {
        await database.deleteNote(note.id);
      }
      // Then delete the folder itself
      await database.deleteNoteFolder(folder.id);
    }
  }

  Future<void> _deleteSubfoldersRecursively(
    AppDatabase database,
    String? parentFolderUuid,
  ) async {
    final allFolders = await database.allNoteFolders;
    final subfolders = allFolders
        .where((f) => f.parentUuid == parentFolderUuid)
        .toList();

    for (final subfolder in subfolders) {
      // Recursively delete subfolders of this subfolder
      await _deleteSubfoldersRecursively(database, subfolder.uuid);
      // Delete all notes in this subfolder
      final notesInFolder = await database.getNotesByFolder(subfolder.uuid);
      for (final note in notesInFolder) {
        await database.deleteNote(note.id);
      }
      // Delete this subfolder
      await database.deleteNoteFolder(subfolder.id);
    }
  }

  Widget _buildMainContent(AppDatabase database, String? selectedFolder) {
    return Column(
      children: [
        // Header with menu button and search bar
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Menu button to toggle sidebar or cancel selection
              if (!_isSelectionMode)
                IconButton(
                  onPressed: _toggleSidebar,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedMenu01,
                    color: AppColors.textPrimary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                IconButton(
                  onPressed: _toggleSelectionMode,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    color: AppColors.textPrimary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 12),

              // Search bar or selection counter
              Expanded(
                child: _isSelectionMode
                    ? Text(
                        '${_selectedNoteIds.length} selected',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search notes...',
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.accentBlue,
                              width: 1,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
              ),
              if (_isSelectionMode) ...[
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => _deleteSelectedNotes(database),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    color: Colors.red,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ] else ...[
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _toggleSelectionMode,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedTick02,
                    color: AppColors.textPrimary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),

        // Notes grid
        Expanded(child: _buildNotesList(database, selectedFolder)),
      ],
    );
  }

  Widget _buildNotesList(AppDatabase database, String? selectedFolder) {
    final source = _getNotesSource(database, selectedFolder, _searchQuery);
    return _notesGridDataLoader(source: source, database: database);
  }

  // Helper to determine the data source (Future or Stream)
  Object _getNotesSource(AppDatabase database, String? folder, String query) {
    if (query.isNotEmpty) {
      return database.searchNotes(query);
    }
    if (folder == 'pinned') {
      // Pinned
      return database.getPinnedNotes();
    }
    if (folder == 'favorites') {
      // Favorites
      return database.getFavoriteNotes();
    }
    return database.watchNotesByFolder(folder);
  }

  // This widget takes a Future<List<Note>> or Stream<List<Note>>
  // and builds the final grid.
  Widget _notesGridDataLoader({
    required Object source,
    required AppDatabase database,
  }) {
    if (source is Stream<List<Note>>) {
      return StreamBuilder<List<Note>>(
        stream: source,
        builder: (context, snapshot) {
          final notes = snapshot.data ?? [];
          return _buildNotesGrid(notes);
        },
      );
    } else if (source is Future<List<Note>>) {
      return FutureBuilder<List<Note>>(
        future: source,
        builder: (context, snapshot) {
          final notes = snapshot.data ?? [];
          // Avoid showing loading while the future is still running
          if (snapshot.connectionState != ConnectionState.done &&
              notes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildNotesGrid(notes);
        },
      );
    }
    return Container(); // Should not happen
  }

  Widget _buildNotesGrid(List<Note> notes) {
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedNote02,
              size: 64,
              color: AppColors.gray500,
            ),
            const SizedBox(height: 20),
            Text(
              'No notes yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create your first note!',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    final isSelected = _selectedNoteIds.contains(note.id);
    final database = ref.watch(databaseProvider);

    return InkWell(
      onTap: () {
        if (_isSelectionMode) {
          _toggleNoteSelection(note.id);
        } else {
          _editNote(context, note);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedNoteIds.add(note.id);
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentBlue.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : AppColors.border,
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_isSelectionMode)
                    HugeIcon(
                      icon: isSelected
                          ? HugeIcons.strokeRoundedCheckmarkCircle02
                          : HugeIcons.strokeRoundedCircle,
                      color: isSelected
                          ? AppColors.accentBlue
                          : AppColors.textMuted,
                      size: 24,
                    )
                  else
                    Expanded(
                      child: Text(
                        note.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (!_isSelectionMode)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Task badge
                        FutureBuilder<int>(
                          future: database.getLinkedTodosCount(note.uuid),
                          builder: (context, snapshot) {
                            final todoCount = snapshot.data ?? 0;
                            if (todoCount == 0) return const SizedBox.shrink();

                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentBlue.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.accentBlue,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const HugeIcon(
                                      icon: HugeIcons.strokeRoundedTask01,
                                      size: 12,
                                      color: AppColors.accentBlue,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$todoCount',
                                      style: const TextStyle(
                                        color: AppColors.accentBlue,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (note.isPinned)
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedPin,
                            size: 16,
                            color: AppColors.accentBlue,
                          ),
                        if (note.isFavorite)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedChart01,
                              size: 16,
                              color: AppColors.error,
                            ),
                          ),
                      ],
                    ),
                  if (_isSelectionMode)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          note.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content preview
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _getPlainTextPreview(note.content),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: Text(
                _formatDate(note.updatedAt ?? note.createdAt),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPlainTextPreview(String jsonContent) {
    try {
      // Parse the Quill Delta JSON format
      final decoded = json.decode(jsonContent);
      final StringBuffer textBuffer = StringBuffer();

      if (decoded is List) {
        for (final op in decoded) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];
            if (insert is String) {
              textBuffer.write(insert);
            }
          }
        }
      }

      // Clean up the text
      String text = textBuffer
          .toString()
          .replaceAll('\n', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (text.isEmpty) {
        return 'No content';
      }

      if (text.length > 200) {
        return '${text.substring(0, 200)}...';
      }
      return text;
    } catch (e) {
      return '';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _createNewNote(BuildContext context, String? folderUuid) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(folderUuid: folderUuid),
      ),
    );
  }

  void _editNote(BuildContext context, Note note) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => NoteEditorPage(note: note)));
  }

  void _showAddFolderDialog(
    BuildContext context,
    AppDatabase database, {
    NoteFolder? parentFolder,
  }) {
    final nameController = TextEditingController();
    String selectedColor = '00ADEF';

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          parentFolder != null
              ? 'New Subfolder in ${parentFolder.name}'
              : 'New Folder',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Folder name',
                hintStyle: TextStyle(color: AppColors.textMuted),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accentBlue),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await database.insertNoteFolder(
                  NoteFoldersCompanion.insert(
                    name: nameController.text.trim(),
                    color: drift.Value(selectedColor),
                    parentUuid: drift.Value(parentFolder?.uuid),
                  ),
                );
                if (context.mounted) Navigator.of(context).pop();
                // Expand parent folder if creating a subfolder
                if (parentFolder != null) {
                  setState(() {
                    _expandedFolderIds.add(parentFolder.uuid);
                  });
                }
              }
            },
            child: const Text(
              'Create',
              style: TextStyle(color: AppColors.accentBlue),
            ),
          ),
        ],
      ),
    );
  }
}
