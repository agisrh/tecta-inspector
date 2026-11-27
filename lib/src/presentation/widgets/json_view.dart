import 'dart:convert';

import 'package:flutter/material.dart';

/// The text of a body, indented when it is JSON.
///
/// A map or list is encoded; a string that holds JSON is parsed and encoded
/// again; anything else is shown as it is.
String prettyBody(Object? value) {
  const encoder = JsonEncoder.withIndent('  ');
  if (value == null) return '';
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        return encoder.convert(jsonDecode(trimmed));
      } catch (_) {
        return value;
      }
    }
    return value;
  }
  try {
    return encoder.convert(value);
  } catch (_) {
    return value.toString();
  }
}

/// The colours of the parts of a JSON text.
class JsonColors {
  const JsonColors({
    required this.key,
    required this.string,
    required this.number,
    required this.keyword,
    required this.plain,
  });

  const JsonColors.dark()
      : key = const Color(0xFF82AAFF),
        string = const Color(0xFFC3E88D),
        number = const Color(0xFFF78C6C),
        keyword = const Color(0xFFC792EA),
        plain = const Color(0xFFE0E0E0);

  const JsonColors.light()
      : key = const Color(0xFF1B5FAA),
        string = const Color(0xFF1B5E20),
        number = const Color(0xFF9A4A00),
        keyword = const Color(0xFF7B1FA2),
        plain = const Color(0xFF111827);

  final Color key;
  final Color string;
  final Color number;
  final Color keyword;
  final Color plain;
}

// A string (and the colon after it when it is a key), a keyword, or a number.
final RegExp _jsonToken = RegExp(
  r'("(?:[^"\\]|\\.)*")(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?',
);

/// Splits [text] into coloured spans: keys, strings, numbers and keywords.
List<TextSpan> highlightJson(String text, JsonColors colors) {
  final spans = <TextSpan>[];
  var cursor = 0;
  for (final match in _jsonToken.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, match.start)));
    }
    final Color color;
    if (match.group(1) != null) {
      color = match.group(2) != null ? colors.key : colors.string;
    } else if (match.group(3) != null) {
      color = colors.keyword;
    } else {
      color = colors.number;
    }
    if (match.group(2) != null) {
      // The colon after a key is not part of the key.
      spans.add(TextSpan(text: match.group(1), style: TextStyle(color: color)));
      spans.add(TextSpan(text: match.group(2)));
    } else {
      spans.add(TextSpan(text: match[0], style: TextStyle(color: color)));
    }
    cursor = match.end;
  }
  if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
  return spans;
}

/// A body in monospace with JSON colours. A long body shows its first
/// [maxLines] lines and a button to show the rest.
class JsonView extends StatefulWidget {
  const JsonView(
      {super.key,
      required this.text,
      required this.isDarkMode,
      this.maxLines = 40});

  final String text;
  final bool isDarkMode;
  final int maxLines;

  @override
  State<JsonView> createState() => _JsonViewState();
}

class _JsonViewState extends State<JsonView> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final colors =
        widget.isDarkMode ? const JsonColors.dark() : const JsonColors.light();
    final lines = widget.text.split('\n');
    final truncated = !_showAll && lines.length > widget.maxLines;
    final shown =
        truncated ? lines.take(widget.maxLines).join('\n') : widget.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText.rich(
          TextSpan(
            style: TextStyle(
                fontFamily: 'monospace', fontSize: 12, color: colors.plain),
            children: highlightJson(shown, colors),
          ),
        ),
        if (lines.length > widget.maxLines)
          TextButton(
            onPressed: () => setState(() => _showAll = !_showAll),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
                truncated ? 'Show all ${lines.length} lines' : 'Show less'),
          ),
      ],
    );
  }
}
