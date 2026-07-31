import 'package:flutter/material.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/compression_option.dart';

class CompressSheet extends StatelessWidget {
  final int originalSizeBytes;
  final List<CompressionOption> options;
  final bool isLoadingOptions;
  final bool isCompressing;
  final String? resultPath;
  final ValueChanged<int> onOptionSelected;

  const CompressSheet({
    super.key,
    required this.originalSizeBytes,
    required this.options,
    required this.isLoadingOptions,
    required this.isCompressing,
    required this.onOptionSelected,
    this.resultPath,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compress audio', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Current size: ${Formatters.fileSize(originalSizeBytes)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (isLoadingOptions)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (isCompressing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Compressing…'),
                  ],
                ),
              )
            else if (resultPath != null)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Compression complete'),
                subtitle: Text(resultPath!.split('/').last),
              )
            else
              ...options.map((option) {
                final savingPercent = originalSizeBytes == 0
                    ? 0
                    : (100 -
                            (option.estimatedBytes / originalSizeBytes * 100))
                        .clamp(0, 100)
                        .round();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(option.label),
                  subtitle: Text(
                    '${Formatters.fileSize(originalSizeBytes)} → '
                    '~${Formatters.fileSize(option.estimatedBytes)} '
                    '(~$savingPercent% smaller)',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onOptionSelected(option.bitrateKbps),
                );
              }),
          ],
        ),
      ),
    );
  }
}
