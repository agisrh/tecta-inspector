import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecta_inspector/src/presentation/inspector_colors.dart';
import 'package:tecta_inspector/src/presentation/widgets/json_view.dart';
import 'package:tecta_inspector/src/presentation/widgets/log_chips.dart';

/// The WCAG contrast ratio of [fg] on [bg].
double contrast(Color fg, Color bg) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final a = luminance(fg);
  final b = luminance(bg);
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

void main() {
  // The backgrounds a log row and its opened panel can have, per theme.
  const lightBackgrounds = [
    Color(0xFFFFFFFF),
    Color(0xFFF2F4F7),
    Color(0xFFECEFF1)
  ];
  const darkBackgrounds = [
    Color(0xFF18181A),
    Color(0xFF222225),
    Color(0xFF101012)
  ];

  void expectReadable(Color color, List<Color> backgrounds, String what) {
    for (final background in backgrounds) {
      expect(contrast(color, background), greaterThanOrEqualTo(4.5),
          reason: '$what on $background');
    }
  }

  test('the text colours are readable in both themes', () {
    for (final dark in [true, false]) {
      final backgrounds = dark ? darkBackgrounds : lightBackgrounds;
      expectReadable(InspectorColors.primaryText(dark), backgrounds,
          'primary, dark=$dark');
      expectReadable(InspectorColors.secondaryText(dark), backgrounds,
          'secondary, dark=$dark');
      expectReadable(InspectorColors.sectionTitle(dark), backgrounds,
          'section title, dark=$dark');
    }
  });

  test('the JSON colours are readable in both themes', () {
    for (final (colors, backgrounds) in [
      (const JsonColors.dark(), darkBackgrounds),
      (const JsonColors.light(), lightBackgrounds),
    ]) {
      expectReadable(colors.key, backgrounds, 'key');
      expectReadable(colors.string, backgrounds, 'string');
      expectReadable(colors.number, backgrounds, 'number');
      expectReadable(colors.keyword, backgrounds, 'keyword');
      expectReadable(colors.plain, backgrounds, 'plain');
    }
  });

  test('the light status colours are readable on the light backgrounds', () {
    for (final status in [200, 302, 404, 500, null]) {
      expectReadable(
          statusColor(status, dark: false), lightBackgrounds, 'status $status');
    }
  });
}
