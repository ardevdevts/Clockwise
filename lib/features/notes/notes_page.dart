import 'package:drift/drift.dart' as drift;
import 'package:financialtracker/core/theme/colors.dart';
import 'package:financialtracker/database/crud.dart';
import 'package:financialtracker/features/notes/note_editor_page.dart';
import 'package:financialtracker/features/notes/notes_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../database/database_provider.dart';

// A data class to hold a note and its associated tags, preventing N+1 queries in the UI.
class NoteWithTags {
  final Note note;
  final List<Tag> tags;

  NoteWithTags({required this.note, required this.tags});
}

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSidebarOpen = false;

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

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final selectedFolder = ref.watch(selectedFolderProvider);
    final selectedTag = ref.watch(selectedTagProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            _buildMainContent(database, selectedFolder, selectedTag),
            
            // Sidebar overlay
            if (_isSidebarOpen)
              GestureDetector(
                onTap: _toggleSidebar,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewNote(context, selectedFolder),
        backgroundColor: AppColors.accentBlue,
        child: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.textPrimary),
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
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: AppColors.textSecondary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Quick filters
          _buildSidebarItem(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedNote02, size: 20, color: AppColors.textSecondary),
            label: 'All Notes',
            onTap: () {
              ref.read(selectedFolderProvider.notifier).state = null;
              ref.read(selectedTagProvider.notifier).state = null;
            },
          ),
          _buildSidebarItem(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedPin, size: 20, color: AppColors.textSecondary),
            label: 'Pinned',
            onTap: () {
              ref.read(selectedFolderProvider.notifier).state = -1; // Special: pinned
              ref.read(selectedTagProvider.notifier).state = null;
            },
          ),
          _buildSidebarItem(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedChart01, size: 20, color: AppColors.textSecondary),
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
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedHdd, size: 16, color: AppColors.accentBlue),
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        onTap();
        _toggleSidebar(); // Close sidebar after selection
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            icon,
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
        _toggleSidebar(); // Close sidebar after selection
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isSelected ? AppColors.elevatedSurface : Colors.transparent,
        child: Row(
          children: [
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
        // Header with menu button and search bar
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Menu button to toggle sidebar
              IconButton(
                onPressed: _toggleSidebar,
                icon: HugeIcon(icon: HugeIcons.strokeRoundedMenu01, color: AppColors.textPrimary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              
              // Search bar
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
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
            ],
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
    final source = _getNotesSource(database, selectedFolder, selectedTag, _searchQuery);
    return _NotesGridDataLoader(
      source: source,
      database: database,
    );
  }

  // Helper to determine the data source (Future or Stream)
  Object _getNotesSource(AppDatabase database, int? folder, int? tag, String query) {
    if (query.isNotEmpty) {
      return database.searchNotes(query);
    }
    if (tag != null) {
      return database.getNotesByTag(tag);
    }
    if (folder == -1) { // Pinned
      return database.getPinnedNotes();
    }
    if (folder == -2) { // Favorites
      return database.getFavoriteNotes();
    }
    return database.watchNotesByFolder(folder);
  }

  // This widget takes a Future<List<Note>> or Stream<List<Note>>,
  // fetches the tags for them, and builds the final grid.
  Widget _NotesGridDataLoader({required Object source, required AppDatabase database}) {
    if (source is Stream<List<Note>>) {
      return StreamBuilder<List<Note>>(
        stream: source,
        builder: (context, snapshot) {
          final notes = snapshot.data ?? [];
          return _buildGridWithFetchedTags(notes, database);
        },
      );
    } else if (source is Future<List<Note>>) {
      return FutureBuilder<List<Note>>(
        future: source,
        builder: (context, snapshot) {
          final notes = snapshot.data ?? [];
          // Avoid fetching tags while the future is still running
          if (snapshot.connectionState != ConnectionState.done && notes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildGridWithFetchedTags(notes, database);
        },
      );
    }
    return Container(); // Should not happen
  }

  // Helper widget to fetch tags in parallel and build the grid
  Widget _buildGridWithFetchedTags(List<Note> notes, AppDatabase database) {
    if (notes.isEmpty) {
      return _buildNotesGrid([]); // Return the empty state grid
    }

    // Fetch all tags for the list of notes in parallel.
    // This is still N queries, but Future.wait runs them concurrently,
    // which is a marginal improvement over sequential fetches in a list.
    final tagsFuture = Future.wait(
      notes.map((note) => database.getTagsForNote(note.id)),
    );

    return FutureBuilder<List<List<Tag>>>(
      future: tagsFuture,
      builder: (context, tagsSnapshot) {
        if (!tagsSnapshot.hasData) {
          // Show a loading state or the grid with no tags while they load
          return const Center(child: CircularProgressIndicator());
        }

        final allTags = tagsSnapshot.data!;
        final notesWithTags = List.generate(notes.length, (i) {
          return NoteWithTags(note: notes[i], tags: allTags[i]);
        });

        return _buildNotesGrid(notesWithTags);
      },
    );
  }

  Widget _buildNotesGrid(List<NoteWithTags> notesWithTags) {
    if (notesWithTags.isEmpty) {
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
      itemCount: notesWithTags.length,
      itemBuilder: (context, index) {
        final noteWithTags = notesWithTags[index];
        return _buildNoteCard(noteWithTags);
      },
    );
  }

  Widget _buildNoteCard(NoteWithTags noteWithTags) {
    final note = noteWithTags.note;
    final tags = noteWithTags.tags;

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
            if (tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(int.parse('FF${tag.color}', radix: 16))
                            .withOpacity(0.2),
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
              )
            else
              const SizedBox(height: 12),

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
      final text = jsonContent.replaceAll(RegExp(r'[{}\[\]"]'), '');
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
