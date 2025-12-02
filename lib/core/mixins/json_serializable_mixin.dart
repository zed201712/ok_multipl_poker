import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

mixin JsonSerializableMixin {
  Set<String> get timeKeys;
  String get jsonString => jsonEncode(convertTime(timeKeys));

  Map<String, dynamic> toJson();

  Map<String, dynamic> convertTime(Set<String> keys) {
    return toJson().map((k, v) {
      if (keys.contains(k) && v is Timestamp) {
        return MapEntry(k, v.millisecondsSinceEpoch);
      }
      return MapEntry(k, v);
    });
  }
}