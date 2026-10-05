import 'package:polypodium_core/lww_vectors.dart';
import 'package:polypodium_core/polypodium_core.dart';
import 'package:test/test.dart';

void main() {
  group('incomingWins', () {
    test('applies when there is no stored row yet', () {
      expect(
        incomingWins(
          incomingUpdatedAt: DateTime.utc(2026, 1, 1),
          incomingDeviceId: 'device-a',
          currentUpdatedAt: null,
          currentDeviceId: null,
        ),
        isTrue,
      );
    });

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
      bool wins(String? incoming, String? current) => incomingWins(
            incomingUpdatedAt: t,
            incomingDeviceId: incoming,
            currentUpdatedAt: t,
            currentDeviceId: current,
          );
      expect(wins('device-b', 'device-a'), isTrue);
      expect(wins('device-a', 'device-b'), isFalse);
      // Two replicas holding each other's version agree on one winner.
      expect(wins('device-b', 'device-a'), isNot(wins('device-a', 'device-b')));
    });

    test('a null deviceId compares as the empty string', () {
      final t = DateTime.utc(2026, 1, 1);
      bool wins(String? incoming, String? current) => incomingWins(
            incomingUpdatedAt: t,
            incomingDeviceId: incoming,
            currentUpdatedAt: t,
            currentDeviceId: current,
          );
      expect(wins('device-a', null), isTrue);
      expect(wins(null, 'device-a'), isFalse);
      expect(wins(null, null), isFalse);
      expect(wins('', null), isFalse);
      expect(wins(null, ''), isFalse);
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
      expect(
        incomingWins(
          incomingUpdatedAt: utc.subtract(const Duration(microseconds: 1)),
          incomingDeviceId: 'device-b',
          currentUpdatedAt: utc,
          currentDeviceId: 'device-a',
        ),
        isFalse,
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
        );
      });
    }

    test('null deviceIds behave exactly like the empty string', () {
      // The server runs these vectors with '' in place of null.
      for (final v in lwwVectors) {
        expect(
          incomingWins(
            incomingUpdatedAt: v.incomingUpdatedAt,
            incomingDeviceId: v.incomingDeviceId ?? '',
            currentUpdatedAt: v.currentUpdatedAt,
            currentDeviceId: v.currentDeviceId ?? '',
          ),
          v.incomingWins,
          reason: v.description,
        );
      }
    });
  });
}
