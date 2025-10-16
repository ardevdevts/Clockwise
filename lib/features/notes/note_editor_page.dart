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
  final int? folderId;

  const NoteEditorPage({super.key, this.note, this.folderId});

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  late QuillController _controller;
  late TextEditingController _titleController;
  final FocusNode _editorFocusNode = FocusNode();
  
  bool _isPinned = false;
  bool _isFavorite = false;
  int? _selectedFolderId;
  List<Tag> _selectedTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedFolderId = widget.note?.folderId ?? widget.folderId;
    _isPinned = widget.note?.isPinned ?? false;
    _isFavorite = widget.note?.isFavorite ?? false;
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
        _selectedTags = await database.getTagsForNote(widget.note!.id);
      } catch (e) {
        _controller = QuillController.basic();
      }
    } else {
      _controller = QuillController.basic();
    }
    
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _editorFocusNode.dispose();
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
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? AppColors.accentBlue : AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_outline,
              color: _isFavorite ? AppColors.error : AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          IconButton(
            icon: const Icon(Icons.content_paste, color: AppColors.textSecondary),
            onPressed: _pasteMarkdown,
            tooltip: 'Paste Markdown',
          ),
          IconButton(
            icon: const Icon(Icons.label_outline, color: AppColors.textSecondary),
            onPressed: _showTagsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.folder_outlined, color: AppColors.textSecondary),
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
          if (_selectedTags.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedTags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(int.parse('FF${tag.color}', radix: 16)).withValues(alpha: 0.2),
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
                            color: Color(int.parse('FF${tag.color}', radix: 16)),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedTags.remove(tag);
                            });
                          },
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Color(int.parse('FF${tag.color}', radix: 16)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // Toolbar
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: QuillSimpleToolbar(
              controller: _controller,
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
          ),

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
              content: Text('Pasted content is empty or could not be converted'),
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
        
        _controller.document.compose(
          insertDelta,
          ChangeSource.local,
        );
        
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
    final allTags = await database.allTags;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
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
                            final newTag = await database.insertTag(
                              TagsCompanion.insert(name: value.trim()),
                            );
                            final tag = await database.getTagById(newTag);
                            if (tag != null) {
                              setDialogState(() {
                                _selectedTags.add(tag);
                              });
                              setState(() {});
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Tags list
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: allTags.length,
                    itemBuilder: (context, index) {
                      final tag = allTags[index];
                      final isSelected = _selectedTags.any((t) => t.id == tag.id);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.removeWhere((t) => t.id == tag.id);
                            }
                          });
                          setState(() {});
                        },
                        title: Text(
                          tag.name,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        ),
                        activeColor: AppColors.accentBlue,
                        checkColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
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
              child: const Text('Done', style: TextStyle(color: AppColors.accentBlue)),
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderDialog() async {
    final database = ref.read(databaseProvider);
    final folders = await database.allNoteFolders;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Move to Folder',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.note_outlined, color: AppColors.textSecondary),
              title: const Text(
                'No Folder',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
              onTap: () {
                setState(() => _selectedFolderId = null);
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
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                ),
                onTap: () {
                  setState(() => _selectedFolderId = folder.id);
                  Navigator.of(context).pop();
                },
              );
            }),
          ],
        ),
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
            folderId: drift.Value(_selectedFolderId),
            isPinned: drift.Value(_isPinned),
            isFavorite: drift.Value(_isFavorite),
          ),
        );

        // Add tags
        for (final tag in _selectedTags) {
          await database.addTagToNote(noteId, tag.id);
        }
      } else {
        // Update existing note
        await database.updateNote(
          widget.note!.copyWith(
            title: _titleController.text.trim(),
            content: content,
            folderId: drift.Value(_selectedFolderId),
            isPinned: _isPinned,
            isFavorite: _isFavorite,
            updatedAt: drift.Value(DateTime.now()),
          ),
        );

        // Update tags
        await database.setNoteTags(
          widget.note!.id,
          _selectedTags.map((t) => t.id).toList(),
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
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
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
