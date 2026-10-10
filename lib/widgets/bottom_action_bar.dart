import 'package:flutter/material.dart';

enum BottomActionBarStyle { floating, toolbar }

class BottomActionBarItem {
  const BottomActionBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;
}

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.actions,
    this.style = BottomActionBarStyle.toolbar,
    this.margin = EdgeInsets.zero,
  });

  final List<BottomActionBarItem> actions;
  final BottomActionBarStyle style;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final actionButtons = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final action in actions)
          Expanded(
            child: _BottomActionBarButton(action: action, style: style),
          ),
      ],
    );

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: style == BottomActionBarStyle.floating
          ? BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A3A42)
                  : const Color(0xFF0F2A33),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline
                      .withValues(alpha: 0.2),
                ),
              ),
            ),
      child: style == BottomActionBarStyle.toolbar
          ? SafeArea(top: false, child: actionButtons)
          : actionButtons,
    );
  }
}

class _BottomActionBarButton extends StatelessWidget {
  const _BottomActionBarButton({required this.action, required this.style});

  final BottomActionBarItem action;
  final BottomActionBarStyle style;

  @override
  Widget build(BuildContext context) {
    if (style == BottomActionBarStyle.floating) {
      final color = action.iconColor ?? Colors.white;

      return InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBackground = isDark
        ? const Color(0xFF1A3A42)
        : const Color(0xFFE3F3F4);
    final defaultIconColor = isDark
        ? const Color(0xFF2CC4CF)
        : const Color(0xFF14909A);

    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: action.backgroundColor ?? defaultBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              action.icon,
              color: action.iconColor ?? defaultIconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
