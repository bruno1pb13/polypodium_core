/// One shared last-write-wins test case: an incoming change against the
/// currently stored row, with the outcome every implementation of the rule
/// must produce.
class LwwVector {
  final String description;
  final DateTime currentUpdatedAt;

  /// Null means the row's writer is unknown; see `incomingWins`.
  final String? currentDeviceId;
  final DateTime incomingUpdatedAt;
  final String? incomingDeviceId;

  /// Expected result of `incomingWins` (and of the server's SQL).
  final bool incomingWins;

  const LwwVector({
    required this.description,
    required this.currentUpdatedAt,
    required this.currentDeviceId,
    required this.incomingUpdatedAt,
    required this.incomingDeviceId,
    required this.incomingWins,
  });
}

// Lowercase UUIDs, the format the server issues, so code-unit and Postgres
// collation ordering agree.
const _deviceLow = '1b4e28ba-2fa1-41d2-883f-0016d3cca427';
const _deviceHigh = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

/// Shared vectors that every implementation of the LWW rule (`incomingWins`
/// and the server's SQL) must agree on. A null deviceId runs as `''` on the
/// server, whose `device_id` column is NOT NULL.
final List<LwwVector> lwwVectors = [
  LwwVector(
    description: 'strictly newer incoming wins',
    currentUpdatedAt: DateTime.utc(2026, 1, 1),
    currentDeviceId: _deviceHigh,
    incomingUpdatedAt: DateTime.utc(2026, 1, 2),
    incomingDeviceId: _deviceLow,
    incomingWins: true,
  ),
  LwwVector(
    description: 'older incoming loses',
    currentUpdatedAt: DateTime.utc(2026, 1, 2),
    currentDeviceId: _deviceLow,
    incomingUpdatedAt: DateTime.utc(2026, 1, 1),
    incomingDeviceId: _deviceHigh,
    incomingWins: false,
  ),
  LwwVector(
    description: 'newer by one microsecond wins',
    currentUpdatedAt: DateTime.utc(2026, 1, 1, 12, 0, 0, 0, 0),
    currentDeviceId: _deviceHigh,
    incomingUpdatedAt: DateTime.utc(2026, 1, 1, 12, 0, 0, 0, 1),
    incomingDeviceId: _deviceLow,
    incomingWins: true,
  ),
  LwwVector(
    description: 'older by one microsecond loses',
    currentUpdatedAt: DateTime.utc(2026, 1, 1, 12, 0, 0, 0, 1),
    currentDeviceId: _deviceLow,
    incomingUpdatedAt: DateTime.utc(2026, 1, 1, 12, 0, 0, 0, 0),
    incomingDeviceId: _deviceHigh,
    incomingWins: false,
  ),
  LwwVector(
    description: 'tie: greater incoming deviceId wins',
    currentUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    currentDeviceId: _deviceLow,
    incomingUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    incomingDeviceId: _deviceHigh,
    incomingWins: true,
  ),
  LwwVector(
    description: 'tie: smaller incoming deviceId loses',
    currentUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    currentDeviceId: _deviceHigh,
    incomingUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    incomingDeviceId: _deviceLow,
    incomingWins: false,
  ),
  LwwVector(
    description: 'tie: same device re-sending the same change is a no-op',
    currentUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    currentDeviceId: _deviceLow,
    incomingUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    incomingDeviceId: _deviceLow,
    incomingWins: false,
  ),
  LwwVector(
    description: 'newer incoming wins regardless of a smaller deviceId',
    currentUpdatedAt: DateTime.utc(2025, 1, 1),
    currentDeviceId: _deviceHigh,
    incomingUpdatedAt: DateTime.utc(2025, 6, 1),
    incomingDeviceId: _deviceLow,
    incomingWins: true,
  ),
  LwwVector(
    description: 'tie: known incoming deviceId beats a null current one',
    currentUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    currentDeviceId: null,
    incomingUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    incomingDeviceId: _deviceLow,
    incomingWins: true,
  ),
  LwwVector(
    description: 'tie: null incoming deviceId loses to a known current one',
    currentUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    currentDeviceId: _deviceLow,
    incomingUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    incomingDeviceId: null,
    incomingWins: false,
  ),
  LwwVector(
    description: 'tie: null against null is a no-op',
    currentUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    currentDeviceId: null,
    incomingUpdatedAt: DateTime.utc(2026, 1, 1, 12),
    incomingDeviceId: null,
    incomingWins: false,
  ),
  LwwVector(
    description: 'newer incoming with a null deviceId still wins',
    currentUpdatedAt: DateTime.utc(2026, 1, 1),
    currentDeviceId: _deviceHigh,
    incomingUpdatedAt: DateTime.utc(2026, 1, 2),
    incomingDeviceId: null,
    incomingWins: true,
  ),
  LwwVector(
    description: 'older incoming loses to a null current deviceId',
    currentUpdatedAt: DateTime.utc(2026, 1, 2),
    currentDeviceId: null,
    incomingUpdatedAt: DateTime.utc(2026, 1, 1),
    incomingDeviceId: _deviceHigh,
    incomingWins: false,
  ),
];
