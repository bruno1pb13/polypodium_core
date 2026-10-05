/// Whether an incoming change should overwrite the currently stored row,
/// using the full last-write-wins rule enforced by the server.
///
/// A strictly newer `updatedAt` always wins (last-write-wins by actual edit
/// time, not arrival order); on an exact `updatedAt` tie the change from the
/// greater `deviceId` wins, so every replica converges on the same winner.
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
  required String incomingDeviceId,
  required DateTime currentUpdatedAt,
  required String currentDeviceId,
}) {
  if (incomingUpdatedAt.isAfter(currentUpdatedAt)) return true;
  return incomingUpdatedAt.isAtSameMomentAs(currentUpdatedAt) &&
      incomingDeviceId.compareTo(currentDeviceId) > 0;
}

/// Whether an incoming remote change should overwrite the local row.
///
/// Same last-write-wins-by-edit-time rule as [incomingWins] (the server's
/// `ON CONFLICT` clause) -- a strictly newer `updatedAt` always wins,
/// replacing the old event-log behavior of resolving conflicts by arrival
/// order instead of real edit time.
///
/// Unlike the server, the client does not persist a per-row `deviceId`
/// locally (only the wire format carries one), so on an exact `updatedAt`
/// tie the remote change wins by default rather than tiebreaking on
/// deviceId. Exact-timestamp collisions between two independent devices'
/// human-paced edits are negligible for this app; if that ever needs to
/// change, a `deviceId` column would have to be added to every entity
/// table to restore full symmetry with the server's comparator.
bool shouldApplyRemote({
  required DateTime? localUpdatedAt,
  required DateTime remoteUpdatedAt,
}) {
  if (localUpdatedAt == null) return true;
  return !remoteUpdatedAt.isBefore(localUpdatedAt);
}
