import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/download_task.dart';
import '../bloc/downloads_bloc.dart';
import 'thumbnail.dart';

/// Rebuilds only when *its own* task changes.
class DownloadTile extends StatelessWidget {
  const DownloadTile({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DownloadsBloc, DownloadsState, DownloadTask?>(
      selector: (s) => s.byId[id],
      builder: (context, task) {
        if (task == null) return const SizedBox.shrink();
        return RepaintBoundary(child: _TileBody(task));
      },
    );
  }
}

class _TileBody extends StatelessWidget {
  const _TileBody(this.task);
  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<DownloadsBloc>();

    final (String subtitle, Color? color) = switch (task.status) {
      DownloadStatus.queued => ('Waiting…', null),
      DownloadStatus.downloading => (_progressText(task), null),
      DownloadStatus.saving => ('Saving to gallery…', null),
      DownloadStatus.completed => ('Saved to gallery', Colors.green),
      DownloadStatus.failed => (task.error ?? 'Failed', scheme.error),
      DownloadStatus.canceled => ('Canceled', scheme.outline),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
        child: Row(
          children: [
            Thumbnail(task.thumbnailUrl, width: 84),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '${task.platform.label} • ${task.qualityLabel}',
                    style: text.labelSmall?.copyWith(color: scheme.outline),
                  ),
                  if (task.status.isActive) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        minHeight: 5,
                        value: task.status == DownloadStatus.downloading
                            ? task.progress
                            : null,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: color)),
                ],
              ),
            ),
            if (task.status.isActive)
              IconButton(
                tooltip: 'Cancel',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => bloc.add(DownloadCanceled(task.id)),
              )
            else if (task.status == DownloadStatus.completed)
              IconButton(
                tooltip: 'Open gallery',
                icon: const Icon(Icons.photo_library_outlined),
                onPressed: () => bloc.add(const GalleryOpened()),
              )
            else
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => bloc.add(DownloadRemoved(task.id)),
              ),
          ],
        ),
      ),
    );
  }

  static String _progressText(DownloadTask t) {
    final p = t.progress;
    final parts = <String>[
      if (p != null) '${(p * 100).toStringAsFixed(0)}%',
      if (t.total != null)
        '${Formatters.bytes(t.received)} / ${Formatters.bytes(t.total)}'
      else
        Formatters.bytes(t.received),
      if (t.bytesPerSecond > 0) '${Formatters.bytes(t.bytesPerSecond)}/s',
    ];
    return parts.where((s) => s.isNotEmpty).join(' • ');
  }
}
