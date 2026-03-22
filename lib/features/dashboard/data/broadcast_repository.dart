import 'package:supabase_flutter/supabase_flutter.dart';

/// Personal inbox row (e.g. role change) from [app_user_notifications].
class UserNotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  UserNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory UserNotificationModel.fromJson(Map<String, dynamic> json) {
    return UserNotificationModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class BroadcastModel {
  final String id;
  final String title;
  final String body;
  final String? senderId;
  final List<String> targetRoles;
  final DateTime createdAt;

  BroadcastModel({
    required this.id,
    required this.title,
    required this.body,
    this.senderId,
    required this.targetRoles,
    required this.createdAt,
  });

  factory BroadcastModel.fromJson(Map<String, dynamic> json) {
    final roles = json['target_roles'];
    return BroadcastModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      senderId: json['sender_id'] as String?,
      targetRoles: roles is List
          ? roles.map((e) => e.toString()).toList()
          : const ['all'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

/// Unified row for the notifications sheet (broadcasts + personal).
class InboxItem {
  final BroadcastModel? broadcast;
  final UserNotificationModel? personal;

  const InboxItem._({this.broadcast, this.personal});

  factory InboxItem.fromBroadcast(BroadcastModel b) => InboxItem._(broadcast: b);
  factory InboxItem.fromPersonal(UserNotificationModel u) => InboxItem._(personal: u);

  bool get isPersonal => personal != null;
  DateTime get createdAt => isPersonal ? personal!.createdAt : broadcast!.createdAt;
}

class BroadcastRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<InboxItem>> fetchInbox({int limit = 50}) async {
    final b = await fetchRecent(limit: limit);
    final u = await fetchUserNotifications(limit: limit);
    final items = <InboxItem>[
      ...b.map(InboxItem.fromBroadcast),
      ...u.map(InboxItem.fromPersonal),
    ];
    items.sort((a, c) => c.createdAt.compareTo(a.createdAt));
    if (items.length > limit) {
      return items.sublist(0, limit);
    }
    return items;
  }

  Future<List<BroadcastModel>> fetchRecent({int limit = 40}) async {
    final res = await _db.from('app_broadcasts').select().order('created_at', ascending: false).limit(limit);
    final list = res as List;
    return list.map((e) => BroadcastModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<UserNotificationModel>> fetchUserNotifications({int limit = 40}) async {
    final res = await _db.from('app_user_notifications').select().order('created_at', ascending: false).limit(limit);
    final list = res as List;
    return list.map((e) => UserNotificationModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<String> send({required String title, required String body, required List<String> targetRoles}) async {
    final res = await _db.rpc('send_app_broadcast', params: {
      'p_title': title,
      'p_body': body,
      'p_target_roles': targetRoles,
    });
    return res.toString();
  }
}
