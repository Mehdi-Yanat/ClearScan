import 'package:flutter/material.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
}) {
  final colors = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
}
