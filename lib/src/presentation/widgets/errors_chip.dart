import 'package:flutter/material.dart';

import '../inspector_colors.dart';

/// The switch that shows only failures. It is red while there is something to
/// look at, muted when there is not, and filled when it is on. The number sits
/// in the same rounded badge the tabs use.
class ErrorsChip extends StatelessWidget {
  const ErrorsChip({
    super.key,
    required this.count,
    required this.selected,
    required this.onChanged,
    this.isDarkMode = true,
  });

  final int count;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final hasErrors = count > 0;
    final color = hasErrors
        ? (isDarkMode ? Colors.redAccent : Colors.red.shade900)
        : InspectorColors.secondaryText(isDarkMode);
    final background = selected
        ? color.withValues(alpha: 0.22)
        : (hasErrors ? color.withValues(alpha: 0.10) : Colors.transparent);

    return Semantics(
      button: true,
      selected: selected,
      label: 'Show errors only',
      child: Material(
        color: background,
        shape: StadiumBorder(
          side: BorderSide(
              color: color.withValues(alpha: selected ? 0.9 : 0.4),
              width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => onChanged(!selected),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? Icons.error : Icons.error_outline,
                    size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  'Errors',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color),
                ),
                if (hasErrors) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
