import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/log_entry.dart';
import '../../tecta_inspector_facade.dart';

class LogItemWidget extends StatefulWidget {
  final LogEntry log;
  final bool isDarkMode;
  final int index;
  const LogItemWidget({
    super.key,
    required this.log,
    required this.isDarkMode,
    required this.index,
  });

  @override
  State<LogItemWidget> createState() => _LogItemWidgetState();
}

class _LogItemWidgetState extends State<LogItemWidget> {
  bool _isExpanded = false;

  void _showToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50,
        left: 24,
        right: 24,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isDarkMode 
                    ? const Color.fromRGBO(44, 44, 44, 0.9) 
                    : const Color.fromRGBO(51, 51, 51, 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.tealAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 1), () {
      entry.remove();
    });
  }

  Color _getLogColor(LogType type) {
    if (widget.log.isError) return Colors.redAccent;
    switch (type) {
      case LogType.network:
        return Colors.greenAccent;
      case LogType.database:
        return Colors.orangeAccent;
      case LogType.navigator:
        return Colors.blueAccent;
      case LogType.print:
      default:
        return widget.isDarkMode ? Colors.white70 : Colors.black54;
    }
  }

  IconData _getLogIcon(LogType type) {
    if (widget.log.isError) return Icons.error_outline;
    switch (type) {
      case LogType.network:
        return Icons.language;
      case LogType.database:
        return Icons.storage;
      case LogType.navigator:
        return Icons.navigation_outlined;
      case LogType.print:
      default:
        return Icons.notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final logColor = _getLogColor(log.type);
    final timeStr =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';

    // Alternating row background color (zebra striping)
    final rowBgColor = widget.index % 2 == 0
        ? (widget.isDarkMode ? const Color(0xFF18181A) : Colors.white)
        : (widget.isDarkMode ? const Color(0xFF222225) : const Color(0xFFF2F4F7));

    final containerBg = widget.isDarkMode ? const Color(0xFF101012) : const Color(0xFFECEFF1);
    final textTitleColor = log.isError
        ? Colors.redAccent
        : (widget.isDarkMode ? Colors.white : const Color(0xFF1C1C1E));
    final detailTextColor = widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF2C2C2C);
    final stackTraceBg = widget.isDarkMode ? const Color(0xFF2A1C1C) : const Color(0xFFFFEBEE);
    final stackTraceTextColor = widget.isDarkMode ? const Color(0xFFFFCDCD) : const Color(0xFFC62828);
    
    final borderColor = widget.isDarkMode 
        ? Colors.white.withOpacity(0.05) 
        : Colors.black.withOpacity(0.04);

    return Material(
      color: rowBgColor,
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: Icon(_getLogIcon(log.type), color: logColor, size: 22),
            title: Text(
              log.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textTitleColor,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              '$timeStr • ${log.type.name.toUpperCase()}',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            trailing: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.grey,
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: containerBg,
                border: Border(
                  top: BorderSide(color: borderColor),
                  bottom: BorderSide(color: borderColor),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: log.content));
                        _showToast(context, 'Log copied to clipboard!');
                      },
                      icon: Icon(Icons.copy_all, size: 16, color: widget.isDarkMode ? Colors.tealAccent : Colors.teal),
                      label: Text(
                        'Copy Log',
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.tealAccent : Colors.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    log.content,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: detailTextColor,
                    ),
                  ),
                  if (log.error != null) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Error Message:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 12),
                    ),
                    SelectableText(
                      log.error!,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.redAccent),
                    ),
                  ],
                  if (log.stackTrace != null && log.stackTrace!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Stack Trace:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: stackTraceBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.isDarkMode 
                              ? Colors.redAccent.withOpacity(0.15) 
                              : Colors.red.withOpacity(0.1),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          log.stackTrace!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: stackTraceTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
