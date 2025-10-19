import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:markdown/markdown.dart' as md;
import '../../database/database_provider.dart';
import '../../database/crud.dart';
import '../../core/theme/colors.dart';
import 'package:drift/drift.dart' as drift;

class NoteEditorPage extends ConsumerStatefulWidget {
  final Note? note;
  final String? folderUuid;

  const NoteEditorPage({super.key, this.note, this.folderUuid});

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  late QuillController _controller;
  late TextEditingController _titleController;
  final FocusNode _editorFocusNode = FocusNode();

  late final ValueNotifier<bool> _isPinnedNotifier;
  late final ValueNotifier<bool> _isFavoriteNotifier;
  late final ValueNotifier<String?> _selectedFolderUuidNotifier;
  late final ValueNotifier<List<Tag>> _selectedTagsNotifier;
  bool _isLoading = true;

  // Cache for database queries
  List<Tag>? _cachedTags;
  List<NoteFolder>? _cachedFolders;

  @override
  void initState() {
    super.initState();
    _isPinnedNotifier = ValueNotifier(widget.note?.isPinned ?? false);
    _isFavoriteNotifier = ValueNotifier(widget.note?.isFavorite ?? false);
    _selectedFolderUuidNotifier = ValueNotifier(
      widget.note?.folderUuid ?? widget.folderUuid,
    );
    _selectedTagsNotifier = ValueNotifier([]);
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _initializeEditor();
  }

  Future<void> _initializeEditor() async {
    if (widget.note != null) {
      try {
        final doc = Document.fromJson(jsonDecode(widget.note!.content));
        _controller = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );

        // Load tags
        final database = ref.read(databaseProvider);
        _selectedTagsNotifier.value = await database.getTagsForNote(
          widget.note!.uuid,
        );
      } catch (e) {
        _controller = QuillController.basic();
      }
    } else {
      _controller = QuillController.basic();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _editorFocusNode.dispose();
    _isPinnedNotifier.dispose();
    _isFavoriteNotifier.dispose();
    _selectedFolderUuidNotifier.dispose();
    _selectedTagsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.note == null ? 'New Note' : 'Edit Note',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          _PinButton(notifier: _isPinnedNotifier),
          _FavoriteButton(notifier: _isFavoriteNotifier),
          IconButton(
            icon: const Icon(
              Icons.content_paste,
              color: AppColors.textSecondary,
            ),
            onPressed: _pasteMarkdown,
            tooltip: 'Paste Markdown',
          ),
          IconButton(
            icon: const Icon(
              Icons.label_outline,
              color: AppColors.textSecondary,
            ),
            onPressed: _showTagsDialog,
          ),
          IconButton(
            icon: const Icon(
              Icons.folder_outlined,
              color: AppColors.textSecondary,
            ),
            onPressed: _showFolderDialog,
          ),
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _deleteNote,
            ),
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.accentBlue),
            onPressed: _saveNote,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Title
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: TextField(
              controller: _titleController,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'Note title...',
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
              ),
            ),
          ),

          // Tags preview
          ValueListenableBuilder<List<Tag>>(
            valueListenable: _selectedTagsNotifier,
            builder: (context, selectedTags, _) {
              if (selectedTags.isEmpty) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 0.5),
                  ),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedTags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse('FF${tag.color}', radix: 16),
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Color(int.parse('FF${tag.color}', radix: 16)),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tag.name,
                            style: TextStyle(
                              color: Color(
                                int.parse('FF${tag.color}', radix: 16),
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              final updated = List<Tag>.from(selectedTags);
                              updated.remove(tag);
                              _selectedTagsNotifier.value = updated;
                            },
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Color(
                                int.parse('FF${tag.color}', radix: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          // Toolbar
          _EditorToolbar(controller: _controller),

          // Editor
          Expanded(
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(20),
              child: QuillEditor(
                controller: _controller,
                focusNode: _editorFocusNode,
                scrollController: ScrollController(),
                config: const QuillEditorConfig(
                  padding: EdgeInsets.zero,
                  placeholder: 'Start writing...',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pasteMarkdown() async {
    try {
      // Get clipboard content
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData?.text == null || clipboardData!.text!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clipboard is empty'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final markdown = clipboardData.text!;

      // Convert markdown to HTML first
      final html = md.markdownToHtml(markdown);

      // Convert HTML to Delta using flutter_quill_delta_from_html
      final delta = HtmlToDelta().convert(html);

      // Prevent crash if conversion results in an empty or invalid delta.
      // A delta is considered contentless if its plain text version is empty.
      if (delta.toString().trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Pasted content is empty or could not be converted',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Get current selection
      final selection = _controller.selection;
      final index = selection.baseOffset;

      // Insert the converted delta at cursor position
      if (index >= 0 && index < _controller.document.length) {
        // Create a new delta that retains content up to cursor, then inserts new content
        final insertDelta = Delta()
          ..retain(index)
          ..concat(delta);

        _controller.document.compose(insertDelta, ChangeSource.local);

        // Move cursor to end of inserted content
        final newPosition = index + delta.length;
        _controller.updateSelection(
          TextSelection.collapsed(offset: newPosition),
          ChangeSource.local,
        );
      } else {
        // If no valid selection, replace entire document
        _controller.document = Document.fromDelta(delta);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Markdown pasted and converted successfully'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error pasting markdown: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showTagsDialog() async {
    final database = ref.read(databaseProvider);

    // Cache tags if not already cached
    _cachedTags ??= await database.allTags;
    final allTags = _cachedTags!;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _TagsDialog(
        allTags: allTags,
        selectedTagsNotifier: _selectedTagsNotifier,
        database: database,
        onTagsUpdated: () {
          _cachedTags = null; // Invalidate cache
        },
      ),
    );
  }

  void _showFolderDialog() async {
    final database = ref.read(databaseProvider);

    // Cache folders if not already cached
    _cachedFolders ??= await database.allNoteFolders;
    final folders = _cachedFolders!;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _FolderDialog(
        folders: folders,
        selectedFolderUuidNotifier: _selectedFolderUuidNotifier,
      ),
    );
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final database = ref.read(databaseProvider);
    final content = jsonEncode(_controller.document.toDelta().toJson());

    try {
      if (widget.note == null) {
        // Create new note
        final noteId = await database.insertNote(
          NotesCompanion.insert(
            title: _titleController.text.trim(),
            content: content,
            folderUuid: drift.Value(_selectedFolderUuidNotifier.value),
            isPinned: drift.Value(_isPinnedNotifier.value),
            isFavorite: drift.Value(_isFavoriteNotifier.value),
          ),
        );

        // Get the newly created note to access its UUID
        final newNote = await database.getNoteById(noteId);

        // Add tags
        for (final tag in _selectedTagsNotifier.value) {
          await database.addTagToNote(newNote!.uuid, tag.uuid);
        }
      } else {
        // Update existing note
        await database.updateNote(
          widget.note!.copyWith(
            title: _titleController.text.trim(),
            content: content,
            folderUuid: drift.Value(_selectedFolderUuidNotifier.value),
            isPinned: _isPinnedNotifier.value,
            isFavorite: _isFavoriteNotifier.value,
            updatedAt: DateTime.now(),
          ),
        );

        // Update tags
        await database.setNoteTags(
          widget.note!.uuid,
          _selectedTagsNotifier.value.map((t) => t.uuid).toList(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote() async {
    if (widget.note == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Note',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: const Text(
          'Are you sure you want to delete this note? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final database = ref.read(databaseProvider);
      await database.deleteNote(widget.note!.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

// Optimized widgets to prevent unnecessary rebuilds
class _PinButton extends StatelessWidget {
  final ValueNotifier<bool> notifier;

  const _PinButton({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, isPinned, _) {
        return IconButton(
          icon: Icon(
            isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            color: isPinned ? AppColors.accentBlue : AppColors.textSecondary,
          ),
          onPressed: () => notifier.value = !notifier.value,
        );
      },
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final ValueNotifier<bool> notifier;

  const _FavoriteButton({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, isFavorite, _) {
        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_outline,
            color: isFavorite ? AppColors.error : AppColors.textSecondary,
          ),
          onPressed: () => notifier.value = !notifier.value,
        );
      },
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  final QuillController controller;

  const _EditorToolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: QuillSimpleToolbar(
        controller: controller,
        config: const QuillSimpleToolbarConfig(
          multiRowsDisplay: false,
          showAlignmentButtons: true,
          showBackgroundColorButton: false,
          showCenterAlignment: true,
          showCodeBlock: true,
          showColorButton: true,
          showDirection: false,
          showDividers: true,
          showFontFamily: false,
          showFontSize: false,
          showHeaderStyle: true,
          showIndent: true,
          showInlineCode: true,
          showJustifyAlignment: false,
          showLeftAlignment: true,
          showLink: true,
          showListBullets: true,
          showListCheck: true,
          showListNumbers: true,
          showQuote: true,
          showRedo: true,
          showRightAlignment: true,
          showSmallButton: false,
          showStrikeThrough: true,
          showUnderLineButton: true,
          showUndo: true,
        ),
      ),
    );
  }
}

class _TagsDialog extends StatefulWidget {
  final List<Tag> allTags;
  final ValueNotifier<List<Tag>> selectedTagsNotifier;
  final AppDatabase database;
  final VoidCallback onTagsUpdated;

  const _TagsDialog({
    required this.allTags,
    required this.selectedTagsNotifier,
    required this.database,
    required this.onTagsUpdated,
  });

  @override
  State<_TagsDialog> createState() => _TagsDialogState();
}

class _TagsDialogState extends State<_TagsDialog> {
  late List<Tag> _allTags;

  @override
  void initState() {
    super.initState();
    _allTags = List.from(widget.allTags);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Manage Tags',
        style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Create new tag
            TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'New tag name',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accentBlue),
                ),
              ),
              onSubmitted: (value) async {
                if (value.trim().isNotEmpty) {
                  final newTag = await widget.database.insertTag(
                    TagsCompanion.insert(name: value.trim()),
                  );
                  final tag = await widget.database.getTagById(newTag);
                  if (tag != null) {
                    setState(() {
                      _allTags.add(tag);
                    });
                    final updated = List<Tag>.from(
                      widget.selectedTagsNotifier.value,
                    );
                    updated.add(tag);
                    widget.selectedTagsNotifier.value = updated;
                    widget.onTagsUpdated();
                  }
                }
              },
            ),
            const SizedBox(height: 20),

            // Tags list
            Flexible(
              child: ValueListenableBuilder<List<Tag>>(
                valueListenable: widget.selectedTagsNotifier,
                builder: (context, selectedTags, _) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: _allTags.length,
                    itemBuilder: (context, index) {
                      final tag = _allTags[index];
                      final isSelected = selectedTags.any(
                        (t) => t.id == tag.id,
                      );

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          final updated = List<Tag>.from(selectedTags);
                          if (value == true) {
                            updated.add(tag);
                          } else {
                            updated.removeWhere((t) => t.id == tag.id);
                          }
                          widget.selectedTagsNotifier.value = updated;
                        },
                        title: Text(
                          tag.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        activeColor: AppColors.accentBlue,
                        checkColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Done',
            style: TextStyle(color: AppColors.accentBlue),
          ),
        ),
      ],
    );
  }
}

class _FolderDialog extends StatelessWidget {
  final List<NoteFolder> folders;
  final ValueNotifier<String?> selectedFolderUuidNotifier;

  const _FolderDialog({
    required this.folders,
    required this.selectedFolderUuidNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Move to Folder',
        style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.note_outlined,
              color: AppColors.textSecondary,
            ),
            title: const Text(
              'No Folder',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            onTap: () {
              selectedFolderUuidNotifier.value = null;
              Navigator.of(context).pop();
            },
          ),
          ...folders.map((folder) {
            return ListTile(
              leading: Icon(
                Icons.folder_outlined,
                color: Color(int.parse('FF${folder.color}', radix: 16)),
              ),
              title: Text(
                folder.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                selectedFolderUuidNotifier.value = folder.uuid;
                Navigator.of(context).pop();
              },
            );
          }),
        ],
      ),
    );
  }
}
