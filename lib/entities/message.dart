import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'message.g.dart';

/// A helper function to convert a Firestore Timestamp to a DateTime.
DateTime? _timestampToDateTime(Timestamp? timestamp) => timestamp?.toDate();

/// A helper function to convert a DateTime to a Firestore Timestamp.
Timestamp? _dateTimeToTimestamp(DateTime? dateTime) =>
    dateTime != null ? Timestamp.fromDate(dateTime) : null;

@JsonSerializable()
class Message {
  final String id;
  final String? systemText;
  final String uid;
  final String? targetUid;
  final String displayName;

  @JsonKey(
    fromJson: _timestampToDateTime,
    toJson: _dateTimeToTimestamp,
  )
  final DateTime? createdAt;
  final String roomId;

  Message({
    String? id,
    this.systemText,
    required this.uid,
    this.targetUid,
    required this.displayName,
    this.createdAt,
    required this.roomId,
  }) : id = id ?? const Uuid().v4();

  /// An empty message, used for default or placeholder values.
  static final Message empty = Message(
    uid: '',
    displayName: '',
    roomId: '',
  );

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
