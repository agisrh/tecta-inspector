import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecta_inspector/src/presentation/widgets/json_view.dart';
import 'package:tecta_inspector/src/presentation/widgets/log_chips.dart';
import 'package:tecta_inspector/src/presentation/widgets/stack_trace_view.dart';

void main() {
  group('prettyBody', () {
    test('indents a map, a list and a string that holds JSON', () {
      expect(prettyBody({'a': 1}), '{\n  "a": 1\n}');
      expect(prettyBody([1]), '[\n  1\n]');
      expect(prettyBody('{"a":1}'), '{\n  "a": 1\n}');
    });

    test('keeps other text as it is and answers empty for null', () {
      expect(prettyBody('plain'), 'plain');
      expect(prettyBody('{broken'), '{broken');
      expect(prettyBody(null), '');
    });
  });

  group('highlightJson', () {
    const colors = JsonColors.dark();

    Color? colorOf(List<TextSpan> spans, String text) =>
        spans.firstWhere((s) => s.text == text).style?.color;

    test('colours keys, strings, numbers and keywords differently', () {
      final spans = highlightJson(
          '{"name": "demo", "age": 3, "ok": true, "x": null}', colors);

      expect(colorOf(spans, '"name"'), colors.key);
      expect(colorOf(spans, '"demo"'), colors.string);
      expect(colorOf(spans, '3'), colors.number);
      expect(colorOf(spans, 'true'), colors.keyword);
      expect(colorOf(spans, 'null'), colors.keyword);
    });

    test('does not colour a number that sits inside a string', () {
      final spans = highlightJson('{"id": "a123"}', colors);

      expect(spans.where((s) => s.text == '123'), isEmpty);
      expect(colorOf(spans, '"a123"'), colors.string);
    });

    test('keeps every character of the text', () {
      const text = '{\n  "a": [1, 2.5, -3e2],\n  "b": "x\\"y"\n}';

      expect(highlightJson(text, colors).map((s) => s.text).join(), text);
    });
  });

  group('isFrameworkFrame', () {
    test('tells the app from the framework', () {
      expect(
          isFrameworkFrame('#0 main (package:flutter/src/x.dart:1:1)'), isTrue);
      expect(
          isFrameworkFrame('#1 _rootRun (dart:async/zone.dart:1:1)'), isTrue);
      expect(
          isFrameworkFrame(
              '#2 LoginBloc.add (package:auth/src/login_bloc.dart:9:3)'),
          isFalse);
    });
  });

  group('statusColor', () {
    test('is green, blue, orange or red by range, and red without a response',
        () {
      expect(statusColor(200), Colors.greenAccent);
      expect(statusColor(302), Colors.lightBlueAccent);
      expect(statusColor(404), Colors.orangeAccent);
      expect(statusColor(500), Colors.redAccent);
      expect(statusColor(null), Colors.redAccent);
    });

    test('uses deeper shades on the light theme', () {
      expect(statusColor(200, dark: false), Colors.green.shade900);
      expect(statusColor(404, dark: false), const Color(0xFF9A4A00));
      expect(statusColor(500, dark: false), Colors.red.shade900);
    });
  });
}
