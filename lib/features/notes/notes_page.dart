import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database_provider.dart';
import '../../database/crud.dart';
import '../../core/theme/colors.dart';
import 'note_editor_page.dart';
import 'notes_providers.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final selectedFolder = ref.watch(selectedFolderProvider);
    final selectedTag = ref.watch(selectedTagProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar
            _buildSidebar(database),
            
            // Main content
            Expanded(
              child: _buildMainContent(database, selectedFolder, selectedTag),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewNote(context, selectedFolder),
        backgroundColor: AppColors.accentBlue,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildSidebar(AppDatabase database) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: const Text(
              'Notes',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Quick filters
          _buildSidebarItem(
            icon: Icons.note_outlined,
            label: 'All Notes',
            onTap: () {
              ref.read(selectedFolderProvider.notifier).state = null;
              ref.read(selectedTagProvider.notifier).state = null;
            },
          ),
          _buildSidebarItem(
            icon: Icons.push_pin_outlined,
            label: 'Pinned',
            onTap: () {
              ref.read(selectedFolderProvider.notifier).state = -1; // Special: pinned
              ref.read(selectedTagProvider.notifier).state = null;
            },
          ),
          _buildSidebarItem(
            icon: Icons.favorite_outline,
            label: 'Favorites',
            onTap: () {
              ref.read(selectedFolderProvider.notifier).state = -2; // Special: favorites
              ref.read(selectedTagProvider.notifier).state = null;
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
                return ListView.builder(
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return _buildFolderItem(folder);
                  },
                );
              },
            ),
          ),

          // Add folder button
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton.icon(
              onPressed: () => _showAddFolderDialog(context, database),
              icon: const Icon(Icons.add, size: 16, color: AppColors.accentBlue),
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
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderItem(NoteFolder folder) {
    final selectedFolder = ref.watch(selectedFolderProvider);
    final isSelected = selectedFolder == folder.id;

    return InkWell(
      onTap: () {
        ref.read(selectedFolderProvider.notifier).state = folder.id;
        ref.read(selectedTagProvider.notifier).state = null;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isSelected ? AppColors.elevatedSurface : Colors.transparent,
        child: Row(
          children: [
            Icon(
              Icons.folder_outlined,
              size: 20,
              color: Color(int.parse('FF${folder.color}', radix: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                folder.name,
                style: TextStyle(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(AppDatabase database, int? selectedFolder, int? selectedTag) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search notes...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.accentBlue, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        // Notes grid
        Expanded(
          child: _buildNotesList(database, selectedFolder, selectedTag),
        ),
      ],
    );
  }

  Widget _buildNotesList(AppDatabase database, int? selectedFolder, int? selectedTag) {
    if (_searchQuery.isNotEmpty) {
      return FutureBuilder<List<Note>>(
        future: database.searchNotes(_searchQuery),
        builder: (context, snapshot) {
          final notes = snapshot.data ?? [];
          return _buildNotesGrid(notes, database);
        },
      );
    }

    if (selectedTag != null) {
      return FutureBuilder<List<Note>>(
        future: database.getNotesByTag(selectedTag),
        builder: (context, snapshot) {
          final notes = snapshot.data ?? [];
          return _buildNotesGrid(notes, database);
        },
      );
    }

    if (selectedFolder == -1) {
      // Pinned notes
      return FutureBuilder<List<Note>>(
        future: database.getPinnedNotes(),
        builder: (context, snapshot) {
          final notes = snapshot.data ?? [];
          return _buildNotesGrid(notes, database);
        },
      );
    }

    if (selectedFolder == -2) {
      // Favorite notes
      return FutureBuilder<List<Note>>(
        future: database.getFavoriteNotes(),
        builder: (context, snapshot) {
          final notes = snapshot.data ?? [];
          return _buildNotesGrid(notes, database);
        },
      );
    }

    return StreamBuilder<List<Note>>(
      stream: database.watchNotesByFolder(selectedFolder),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];
        return _buildNotesGrid(notes, database);
      },
    );
  }

  Widget _buildNotesGrid(List<Note> notes, AppDatabase database) {
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_outlined,
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
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
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
        return _buildNoteCard(note, database);
      },
    );
  }

  Widget _buildNoteCard(Note note, AppDatabase database) {
    return InkWell(
      onTap: () => _editNote(context, note),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (note.isPinned)
                        const Icon(
                          Icons.push_pin,
                          size: 16,
                          color: AppColors.accentBlue,
                        ),
                      if (note.isFavorite)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.favorite,
                            size: 16,
                            color: AppColors.error,
                          ),
                        ),
                    ],
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

            // Tags
            FutureBuilder<List<Tag>>(
              future: database.getTagsForNote(note.id),
              builder: (context, snapshot) {
                final tags = snapshot.data ?? [];
                if (tags.isEmpty) return const SizedBox(height: 12);

                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(int.parse('FF${tag.color}', radix: 16)).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag.name,
                          style: TextStyle(
                            color: Color(int.parse('FF${tag.color}', radix: 16)),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
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
    // Simple extraction - in reality, you'd parse the Quill JSON
    try {
      return jsonContent.replaceAll(RegExp(r'[{}\[\]"]'), '').substring(0, 200);
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

  void _createNewNote(BuildContext context, int? folderId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(folderId: folderId),
      ),
    );
  }

  void _editNote(BuildContext context, Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(note: note),
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context, AppDatabase database) {
    final nameController = TextEditingController();
    String selectedColor = '00ADEF';

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'New Folder',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
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
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await database.insertNoteFolder(
                  NoteFoldersCompanion.insert(
                    name: nameController.text.trim(),
                    color: drift.Value(selectedColor),
                  ),
                );
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            child: const Text('Create', style: TextStyle(color: AppColors.accentBlue)),
          ),
        ],
      ),
    );
  }
}
