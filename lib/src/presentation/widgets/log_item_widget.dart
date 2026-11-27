import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../curl_builder.dart';
import '../../models/log_entry.dart';
import '../inspector_colors.dart';
import 'json_view.dart';
import 'log_chips.dart';
import 'log_sections.dart';
import 'stack_trace_view.dart';

class LogItemWidget extends StatefulWidget {
  final LogEntry log;
  final bool isDarkMode;
  final int index;

  /// The search text, highlighted in the title.
  final String highlight;
  const LogItemWidget({
    super.key,
    required this.log,
    required this.isDarkMode,
    required this.index,
    this.highlight = '',
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
                  const Icon(Icons.check_circle_outline,
                      color: Colors.tealAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    message,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
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

  Widget _copyButton(String label, String text, String toast) {
    final color = widget.isDarkMode ? Colors.tealAccent : Colors.teal;
    return OutlinedButton.icon(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: text));
        _showToast(context, toast);
      },
      icon: Icon(Icons.copy_all, size: 16, color: color),
      label: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Color _getLogColor(LogType type) {
    final dark = widget.isDarkMode;
    if (widget.log.isError) return dark ? Colors.redAccent : Colors.red.shade900;
    switch (type) {
      case LogType.network:
        return dark ? Colors.greenAccent : Colors.green.shade900;
      case LogType.database:
        return dark ? Colors.orangeAccent : const Color(0xFF9A4A00);
      case LogType.navigator:
        return dark ? Colors.blueAccent : Colors.blue.shade900;
      case LogType.print:
      default:
        return dark ? Colors.white70 : Colors.black54;
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

  String _time(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${t.millisecond.toString().padLeft(3, '0')}';
  }

  /// `time • TYPE`, and for a network log the duration after it. The title
  /// already says the method and the status, so they are not repeated here.
  Widget _subtitle(LogEntry log) {
    final duration = log.type == LogType.network ? log.durationMs : null;
    return Text(
      '${_time(log.timestamp)} • ${log.type.name.toUpperCase()}'
      '${duration != null ? ' • $duration ms' : ''}',
      style: TextStyle(color: InspectorColors.secondaryText(widget.isDarkMode), fontSize: 11),
    );
  }

  /// The parts of a network log, each of which can be folded.
  List<Widget> _networkSections(LogEntry log) {
    final dark = widget.isDarkMode;
    final status = log.statusCode;
    final requestBody = prettyBody(log.metadata?['requestBody']);
    final responseBody = prettyBody(log.metadata?['responseBody']);
    final headers = log.metadata?['requestHeaders'];

    return [
      LogSection(
        title: 'Summary',
        isDarkMode: dark,
        child: Column(
          children: [
            SummaryRow(label: 'Method', value: log.method ?? '-', isDarkMode: dark),
            SummaryRow(label: 'URL', value: '${log.metadata?['url'] ?? '-'}', isDarkMode: dark),
            SummaryRow(
              label: 'Status',
              value: status?.toString() ?? 'No response',
              isDarkMode: dark,
              valueColor: statusColor(status, dark: dark),
            ),
            if (log.durationMs != null)
              SummaryRow(label: 'Duration', value: '${log.durationMs} ms', isDarkMode: dark),
          ],
        ),
      ),
      if (log.error != null)
        LogSection(
          title: 'Error',
          isDarkMode: dark,
          child: SelectableText(
            log.error!,
            style: const TextStyle(
                fontFamily: 'monospace', fontSize: 12, color: Colors.redAccent),
          ),
        ),
      if (requestBody.isNotEmpty && requestBody != '{}')
        LogSection(
          title: 'Request body',
          isDarkMode: dark,
          child: JsonView(text: requestBody, isDarkMode: dark),
        ),
      if (responseBody.isNotEmpty)
        LogSection(
          title: log.isError ? 'Error response' : 'Response body',
          isDarkMode: dark,
          child: JsonView(text: responseBody, isDarkMode: dark),
        ),
      if (headers is Map && headers.isNotEmpty)
        LogSection(
          title: 'Request headers',
          isDarkMode: dark,
          initiallyExpanded: false,
          child: JsonView(text: prettyBody(headers), isDarkMode: dark),
        ),
      LogSection(
        title: 'Raw log',
        isDarkMode: dark,
        initiallyExpanded: false,
        child: SelectableText(
          log.content,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: InspectorColors.primaryText(dark),
          ),
        ),
      ),
    ];
  }

  List<Widget> _plainSections(LogEntry log) {
    final dark = widget.isDarkMode;
    return [
      SelectableText(
        log.content,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: InspectorColors.primaryText(dark),
        ),
      ),
      if (log.error != null) ...[
        const SizedBox(height: 12),
        LogSection(
          title: 'Error',
          isDarkMode: dark,
          child: SelectableText(
            log.error!,
            style: const TextStyle(
                fontFamily: 'monospace', fontSize: 12, color: Colors.redAccent),
          ),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final logColor = _getLogColor(log.type);

    // Alternating row background color (zebra striping)
    final rowBgColor = widget.index % 2 == 0
        ? (widget.isDarkMode ? const Color(0xFF18181A) : Colors.white)
        : (widget.isDarkMode
            ? const Color(0xFF222225)
            : const Color(0xFFF2F4F7));

    final containerBg =
        widget.isDarkMode ? const Color(0xFF101012) : const Color(0xFFECEFF1);
    final textTitleColor = log.isError
        ? (widget.isDarkMode ? Colors.redAccent : Colors.red.shade900)
        : (widget.isDarkMode ? Colors.white : const Color(0xFF1C1C1E));

    final curl = buildCurl(log);
    final responseBody = log.metadata?['responseBody'];
    final response = log.type == LogType.network && responseBody != null
        ? prettyBody(responseBody)
        : null;
    final isNetwork = log.type == LogType.network && log.method != null;

    final borderColor = widget.isDarkMode
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);

    return Material(
      color: rowBgColor,
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: Icon(_getLogIcon(log.type), color: logColor, size: 22),
            title: HighlightText(
              text: log.title,
              query: widget.highlight,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textTitleColor,
                fontSize: 14,
              ),
            ),
            subtitle: _subtitle(log),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        _copyButton('Copy Log', log.content,
                            'Log copied to clipboard!'),
                        if (curl != null)
                          _copyButton(
                              'Copy cURL', curl, 'cURL copied to clipboard!'),
                        if (response != null)
                          _copyButton('Copy Response', response,
                              'Response copied to clipboard!'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(isNetwork ? _networkSections(log) : _plainSections(log)),
                  if (log.stackTrace != null && log.stackTrace!.isNotEmpty)
                    LogSection(
                      title: 'Stack trace',
                      isDarkMode: widget.isDarkMode,
                      child: StackTraceView(
                          stackTrace: log.stackTrace!,
                          isDarkMode: widget.isDarkMode),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
