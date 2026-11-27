import 'package:flutter/material.dart';

import '../inspector_colors.dart';

/// A titled block that can be folded. Long logs are easier to read when the
/// parts that matter stay open and the rest, such as headers, stay closed.
class LogSection extends StatefulWidget {
  const LogSection({
    super.key,
    required this.title,
    required this.child,
    required this.isDarkMode,
    this.initiallyExpanded = true,
  });

  final String title;
  final Widget child;
  final bool isDarkMode;
  final bool initiallyExpanded;

  @override
  State<LogSection> createState() => _LogSectionState();
}

class _LogSectionState extends State<LogSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final titleColor = InspectorColors.sectionTitle(widget.isDarkMode);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 18,
                    color: InspectorColors.secondaryText(widget.isDarkMode),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 2),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

/// One `label  value` line of a summary.
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    required this.isDarkMode,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isDarkMode;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(color: InspectorColors.secondaryText(isDarkMode), fontSize: 12),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: valueColor ?? InspectorColors.primaryText(isDarkMode),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
