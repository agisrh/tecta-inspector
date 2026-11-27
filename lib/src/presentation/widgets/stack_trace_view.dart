import 'package:flutter/material.dart';

/// Whether a stack trace line comes from the Dart SDK or from a common
/// framework package, as opposed to the app's own code.
bool isFrameworkFrame(String line) {
  // `dart:` as a library, not as the end of a file name such as `x.dart:9:3`.
  if (RegExp(r'(^|[\s(])dart:[a-z]').hasMatch(line)) return true;
  const markers = [
    'package:flutter/',
    'package:flutter_test/',
    'package:flutter_bloc/',
    'package:bloc/',
    'package:provider/',
    'package:go_router/',
    'package:dio/',
    'package:async/',
    'package:stack_trace/',
    'package:tecta_inspector/',
  ];
  return markers.any(line.contains);
}

/// A stack trace in which the app's own frames stand out and the framework's
/// frames are dimmed, so the line to open is easy to find.
class StackTraceView extends StatelessWidget {
  const StackTraceView(
      {super.key, required this.stackTrace, required this.isDarkMode});

  final String stackTrace;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final strong =
        isDarkMode ? const Color(0xFFFFCDCD) : const Color(0xFFC62828);
    final dim = strong.withValues(alpha: 0.45);

    return Container(
      constraints: const BoxConstraints(maxHeight: 240),
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A1C1C) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode
              ? Colors.redAccent.withValues(alpha: 0.15)
              : Colors.red.withValues(alpha: 0.1),
        ),
      ),
      child: SingleChildScrollView(
        child: SelectableText.rich(
          TextSpan(
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            children: [
              for (final line in stackTrace.split('\n'))
                TextSpan(
                  text: '$line\n',
                  style: TextStyle(
                    color: isFrameworkFrame(line) ? dim : strong,
                    fontWeight: isFrameworkFrame(line)
                        ? FontWeight.normal
                        : FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
