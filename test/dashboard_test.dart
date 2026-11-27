import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecta_inspector/src/presentation/tecta_inspector_dashboard.dart';
import 'package:tecta_inspector/src/presentation/widgets/errors_chip.dart';
import 'package:tecta_inspector/tecta_inspector.dart';

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: TcInspectorDashboard()));
  await tester.pump();
  await tester.pump();
}

void _addNetwork(
    {required String title, int status = 200, bool isError = false}) {
  TcInspector.addLogEntry(LogEntry(
    id: title,
    timestamp: DateTime(2026),
    type: LogType.network,
    title: title,
    content: 'content of $title',
    isError: isError,
    metadata: {
      'statusCode': status,
      'method': 'GET',
      'url': 'https://api.test/$title'
    },
  ));
}

void main() {
  setUp(() {
    TcInspector.initialize(enabled: true);
    TcInspector.clearLogs();
  });

  testWidgets('the app bar does not change when the list scrolls',
      (tester) async {
    for (var i = 0; i < 60; i++) {
      TcInspector.log('log $i');
    }
    await _open(tester);

    Material barMaterial() => tester.widget<Material>(
          find
              .descendant(
                  of: find.byType(AppBar), matching: find.byType(Material))
              .first,
        );
    final before = barMaterial();

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    final after = barMaterial();

    expect(after.color, before.color);
    expect(after.elevation, 0);
    expect(after.surfaceTintColor, Colors.transparent);
  });

  testWidgets('each tab shows how many entries it holds', (tester) async {
    TcInspector.log('one');
    TcInspector.log('two');
    _addNetwork(title: 'a');
    await _open(tester);

    // The title and the number are separate, so the number can sit in a badge.
    Finder badgeIn(String tab) => find.descendant(
          of: find.widgetWithText(Tab, tab),
          matching: find.byType(Container),
        );

    expect(find.descendant(of: badgeIn('All'), matching: find.text('3')),
        findsOneWidget);
    expect(find.descendant(of: badgeIn('Print'), matching: find.text('2')),
        findsOneWidget);
    expect(find.descendant(of: badgeIn('Network'), matching: find.text('1')),
        findsOneWidget);
    // An empty tab shows no badge.
    expect(badgeIn('Database'), findsNothing);
  });

  testWidgets('the Errors chip keeps only failures and shows their number',
      (tester) async {
    _addNetwork(title: 'ok');
    _addNetwork(title: 'bad', status: 500, isError: true);
    await _open(tester);

    final chip = find.byType(ErrorsChip);
    expect(find.descendant(of: chip, matching: find.text('1')), findsOneWidget);

    await tester.tap(chip);
    await tester.pump();

    expect(find.text('bad'), findsOneWidget);
    expect(find.text('ok'), findsNothing);
  });

  testWidgets('a network row ends its time line with the duration', (tester) async {
    TcInspector.addLogEntry(LogEntry(
      id: 'row',
      timestamp: DateTime(2026, 1, 1, 8, 5, 9, 42),
      type: LogType.network,
      title: 'POST /login - 401',
      content: 'content',
      metadata: {'method': 'POST', 'statusCode': 401, 'duration': 128, 'url': 'https://api.test/login'},
    ));
    await _open(tester);

    expect(find.text('08:05:09.042 • NETWORK • 128 ms'), findsOneWidget);
    // The title already says the method and the status: no second copy of them.
    expect(find.text('POST'), findsNothing);
    expect(find.text('401'), findsNothing);
  });

  testWidgets('an opened network log has foldable sections, headers closed',
      (tester) async {
    TcInspector.addLogEntry(LogEntry(
      id: 'n2',
      timestamp: DateTime(2026),
      type: LogType.network,
      title: 'GET /orders - 200',
      content: 'raw content',
      metadata: {
        'method': 'GET',
        'statusCode': 200,
        'duration': 10,
        'url': 'https://api.test/orders',
        'requestHeaders': {'Accept': 'application/json'},
        'responseBody': {'ok': true},
      },
    ));
    await _open(tester);
    await tester.tap(find.text('GET /orders - 200'));
    await tester.pump();

    expect(find.text('SUMMARY'), findsOneWidget);
    expect(find.text('RESPONSE BODY'), findsOneWidget);
    // Headers start folded.
    expect(find.text('REQUEST HEADERS'), findsOneWidget);
    expect(find.textContaining('Accept', findRichText: true), findsNothing);

    await tester.tap(find.text('REQUEST HEADERS'));
    await tester.pump();

    expect(find.textContaining('Accept', findRichText: true), findsOneWidget);
  });

  testWidgets('the search text is highlighted in the title', (tester) async {
    TcInspector.addLogEntry(LogEntry(
      id: 'h',
      timestamp: DateTime(2026),
      type: LogType.print,
      title: 'Hello world',
      content: 'c',
    ));
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'world');
    await tester.pump();

    final rich = tester.widget<RichText>(
      find.descendant(
          of: find.text('Hello world'), matching: find.byType(RichText)),
    );
    var found = false;
    rich.text.visitChildren((span) {
      if (span is TextSpan &&
          span.text == 'world' &&
          span.style?.backgroundColor != null) {
        found = true;
      }
      return true;
    });
    expect(found, isTrue);
  });

  testWidgets(
      'an empty search result says what was searched and can be cleared',
      (tester) async {
    TcInspector.log('hello');
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();

    expect(find.text('No logs match "zzz"'), findsOneWidget);

    await tester.tap(find.text('Clear search'));
    await tester.pump();

    // A print log is listed under the title "Console Print".
    expect(find.text('Console Print'), findsOneWidget);
  });

  testWidgets('says so when there are no logs at all', (tester) async {
    await _open(tester);

    expect(find.text('No logs yet'), findsOneWidget);
  });

  testWidgets('the search can also find what is only in the metadata',
      (tester) async {
    TcInspector.addLogEntry(LogEntry(
      id: 'db',
      timestamp: DateTime(2026),
      type: LogType.database,
      title: 'Database Query',
      content: 'SELECT 1',
      metadata: {'result': 'inventory-row'},
    ));
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'inventory');
    await tester.pump();

    expect(find.text('Database Query'), findsOneWidget);
  });

  testWidgets('the theme choice survives closing and reopening the dashboard',
      (tester) async {
    await _open(tester);
    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    await _open(tester);

    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

    // Put it back so later tests start dark.
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pump();
  });

  testWidgets('a network log offers three separate copy buttons',
      (tester) async {
    TcInspector.addLogEntry(LogEntry(
      id: 'n',
      timestamp: DateTime(2026),
      type: LogType.network,
      title: 'GET /orders - 200',
      content: 'content',
      metadata: {
        'statusCode': 200,
        'method': 'GET',
        'url': 'https://api.test/orders',
        'responseBody': {'ok': true},
      },
    ));
    await _open(tester);

    await tester.tap(find.text('GET /orders - 200'));
    await tester.pump();

    expect(find.byType(OutlinedButton), findsNWidgets(3));
    expect(find.text('Copy Log'), findsOneWidget);
    expect(find.text('Copy cURL'), findsOneWidget);
    expect(find.text('Copy Response'), findsOneWidget);
  });
}
