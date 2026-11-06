/// The "Recorded by" text of a shared record (T112): "You" for the signed-in
/// user's own record, otherwise the creator's name, or "Another researcher"
/// when the phone does not know it (a record pulled before names existed).
String recordedByText({
  required String? creatorId,
  required String? creatorName,
  required String? userId,
}) {
  if (creatorId != null && creatorId == userId) return 'You';
  if (creatorName != null && creatorName.isNotEmpty) return creatorName;
  return 'Another researcher';
}
