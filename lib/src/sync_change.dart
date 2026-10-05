/// Wire-format change record exchanged by the app and the server on
/// `/sync/changes` and `/sync/receive`.
class SyncChange {
  final String entityType;
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String deviceId;
  final int rev;

  SyncChange({
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
    required this.rev,
  });

  factory SyncChange.fromJson(Map<String, dynamic> json) => SyncChange(
        entityType: json['entityType'] as String,
        entityId: json['entityId'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'] as String)
            : null,
        deviceId: json['deviceId'] as String,
        // On upload this is the sender's own local revision; the server
        // assigns its own rev on write and never trusts this value.
        rev: json['rev'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'entityType': entityType,
        'entityId': entityId,
        'payload': payload,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'deletedAt': deletedAt?.toUtc().toIso8601String(),
        'deviceId': deviceId,
        'rev': rev,
      };
}
