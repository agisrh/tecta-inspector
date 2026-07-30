import 'package:flutter/material.dart';
import '../tecta_inspector_facade.dart';
import 'tecta_inspector_dashboard.dart';

class TectaInspectorOverlay extends StatefulWidget {
  final Widget child;

  const TectaInspectorOverlay({super.key, required this.child});

  @override
  State<TectaInspectorOverlay> createState() => _TectaInspectorOverlayState();
}

class _TectaInspectorOverlayState extends State<TectaInspectorOverlay> {
  Offset _position = const Offset(-1, -1); // Uninitialized indicator
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final padding = mediaQuery.padding;

    // Initialize initial position to bottom-right of the screen
    if (_position.dx == -1 && _position.dy == -1) {
      _position = Offset(
        size.width - 70,
        size.height - padding.bottom - 120,
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          ValueListenableBuilder<bool>(
            valueListenable: TectaInspector.enabledNotifier,
            builder: (context, enabled, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: TectaInspector.isDashboardOpen,
                builder: (context, isDashboardOpen, _) {
                  if (!enabled || isDashboardOpen) return const SizedBox.shrink();
                  return Positioned(
                    left: _position.dx,
                    top: _position.dy,
                    child: GestureDetector(
                      onPanStart: (_) {
                        setState(() {
                          _isDragging = true;
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          double newX = _position.dx + details.delta.dx;
                          double newY = _position.dy + details.delta.dy;

                          // Prevent button from going offscreen
                          newX = newX.clamp(16.0, size.width - 64.0);
                          newY = newY.clamp(
                            padding.top + 16.0,
                            size.height - padding.bottom - 64.0,
                          );

                          _position = Offset(newX, newY);
                        });
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _isDragging = false;
                        });
                      },
                      onTap: () {
                        if (!_isDragging) {
                          TectaInspector.navigatorKey.currentState?.push(
                            MaterialPageRoute<void>(
                              builder: (context) => const TectaInspectorDashboard(),
                              fullscreenDialog: true,
                            ),
                          );
                        }
                      },
                      child: Material(
                        type: MaterialType.transparency,
                        child: Opacity(
                          opacity: _isDragging ? 0.9 : 0.6,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E1E1E),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.bug_report,
                              color: Colors.tealAccent,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
