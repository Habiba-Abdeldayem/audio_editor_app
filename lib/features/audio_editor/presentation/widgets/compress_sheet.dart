import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/compression_option.dart';

class CompressSheet extends StatelessWidget {
  final int originalSizeBytes;
  final List<CompressionOption> options;
  final bool isLoadingOptions;
  final bool isCompressing;
  final bool isError;
  final String? errorMessage;
  final String? resultPath;
  final double? progress;
  final ValueChanged<int> onOptionSelected;

  const CompressSheet({
    super.key,
    required this.originalSizeBytes,
    required this.options,
    required this.isLoadingOptions,
    required this.isCompressing,
    required this.onOptionSelected,
    this.isError = false,
    this.errorMessage,
    this.resultPath,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.compressAudio,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                l10n.currentSize(Formatters.fileSize(originalSizeBytes)),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            if (isLoadingOptions)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (isCompressing)
               Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 6,
                            value: progress,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                          Text(
                            progress != null
                                ? '${(progress! * 100).round()}%'
                                : '',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.compressing),
                  ],
                ),
              )
            else if (resultPath != null)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(l10n.compressionComplete),
                subtitle: Text(resultPath!.split('/').last),
              )
            else if (isError)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage ?? l10n.compressionFailed,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.chooseSizeToRetry,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    final filtered = originalSizeBytes > 0
                        ? options
                            .where(
                                (o) => o.estimatedBytes < originalSizeBytes)
                            .toList()
                        : options;
                    if (filtered.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            l10n.fileAlreadySmall,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = filtered[index];
                        final savingPercent =
                            (100 - (option.estimatedBytes / originalSizeBytes * 100))
                                .clamp(0, 100)
                                .round();
                        final subtitle = savingPercent > 0
                            ? '${Formatters.fileSize(originalSizeBytes)} → '
                                '~${Formatters.fileSize(option.estimatedBytes)} '
                                '($savingPercent% ${l10n.smaller})'
                            : '${Formatters.fileSize(originalSizeBytes)} → '
                                '~${Formatters.fileSize(option.estimatedBytes)}';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(option.label),
                          subtitle: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(subtitle),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              onOptionSelected(option.bitrateKbps),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
