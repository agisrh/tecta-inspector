import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecta_inspector/src/masking_util.dart';
import 'package:tecta_inspector/src/presentation/tecta_inspector_dashboard.dart';
import 'package:tecta_inspector/tecta_inspector.dart';

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: TcInspectorDashboard()));
  await tester.pump();
  await tester.pump();
}

void main() {
  tearDown(() {
    TcInspector.initialize();
    MaskingUtil.maskedKeys = [...MaskingUtil.defaultMaskedKeys];
    MaskingUtil.unmaskedKeys = [];
  });

  group('TcInspector.setMaskingEnabled', () {
    test('is ignored unless unmasking was allowed', () {
      TcInspector.initialize(enabled: true, allowUnmasking: false);

      TcInspector.setMaskingEnabled(false);

      expect(TcInspector.maskingEnabled, isTrue);
      expect(MaskingUtil.enabled, isTrue);
    });

    test('switches masking off and on when allowed', () {
      TcInspector.initialize(enabled: true, allowUnmasking: true);

      TcInspector.setMaskingEnabled(false);
      expect(TcInspector.maskingEnabled, isFalse);
      expect(MaskingUtil.enabled, isFalse);

      TcInspector.setMaskingEnabled(true);
      expect(TcInspector.maskingEnabled, isTrue);
      expect(MaskingUtil.enabled, isTrue);
    });

    test('initialize always starts with masking on', () {
      TcInspector.initialize(enabled: true, allowUnmasking: true);
      TcInspector.setMaskingEnabled(false);

      TcInspector.initialize(enabled: true, allowUnmasking: true);

      expect(TcInspector.maskingEnabled, isTrue);
    });

    test('initialize sets the names that are never masked', () {
      TcInspector.initialize(enabled: true, unmaskedKeys: ['sort_key']);

      expect(MaskingUtil.unmaskedKeys, ['sort_key']);
      expect(MaskingUtil.isMaskedKey('sortKey'), isFalse);
    });

    test('is allowed by default outside release mode', () {
      TcInspector.initialize(enabled: true);

      expect(TcInspector.allowUnmasking, isTrue);
    });
  });

  group('the dashboard', () {
    setUp(() {
      TcInspector.clearLogs();
    });

    testWidgets('has no unmask button when unmasking is not allowed',
        (tester) async {
      TcInspector.initialize(enabled: true, allowUnmasking: false);
      await _open(tester);

      expect(find.byTooltip('Show real values'), findsNothing);
    });

    testWidgets('switches masking off after a confirmation and shows a warning',
        (tester) async {
      TcInspector.initialize(enabled: true, allowUnmasking: true);
      await _open(tester);
      expect(find.textContaining('Masking is off'), findsNothing);

      await tester.tap(find.byTooltip('Show real values'));
      await tester.pump();
      // A confirmation first: nothing changes until the user agrees.
      expect(TcInspector.maskingEnabled, isTrue);

      await tester.tap(find.text('Show real values').last);
      await tester.pump();
      await tester.pump();

      expect(TcInspector.maskingEnabled, isFalse);
      expect(find.textContaining('Masking is off'), findsOneWidget);
    });

    testWidgets('cancelling the confirmation keeps masking on', (tester) async {
      TcInspector.initialize(enabled: true, allowUnmasking: true);
      await _open(tester);

      await tester.tap(find.byTooltip('Show real values'));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(TcInspector.maskingEnabled, isTrue);
    });

    testWidgets('turns masking back on without asking', (tester) async {
      TcInspector.initialize(enabled: true, allowUnmasking: true);
      TcInspector.setMaskingEnabled(false);
      await _open(tester);

      await tester.tap(find.byTooltip('Mask sensitive values'));
      await tester.pump();
      await tester.pump();

      expect(TcInspector.maskingEnabled, isTrue);
      expect(find.textContaining('Masking is off'), findsNothing);
    });
  });
}
