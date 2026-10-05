/// One shared last-write-wins test case: an incoming change against the
/// currently stored row, with the outcome each comparator must produce.
class LwwVector {
  final String description;
  final DateTime currentUpdatedAt;
  final String currentDeviceId;
  final DateTime incomingUpdatedAt;
  final String incomingDeviceId;

  /// Expected result of `incomingWins` (and of the server's SQL).
  final bool incomingWins;

  /// Expected result of `shouldApplyRemote`, which has no deviceId tiebreak.
  final bool shouldApplyRemote;

  const LwwVector({
    required this.description,
    required this.currentUpdatedAt,
    required this.currentDeviceId,
    required this.incomingUpdatedAt,
    required this.incomingDeviceId,
    required this.incomingWins,
    required this.shouldApplyRemote,
  });
}

// Lowercase UUIDs, the format the server issues, so code-unit and Postgres
// collation ordering agree.
const _deviceLow = '1b4e28ba-2fa1-41d2-883f-0016d3cca427';
const _deviceHigh = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

/// Shared vectors that every implementation of the LWW rule (the Dart
/// comparators here and the server's SQL) must agree on.
final List<LwwVector> lwwVectors = [
  LwwVector(
    description: 'strictly newer incoming wins',
    currentUpdatedAt: DateTime.utc(2026, 1, 1),
    currentDeviceId: _deviceHigh,
    incomingUpdatedAt: DateTime.utc(2026, 1, 2),
    incomingDeviceId: _deviceLow,
    incomingWins: true,
    shouldApplyRemote: true,
  ),
  LwwVector(
    description: 'older incoming loses',
    currentUpdatedAt: DateTime.utc(2026, 1, 2),
    currentDeviceId: _deviceLow,
    incomingUpdatedAt: DateTime.utc(2026, 1, 1),
    incomingDeviceId: _deviceHigh,
    incomingWins: false,
    shouldApplyRemote: false,
  ),
  LwwVector(
    description: 'newer by one microsecond wins',
    currentUpdatedAt: DateTime.utc(2026, 1, 1, 12, 0, 0, 0, 0),
    currentDeviceId: _deviceHigh,
    incomingUpdatedAt: DateTime.utc(2026, 1, 1, 12, 0, 0, 0, 1),
    incomingDeviceId: _deviceLow,
    incomingWins: true,
    shouldApplyRemote: true,
  ),
  LwwVector(
    description: 'older by one microsecond loses',
    currentUpdatedAt: DateTime.utc(2026, 1, 1, 12, 0, 0, 0, 1),
    currentDeviceId: _deviceLow,
    incomingUpdatedAt: DateTime.utc(2026, 1, 1, 12, 0, 0, 0, 0),
    incomingDeviceId: _deviceHigh,
    incomingWins: false,
    shouldApplyRemote: false,
  ),
  LwwVector(
    description: 'tie: greater incoming deviceId wins',
    currentUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    currentDeviceId: _deviceLow,
    incomingUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    incomingDeviceId: _deviceHigh,
    incomingWins: true,
    shouldApplyRemote: true,
  ),
  // The one case where the two comparators diverge: the client has no
  // per-row deviceId, so remote always wins a tie there.
  LwwVector(
    description: 'tie: smaller incoming deviceId loses on the server',
    currentUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    currentDeviceId: _deviceHigh,
    incomingUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    incomingDeviceId: _deviceLow,
    incomingWins: false,
    shouldApplyRemote: true,
  ),
  LwwVector(
    description: 'tie: same device re-sending the same change is a no-op',
    currentUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    currentDeviceId: _deviceLow,
    incomingUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    incomingDeviceId: _deviceLow,
    incomingWins: false,
    shouldApplyRemote: true,
  ),
  LwwVector(
    description: 'newer incoming wins regardless of a smaller deviceId',
    currentUpdatedAt: DateTime.utc(2025, 1, 1),
    currentDeviceId: _deviceHigh,
    incomingUpdatedAt: DateTime.utc(2025, 6, 1),
    incomingDeviceId: _deviceLow,
    incomingWins: true,
    shouldApplyRemote: true,
  ),
];
