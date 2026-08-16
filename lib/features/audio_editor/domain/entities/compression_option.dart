import 'package:equatable/equatable.dart';

enum CompressionQuality {
  veryHigh,
  high,
  medium,
  low,
  veryLow,
  voice,
  ultraLow
}

/// A user-selectable compression preset. `estimatedBytes` is computed by the
/// use case layer before the user commits, so the UI can show "128kbps —
/// ~2.4 MB (was 6.1 MB)" without actually re-encoding first.
class CompressionOption extends Equatable {
  final CompressionQuality quality;
  final int bitrateKbps;
  final String label;
  final int estimatedBytes;
  final bool isTargetSize;

  const CompressionOption({
    required this.quality,
    required this.bitrateKbps,
    required this.label,
    required this.estimatedBytes,
    this.isTargetSize = false,
  });

  @override
  List<Object?> get props =>
      [quality, bitrateKbps, label, estimatedBytes, isTargetSize];
}
