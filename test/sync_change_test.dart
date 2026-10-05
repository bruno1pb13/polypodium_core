import 'package:polypodium_core/polypodium_core.dart';
import 'package:test/test.dart';

void main() {
  group('SyncChange', () {
    test('round-trips through JSON', () {
      final change = SyncChange(
        entityType: 'plant',
        entityId: 'p1',
        payload: {'nickname': 'Samambaia', 'status': 'active'},
        updatedAt: DateTime.utc(2026, 1, 1, 12, 0, 0, 0, 1),
        deletedAt: DateTime.utc(2026, 1, 2),
        deviceId: 'device-a',
        rev: 42,
      );

      final decoded = SyncChange.fromJson(change.toJson());

      expect(decoded.entityType, 'plant');
      expect(decoded.entityId, 'p1');
      expect(decoded.payload, change.payload);
      expect(decoded.updatedAt, change.updatedAt);
      expect(decoded.deletedAt, change.deletedAt);
      expect(decoded.deviceId, 'device-a');
      expect(decoded.rev, 42);
    });

    test('serializes timestamps as UTC ISO-8601', () {
      final json = SyncChange(
        entityType: 'plant',
        entityId: 'p1',
        payload: const {},
        updatedAt: DateTime.utc(2026, 1, 1, 12),
        deviceId: 'device-a',
        rev: 0,
      ).toJson();

      expect(json['updatedAt'], '2026-01-01T12:00:00.000Z');
      expect(json['deletedAt'], isNull);
    });

    test('missing rev defaults to 0 and missing deletedAt to null', () {
      final change = SyncChange.fromJson({
        'entityType': 'plant',
        'entityId': 'p1',
        'payload': <String, dynamic>{},
        'updatedAt': '2026-01-01T12:00:00.000Z',
        'deviceId': 'device-a',
      });

      expect(change.rev, 0);
      expect(change.deletedAt, isNull);
    });
  });
}
