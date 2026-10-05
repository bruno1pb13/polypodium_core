/// Whether an incoming change should overwrite the currently stored row --
/// the single last-write-wins rule shared by the server and the app.
///
/// A strictly newer `updatedAt` always wins (last-write-wins by actual edit
/// time, not arrival order); on an exact `updatedAt` tie the change from the
/// greater `deviceId` wins, so every replica converges on the same winner.
/// An identical re-send (same `updatedAt`, same `deviceId`) is a no-op.
/// A null [currentUpdatedAt] means there is no stored row yet, so the
/// incoming change is always applied (a plain `INSERT` on the server).
///
/// A null `deviceId` (a row written before its writer had a known device,
/// e.g. on a device-only workspace or before the app stored one per row)
/// compares as the empty string: it loses every tie against a known device
/// and ties with another null. The server never stores a null `device_id`,
/// and `''` sorts before every non-empty string in Postgres too, so the
/// server's test suite runs the null vectors with `''` in their place.
///
/// The server cannot call this function directly: it applies the same rule
/// atomically inside the `ON CONFLICT ... DO UPDATE ... WHERE` clause in
/// `Polypodium_server/lib/features/sync/sync_repository.dart`:
///
/// ```sql
/// WHERE EXCLUDED.updated_at > table.updated_at
///    OR (EXCLUDED.updated_at = table.updated_at
///        AND EXCLUDED.device_id > table.device_id)
/// ```
///
/// That SQL must stay term-for-term identical to this function; the server's
/// test suite runs `lwwVectors` against Postgres to enforce it. Device ids
/// are compared by code unit here and by collation in Postgres, which agree
/// for the lowercase UUIDs the server issues.
bool incomingWins({
  required DateTime incomingUpdatedAt,
  required String? incomingDeviceId,
  required DateTime? currentUpdatedAt,
  required String? currentDeviceId,
}) {
  if (currentUpdatedAt == null) return true;
  if (incomingUpdatedAt.isAfter(currentUpdatedAt)) return true;
  return incomingUpdatedAt.isAtSameMomentAs(currentUpdatedAt) &&
      (incomingDeviceId ?? '').compareTo(currentDeviceId ?? '') > 0;
}
