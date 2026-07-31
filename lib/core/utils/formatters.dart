/// Small, pure formatting helpers shared across widgets.
/// Kept in `core` (not `presentation`) because they have no Flutter/UI
/// dependency and could be reused by data/domain layers (e.g. logging).
class Formatters {
  Formatters._();

  static String duration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  static String fileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size < 10 && i > 0 ? 2 : 0)} ${suffixes[i]}';
  }

  /// Estimated output size for a given duration + target bitrate, used so
  /// the compression sheet can show a size *before* the user commits.
  static int estimatedSizeBytes({
    required Duration duration,
    required int bitrateKbps,
  }) {
    final bits = bitrateKbps * 1000 * duration.inMilliseconds / 1000;
    return (bits / 8).round();
  }
}
