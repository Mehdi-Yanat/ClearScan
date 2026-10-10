import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart' as loc;
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _notifications;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _notifications = loadNotifications();
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) return;
      setState(_refresh);
    } on Exception catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, error.toString());
    }
  }

  (String, String) _notificationText(
    AppNotification item,
    loc.AppLocalizations strings,
  ) {
    switch (item.type) {
      case AppNotificationType.scanCompleted:
        return (strings.notificationScanTitle, item.detail);
      case AppNotificationType.imageImported:
        return (strings.notificationImportTitle, item.detail);
      case AppNotificationType.folderCreated:
        return (strings.notificationFolderTitle, item.detail);
      case AppNotificationType.appUpdate:
        final update = jsonDecode(item.detail);
        if (update is! Map<String, dynamic> ||
            update['title'] is! String ||
            update['message'] is! String) {
          throw const FormatException('Invalid app update notification.');
        }
        return (update['title']! as String, update['message']! as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = loc.AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(strings.notificationsTitle),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: notificationUnreadCount,
            builder: (context, unread, _) => IconButton(
              tooltip: strings.notificationsMarkAllRead,
              onPressed: unread == 0
                  ? null
                  : () => _runAction(markAllNotificationsRead),
              icon: const Icon(Icons.done_all_rounded),
            ),
          ),
          IconButton(
            tooltip: strings.notificationsClearAll,
            onPressed: () => _runAction(clearNotifications),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: notificationRevision,
        builder: (context, _, _) => FutureBuilder<List<AppNotification>>(
          future: _notifications,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _MessageState(
                icon: Icons.error_outline_rounded,
                message: snapshot.error.toString(),
                actionLabel: strings.notificationsRetry,
                onAction: () => setState(_refresh),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final notifications = snapshot.data!;
            if (notifications.isEmpty) {
              return _MessageState(
                icon: Icons.notifications_none_rounded,
                message: strings.notificationsEmpty,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: AppColors.border(context)),
              itemBuilder: (context, index) {
                final item = notifications[index];
                final (title, body) = _notificationText(item, strings);
                return ListTile(
                  leading: Icon(
                    _iconFor(item.type),
                    color: item.isRead
                        ? AppColors.textMuted(context)
                        : AppColors.primary(context),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: item.isRead
                          ? FontWeight.w400
                          : FontWeight.w700,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (body.isNotEmpty) Text(body),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd(
                          Localizations.localeOf(context).toString(),
                        ).add_jm().format(item.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ],
                  ),
                  onTap: item.isRead
                      ? null
                      : () => _runAction(() => markNotificationRead(item.id)),
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _iconFor(AppNotificationType type) => switch (type) {
    AppNotificationType.scanCompleted => Icons.document_scanner_outlined,
    AppNotificationType.imageImported => Icons.add_photo_alternate_outlined,
    AppNotificationType.folderCreated => Icons.create_new_folder_outlined,
    AppNotificationType.appUpdate => Icons.campaign_outlined,
  };
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColors.textMuted(context)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    ),
  );
}
