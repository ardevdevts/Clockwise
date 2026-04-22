import 'package:super_editor/super_editor.dart';
import 'package:uuid/uuid.dart';

class SuperEditorMarkdownAdapter {
  SuperEditorMarkdownAdapter();

  final _uuid = const Uuid();

  MutableDocument markdownToDocument(String markdown) {
    final normalized = markdown.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');

    final nodes = <DocumentNode>[];
    for (final line in lines) {
      nodes.add(_paragraphNode(line));
    }

    if (nodes.isEmpty) {
      nodes.add(_paragraphNode(''));
    }

    return MutableDocument(nodes: nodes);
  }

  String documentToMarkdown(MutableDocument document) {
    final buffer = StringBuffer();
    final nodes = document.nodes;
    for (var i = 0; i < nodes.length; i++) {
      final text = _nodeText(nodes[i]);
      buffer.writeln(text);
    }
    return buffer.toString().trimRight();
  }

  ParagraphNode _paragraphNode(String text) {
    return ParagraphNode(id: _uuid.v4(), text: AttributedText(text: text));
  }

  String _nodeText(Object node) {
    final dynamic dynamicNode = node;

    if (dynamicNode is ParagraphNode) {
      return _toPlainText(dynamicNode.text);
    }

    final dynamic textField = dynamicNode.text;
    if (textField != null) {
      return _toPlainText(textField);
    }

    return '';
  }

  String _toPlainText(dynamic text) {
    if (text == null) return '';
    if (text is String) return text;

    try {
      final plain = text.toPlainText();
      if (plain is String) return plain;
    } catch (_) {}

    try {
      final raw = text.text;
      if (raw is String) return raw;
    } catch (_) {}

    return text.toString();
  }
}
