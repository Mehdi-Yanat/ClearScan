import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppNotificationType {
  scanCompleted,
  imageImported,
  folderCreated,
  appUpdate,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.detail,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final AppNotificationType type;
  final String detail;
  final DateTime createdAt;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    detail: detail,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'type': type.name,
    'detail': detail,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
  };

  factory AppNotification.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid notification record.');
    }
    final id = value['id'];
    final typeName = value['type'];
    final detail = value['detail'];
    final createdAt = value['createdAt'];
    final isRead = value['isRead'];
    final type = AppNotificationType.values.where(
      (item) => item.name == typeName,
    );
    if (id is! String ||
        detail is! String ||
        createdAt is! String ||
        isRead is! bool ||
        type.isEmpty) {
      throw const FormatException('Invalid notification record.');
    }
    final date = DateTime.tryParse(createdAt);
    if (date == null) {
      throw const FormatException('Invalid notification date.');
    }
    return AppNotification(
      id: id,
      type: type.first,
      detail: detail,
      createdAt: date,
      isRead: isRead,
    );
  }
}

const _storageKey = 'app_notifications_v1';
final notificationRevision = ValueNotifier<int>(0);
final notificationUnreadCount = ValueNotifier<int>(0);

Future<void> _operationQueue = Future<void>.value();

Future<T> _serialize<T>(Future<T> Function() action) {
  final completer = Completer<T>();
  _operationQueue = _operationQueue.then((_) async {
    try {
      completer.complete(await action());
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    }
  });
  return completer.future;
}

Future<List<AppNotification>> loadNotifications() => _serialize(() async {
  final notifications = await _readNotifications();
  notificationUnreadCount.value = notifications
      .where((item) => !item.isRead)
      .length;
  return notifications;
});

Future<void> addNotification(AppNotificationType type, {String detail = ''}) =>
    _serialize(() async {
      final notifications = await _readNotifications();
      notifications.insert(
        0,
        AppNotification(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: type,
          detail: detail,
          createdAt: DateTime.now(),
          isRead: false,
        ),
      );
      await _writeNotifications(notifications);
    });

Future<void> addAppUpdate({required String title, required String message}) =>
    addNotification(
      AppNotificationType.appUpdate,
      detail: jsonEncode({'title': title, 'message': message}),
    );

Future<void> markNotificationRead(String id) => _serialize(() async {
  final notifications = await _readNotifications();
  final updated = [
    for (final item in notifications)
      if (item.id == id) item.copyWith(isRead: true) else item,
  ];
  await _writeNotifications(updated);
});

Future<void> markAllNotificationsRead() => _serialize(() async {
  final notifications = await _readNotifications();
  await _writeNotifications([
    for (final item in notifications) item.copyWith(isRead: true),
  ]);
});

Future<void> clearNotifications() => _serialize(() async {
  final preferences = await SharedPreferences.getInstance();
  if (!await preferences.remove(_storageKey)) {
    throw StateError('Could not clear notifications.');
  }
  notificationUnreadCount.value = 0;
  notificationRevision.value++;
});

Future<List<AppNotification>> _readNotifications() async {
  final preferences = await SharedPreferences.getInstance();
  final encoded = preferences.getStringList(_storageKey) ?? const <String>[];
  return [
    for (final item in encoded) AppNotification.fromJson(jsonDecode(item)),
  ];
}

Future<void> _writeNotifications(List<AppNotification> notifications) async {
  final preferences = await SharedPreferences.getInstance();
  final encoded = [for (final item in notifications) jsonEncode(item.toJson())];
  if (!await preferences.setStringList(_storageKey, encoded)) {
    throw StateError('Could not save notifications.');
  }
  notificationUnreadCount.value = notifications
      .where((item) => !item.isRead)
      .length;
  notificationRevision.value++;
}
