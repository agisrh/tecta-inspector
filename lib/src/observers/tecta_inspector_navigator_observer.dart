import 'package:flutter/material.dart';
import '../tecta_inspector_facade.dart';
import '../models/log_entry.dart';

class TcInspectorNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (!TcInspector.enabled) return;

    final routeName = route.settings.name ?? 'unnamed';
    final prevRouteName = previousRoute?.settings.name ?? 'none';

    TcInspector.addLogEntry(LogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: LogType.navigator,
      title: 'Navigator PUSH',
      content: 'PUSH to "$routeName" (from "$prevRouteName")',
      metadata: {
        'route': routeName,
        'previousRoute': prevRouteName,
        'arguments': route.settings.arguments,
      },
    ));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (!TcInspector.enabled) return;

    final routeName = route.settings.name ?? 'unnamed';
    final prevRouteName = previousRoute?.settings.name ?? 'none';

    TcInspector.addLogEntry(LogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: LogType.navigator,
      title: 'Navigator POP',
      content: 'POP from "$routeName" (back to "$prevRouteName")',
      metadata: {
        'route': routeName,
        'previousRoute': prevRouteName,
      },
    ));
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (!TcInspector.enabled) return;

    final newRouteName = newRoute?.settings.name ?? 'unnamed';
    final oldRouteName = oldRoute?.settings.name ?? 'unnamed';

    TcInspector.addLogEntry(LogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: LogType.navigator,
      title: 'Navigator REPLACE',
      content: 'REPLACE "$oldRouteName" with "$newRouteName"',
      metadata: {
        'newRoute': newRouteName,
        'oldRoute': oldRouteName,
        'arguments': newRoute?.settings.arguments,
      },
    ));
  }
}
