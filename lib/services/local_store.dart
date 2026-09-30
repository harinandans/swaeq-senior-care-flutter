import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight local persistence for slot completion, likes, comments, reactions.
class LocalStore {
  LocalStore._();
  static final instance = LocalStore._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  String _slotKey(String date, String slotId) => 'slot_done_${date}_$slotId';

  Future<bool> isSlotDone(String date, String slotId) async {
    final p = await prefs;
    return p.getBool(_slotKey(date, slotId)) ?? false;
  }

  Future<void> markSlotDone(String date, String slotId) async {
    final p = await prefs;
    await p.setBool(_slotKey(date, slotId), true);
  }

  Future<Map<String, dynamic>> slotCompletionMap(String date) async {
    final p = await prefs;
    final prefix = 'slot_done_${date}_';
    final out = <String, dynamic>{};
    for (final k in p.getKeys()) {
      if (k.startsWith(prefix) && p.getBool(k) == true) {
        out[k.substring(prefix.length)] = true;
      }
    }
    return out;
  }

  String _engagementKey(String contentId) => 'eng_$contentId';

  Future<Map<String, dynamic>> getEngagement(String contentId) async {
    final p = await prefs;
    final raw = p.getString(_engagementKey(contentId));
    if (raw == null) return {'liked': false, 'comment': '', 'reactions': {}};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> saveEngagement(String contentId, Map<String, dynamic> data) async {
    final p = await prefs;
    await p.setString(_engagementKey(contentId), jsonEncode(data));
  }

  Future<void> setLiked(String contentId, bool liked) async {
    final e = await getEngagement(contentId);
    e['liked'] = liked;
    await saveEngagement(contentId, e);
  }

  Future<void> setComment(String contentId, String comment) async {
    final e = await getEngagement(contentId);
    e['comment'] = comment;
    await saveEngagement(contentId, e);
  }

  Future<void> bumpReaction(String contentId, String reactionId) async {
    final e = await getEngagement(contentId);
    final reactions = Map<String, int>.from(
      (e['reactions'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
          {},
    );
    reactions[reactionId] = (reactions[reactionId] ?? 0) + 1;
    e['reactions'] = reactions;
    await saveEngagement(contentId, e);
  }
}
