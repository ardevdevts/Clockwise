import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';

import '../../core/theme/colors.dart';
import '../../database/crud.dart';
import 'file_notes_models.dart';
import 'notes_providers.dart';
import 'super_editor_markdown_adapter.dart';

class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({
    super.key,
    this.workspace,
    this.node,
    this.note,
    this.folderUuid,
  });

  final NoteWorkspace? workspace;
  final NoteFileNode? node;

  // Legacy compatibility path for callers not yet migrated to file-first notes.
  final Note? note;
  final String? folderUuid;

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage>
    with WidgetsBindingObserver {
  final _adapter = SuperEditorMarkdownAdapter();

  late final ValueNotifier<bool> _isPinnedNotifier;
  late final ValueNotifier<bool> _isFavoriteNotifier;
  late final ValueNotifier<List<String>> _tagsNotifier;

  MutableDocument? _document;
  MutableDocumentComposer? _composer;
  dynamic _editor;

  bool _isLoading = true;
  bool _isDirty = false;
  bool _isSaving = false;
  String? _loadError;
  DateTime? _lastKnownDiskWrite;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isPinnedNotifier = ValueNotifier(false);
    _isFavoriteNotifier = ValueNotifier(false);
    _tagsNotifier = ValueNotifier(const []);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isPinnedNotifier.dispose();
    _isFavoriteNotifier.dispose();
    _tagsNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveSilently();
    }
  }

  Future<void> _load() async {
    final workspace = widget.workspace;
    final node = widget.node;

    if (workspace == null || node == null) {
      if (widget.note != null) {
        _loadLegacyNote();
      } else {
        setState(() {
          _isLoading = false;
          _loadError = 'Missing file context for note editor.';
        });
      }
      return;
    }

    try {
      final repository = ref.read(fileNotesRepositoryProvider);
      final markdown = await repository.readNote(workspace, node);
      final metadata = await repository.readMetadata(workspace, node);

      _document = _adapter.markdownToDocument(markdown);
      _composer = MutableDocumentComposer();
      _editor = createDefaultDocumentEditor(
        document: _document!,
        composer: _composer!,
      );

      _isPinnedNotifier.value = metadata.isPinned;
      _isFavoriteNotifier.value = metadata.isFavorite;
      _tagsNotifier.value = metadata.tags;
      _lastKnownDiskWrite = node.lastModified;

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load markdown file: $error';
      });
    }
  }

  void _loadLegacyNote() {
    final note = widget.note;
    final content = note?.content ?? '';

    _document = _adapter.markdownToDocument(content);
    _composer = MutableDocumentComposer();
    _editor = createDefaultDocumentEditor(
      document: _document!,
      composer: _composer!,
    );
    _isPinnedNotifier.value = note?.isPinned ?? false;
    _isFavoriteNotifier.value = note?.isFavorite ?? false;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSilently() async {
    try {
      await _save(showSnackbar: false);
    } catch (_) {
      // Best effort auto-save.
    }
  }

  Future<void> _save({bool showSnackbar = true}) async {
    if (_isSaving) return;
    final workspace = widget.workspace;
    final node = widget.node;

    if (workspace == null || node == null || _document == null) {
      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Legacy note editing is read-only in file-first mode.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final repository = ref.read(fileNotesRepositoryProvider);
    final markdown = _adapter.documentToMarkdown(_document!);

    await repository.saveNote(workspace, node, markdown);

    final previous = await repository.readMetadata(workspace, node);
    await repository.writeMetadata(
      workspace,
      node,
      previous.copyWith(
        isPinned: _isPinnedNotifier.value,
        isFavorite: _isFavoriteNotifier.value,
        tags: _tagsNotifier.value,
        updatedAt: DateTime.now(),
      ),
    );

    setState(() {
      _isSaving = false;
      _isDirty = false;
    });

    if (showSnackbar && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved'),
          duration: Duration(milliseconds: 1200),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _checkExternalChanges() async {
    final workspace = widget.workspace;
    final node = widget.node;
    if (workspace == null || node == null) return;

    final repository = ref.read(fileNotesRepositoryProvider);
    final info = await repository.findNodeByRelativePath(
      workspace: workspace,
      relativePath: node.relativePath,
    );

    if (info == null || info.lastModified == null) return;
    if (_lastKnownDiskWrite == null || !info.lastModified!.isAfter(_lastKnownDiskWrite!)) {
      return;
    }

    _lastKnownDiskWrite = info.lastModified;

    if (!_isDirty) {
      await _reloadFromDisk();
      return;
    }

    if (!mounted) return;
    final reload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('File changed on disk', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This note was modified outside the editor. Reload the file or keep your in-memory changes?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Mine', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reload', style: TextStyle(color: AppColors.accentBlue)),
          ),
        ],
      ),
    );

    if (reload == true) {
      await _reloadFromDisk();
    }
  }

  Future<void> _reloadFromDisk() async {
    final workspace = widget.workspace;
    final node = widget.node;
    if (workspace == null || node == null) return;

    final repository = ref.read(fileNotesRepositoryProvider);
    final markdown = await repository.readNote(workspace, node);

    setState(() {
      _document = _adapter.markdownToDocument(markdown);
      _composer = MutableDocumentComposer();
      _editor = createDefaultDocumentEditor(document: _document!, composer: _composer!);
      _isDirty = false;
    });
  }

  Future<void> _editTags() async {
    final controller = TextEditingController(text: _tagsNotifier.value.join(', '));

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Tags', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'comma, separated, tags',
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final tags = controller.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .toList();
              Navigator.of(context).pop(tags);
            },
            child: const Text('Apply', style: TextStyle(color: AppColors.accentBlue)),
          ),
        ],
      ),
    );

    if (result != null) {
      _tagsNotifier.value = result;
      _isDirty = true;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.textMuted)),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _loadError!,
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final node = widget.node;
    final title = node?.name ?? widget.note?.title ?? 'Note';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () async {
            await _saveSilently();
            if (mounted) Navigator.of(context).pop();
          },
        ),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _isPinnedNotifier,
            builder: (context, pinned, _) => IconButton(
              onPressed: () {
                _isPinnedNotifier.value = !pinned;
                _isDirty = true;
              },
              icon: Icon(
                pinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: pinned ? AppColors.accentBlue : AppColors.textSecondary,
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _isFavoriteNotifier,
            builder: (context, favorite, _) => IconButton(
              onPressed: () {
                _isFavoriteNotifier.value = !favorite;
                _isDirty = true;
              },
              icon: Icon(
                favorite ? Icons.favorite : Icons.favorite_outline,
                color: favorite ? AppColors.error : AppColors.textSecondary,
              ),
            ),
          ),
          IconButton(
            onPressed: _editTags,
            icon: const Icon(Icons.label_outline, color: AppColors.textSecondary),
          ),
          IconButton(
            onPressed: _checkExternalChanges,
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            tooltip: 'Check external changes',
          ),
          IconButton(
            onPressed: _isSaving
                ? null
                : () async {
                    await _save();
                  },
            icon: Icon(
              _isSaving ? Icons.sync : Icons.check,
              color: AppColors.accentBlue,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          ValueListenableBuilder<List<String>>(
            valueListenable: _tagsNotifier,
            builder: (context, tags, _) {
              if (tags.isEmpty) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(color: AppColors.accentBlue, fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
          Expanded(
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _editor == null
                  ? const SizedBox.shrink()
                  : SuperEditor(
                      editor: _editor,
                      composer: _composer!,
                      stylesheet: defaultStylesheet,
                      autofocus: true,
                      inputSource: TextInputSource.ime,
                      gestureMode: DocumentGestureMode.mouse,
                      componentBuilders: defaultComponentBuilders,
                      selectionStyle: const SelectionStyles(
                        selectionColor: Color(0x553A8DFF),
                      ),
                      onSelectionChange: (_) {
                        _isDirty = true;
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
