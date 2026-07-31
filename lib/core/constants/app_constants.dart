/// App-wide constants that don't belong to any single layer.
class AppConstants {
  AppConstants._();

  static const List<String> supportedExtensions = ['m4a'];

  /// Default bitrate presets offered in the compression sheet, in kbps.
  static const int highQualityBitrate = 192;
  static const int mediumQualityBitrate = 128;
  static const int lowQualityBitrate = 64;
  static const int voiceOptimizedBitrate = 32;

  static const Duration seekDebounce = Duration(milliseconds: 40);
  static const Duration waveformExtractionChunk = Duration(seconds: 1);
}
