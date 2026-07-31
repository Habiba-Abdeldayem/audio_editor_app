import 'package:equatable/equatable.dart';

enum CompressionQuality { high, medium, low, voice }

/// A user-selectable compression preset. `estimatedBytes` is computed by the
/// use case layer before the user commits, so the UI can show "128kbps —
/// ~2.4 MB (was 6.1 MB)" without actually re-encoding first.
class CompressionOption extends Equatable {
  final CompressionQuality quality;
  final int bitrateKbps;
  final String label;
  final int estimatedBytes;

  const CompressionOption({
    required this.quality,
    required this.bitrateKbps,
    required this.label,
    required this.estimatedBytes,
  });

  @override
  List<Object?> get props => [quality, bitrateKbps, label, estimatedBytes];
}
