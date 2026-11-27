import 'package:flutter/material.dart';

/// The colour of an HTTP status: green for 2xx, blue for 3xx, orange for 4xx
/// and red for 5xx or no response at all. The light theme gets deeper shades,
/// because the bright ones barely show on white.
Color statusColor(int? status, {bool dark = true}) {
  if (status == null || status >= 500)
    return dark ? Colors.redAccent : Colors.red.shade900;
  if (status >= 400) return dark ? Colors.orangeAccent : const Color(0xFF9A4A00);
  if (status >= 300)
    return dark ? Colors.lightBlueAccent : Colors.blue.shade900;
  if (status >= 200) return dark ? Colors.greenAccent : Colors.green.shade900;
  return dark ? Colors.grey : const Color(0xFF4B5563);
}

/// A text in which every match of [query] is highlighted.
class HighlightText extends StatelessWidget {
  const HighlightText(
      {super.key,
      required this.text,
      required this.query,
      required this.style});

  final String text;
  final String query;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: style);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var cursor = 0;
    while (true) {
      final start = lowerText.indexOf(lowerQuery, cursor);
      if (start < 0) break;
      if (start > cursor)
        spans.add(TextSpan(text: text.substring(cursor, start)));
      spans.add(TextSpan(
        text: text.substring(start, start + lowerQuery.length),
        style: const TextStyle(backgroundColor: Color(0x66FFC107)),
      ));
      cursor = start + lowerQuery.length;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
    return Text.rich(TextSpan(style: style, children: spans));
  }
}
