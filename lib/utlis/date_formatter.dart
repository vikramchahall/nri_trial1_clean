String formatDate(dynamic timestamp) {
  if (timestamp == null) return '';
  try {
    return DateTime.parse(timestamp.toString())
        .toLocal()
        .toString()
        .split(' ')
        .first;
  } catch (_) {
    return '';
  }
}
