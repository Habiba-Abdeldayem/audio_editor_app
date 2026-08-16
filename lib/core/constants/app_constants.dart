/// App-wide constants that don't belong to any single layer.
class AppConstants {
  AppConstants._();

  static const List<String> supportedExtensions = ['m4a'];

  /// Default bitrate presets offered in the compression sheet, in kbps.
  static const int veryHighQualityBitrate = 320;
  static const int highQualityBitrate = 192;
  static const int mediumQualityBitrate = 128;
  static const int lowQualityBitrate = 64;
  static const int veryLowQualityBitrate = 32;
  static const int voiceOptimizedBitrate = 24;
  static const int ultraLowQualityBitrate = 16;

  /// Target file size for compression (in bytes)
  static const int targetFileSize16MB = 16 * 1024 * 1024; // 16 MB
  static const int targetFileSize8MB = 8 * 1024 * 1024; // 8 MB
  static const int targetFileSize4MB = 4 * 1024 * 1024; // 4 MB

  static const Duration seekDebounce = Duration(milliseconds: 40);
  static const Duration waveformExtractionChunk = Duration(seconds: 1);
}
