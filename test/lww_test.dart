import 'package:polypodium_core/lww_vectors.dart';
import 'package:polypodium_core/polypodium_core.dart';
import 'package:test/test.dart';

void main() {
  group('shouldApplyRemote', () {
    test('applies when there is no local row yet', () {
      expect(
        shouldApplyRemote(
          localUpdatedAt: null,
          remoteUpdatedAt: DateTime(2026, 1, 1),
        ),
        isTrue,
      );
    });

    test('applies when remote is strictly newer', () {
      expect(
        shouldApplyRemote(
          localUpdatedAt: DateTime(2026, 1, 1),
          remoteUpdatedAt: DateTime(2026, 1, 2),
        ),
        isTrue,
      );
    });

    test('rejects when remote is older', () {
      expect(
        shouldApplyRemote(
          localUpdatedAt: DateTime(2026, 1, 2),
          remoteUpdatedAt: DateTime(2026, 1, 1),
        ),
        isFalse,
      );
    });

    test('applies on an exact timestamp tie (remote wins ties)', () {
      final t = DateTime(2026, 1, 1, 12, 0, 0);
      expect(
        shouldApplyRemote(localUpdatedAt: t, remoteUpdatedAt: t),
        isTrue,
      );
    });

    test('re-applying the same change is idempotent', () {
      final t = DateTime(2026, 1, 1, 12, 0, 0);
      // First apply: no local row yet.
      expect(
          shouldApplyRemote(localUpdatedAt: null, remoteUpdatedAt: t), isTrue);
      // Second apply of the identical change: local now has updatedAt == t.
      expect(shouldApplyRemote(localUpdatedAt: t, remoteUpdatedAt: t), isTrue);
    });

    test('compares instants, not wall-clock fields', () {
      final utc = DateTime.utc(2026, 1, 1, 12);
      expect(
        shouldApplyRemote(localUpdatedAt: utc, remoteUpdatedAt: utc.toLocal()),
        isTrue,
      );
      expect(
        shouldApplyRemote(
          localUpdatedAt: utc,
          remoteUpdatedAt: utc.subtract(const Duration(microseconds: 1)),
        ),
        isFalse,
      );
    });
  });

  group('incomingWins', () {
    test('resolves by updatedAt, not arrival order', () {
      // Newer edit stored first, older edit arrives second (out-of-order
      // delivery) -- the older one must lose despite arriving later.
      final older = DateTime.utc(2025, 1, 1);
      final newer = DateTime.utc(2025, 6, 1);
      expect(
        incomingWins(
          incomingUpdatedAt: older,
          incomingDeviceId: 'device-a',
          currentUpdatedAt: newer,
          currentDeviceId: 'device-a',
        ),
        isFalse,
      );
    });

    test('tie on the same device is a no-op', () {
      final t = DateTime.utc(2026, 1, 1);
      expect(
        incomingWins(
          incomingUpdatedAt: t,
          incomingDeviceId: 'device-a',
          currentUpdatedAt: t,
          currentDeviceId: 'device-a',
        ),
        isFalse,
      );
    });

    test('tie is broken by the greater deviceId, symmetrically', () {
      final t = DateTime.utc(2026, 1, 1);
      bool wins(String incoming, String current) => incomingWins(
            incomingUpdatedAt: t,
            incomingDeviceId: incoming,
            currentUpdatedAt: t,
            currentDeviceId: current,
          );
      expect(wins('device-b', 'device-a'), isTrue);
      expect(wins('device-a', 'device-b'), isFalse);
    });

    test('compares instants, not wall-clock fields', () {
      final utc = DateTime.utc(2026, 1, 1, 12);
      expect(
        incomingWins(
          incomingUpdatedAt: utc.toLocal(),
          incomingDeviceId: 'device-b',
          currentUpdatedAt: utc,
          currentDeviceId: 'device-a',
        ),
        isTrue,
      );
    });
  });

  group('shared vectors', () {
    for (final v in lwwVectors) {
      test(v.description, () {
        expect(
          incomingWins(
            incomingUpdatedAt: v.incomingUpdatedAt,
            incomingDeviceId: v.incomingDeviceId,
            currentUpdatedAt: v.currentUpdatedAt,
            currentDeviceId: v.currentDeviceId,
          ),
          v.incomingWins,
          reason: 'incomingWins',
        );
        expect(
          shouldApplyRemote(
            localUpdatedAt: v.currentUpdatedAt,
            remoteUpdatedAt: v.incomingUpdatedAt,
          ),
          v.shouldApplyRemote,
          reason: 'shouldApplyRemote',
        );
      });
    }

    test('the comparators only diverge on exact-timestamp ties', () {
      for (final v in lwwVectors) {
        if (v.incomingWins != v.shouldApplyRemote) {
          expect(
              v.incomingUpdatedAt.isAtSameMomentAs(v.currentUpdatedAt), isTrue,
              reason: v.description);
        }
      }
    });
  });
}
