import 'package:flutter_test/flutter_test.dart';
import 'package:tecta_inspector/src/inspector_controller.dart';
import 'package:tecta_inspector/tecta_inspector.dart';

void main() {
  testWidgets('a log added while the app is idle is shown after one pump',
      (tester) async {
    TcInspector.initialize(enabled: true);
    TcInspector.clearLogs();

    TcInspector.log('hello');
    // No widget is on screen, so nothing else would ask for a frame.
    await tester.pump();

    expect(InspectorController.instance.logs.single.content, 'hello');
  });
}
