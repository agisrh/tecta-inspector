import 'package:flutter/material.dart';

/// The text colours the dashboard uses on top of the log rows, chosen so that
/// each one has a contrast ratio of at least 4.5 on both row backgrounds of its
/// theme. Plain `Colors.grey` is too faint on white.
class InspectorColors {
  const InspectorColors._();

  /// The main text of an entry.
  static Color primaryText(bool dark) => dark ? const Color(0xFFE0E0E0) : const Color(0xFF111827);

  /// Times, labels and other supporting text.
  static Color secondaryText(bool dark) => dark ? Colors.grey : const Color(0xFF4B5563);

  /// The titles of the foldable sections.
  static Color sectionTitle(bool dark) => dark ? Colors.white70 : const Color(0xFF374151);
}
