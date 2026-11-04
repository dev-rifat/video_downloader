import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/formatters.dart';
import '../bloc/downloads_bloc.dart';
import '../bloc/link_bloc.dart';
import 'platform_icon.dart';
import 'thumbnail.dart';

/// Shows analysis result: thumbnail, title and resolution picker.
class VideoPreviewSection extends StatelessWidget {
  const VideoPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LinkBloc, LinkState>(
      buildWhen: (a, b) =>
          a.status != b.status || a.info != b.info || a.selected != b.selected,
      builder: (context, state) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: switch (state.status) {
          LinkStatus.initial => const _Hint(),
          LinkStatus.loading => const _Loading(),
          LinkStatus.failure => _ErrorCard(state.error ?? 'Something went wrong'),
          LinkStatus.loaded => _Preview(state),
        },
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Tip: In Facebook, YouTube or any app tap Share → Downloader '
        'to open the video here directly.',
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard(this.message);
  final String message;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: ListTile(
        leading: Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
        title: Text(message, style: TextStyle(color: scheme.onErrorContainer)),
        trailing: IconButton(
          icon: const Icon(Icons.refresh_rounded),
          color: scheme.onErrorContainer,
          onPressed: () {
            final bloc = context.read<LinkBloc>();
            bloc.add(LinkSubmitted(bloc.state.input));
          },
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview(this.state);
  final LinkState state;

  @override
  Widget build(BuildContext context) {
    final info = state.info!;
    final text = Theme.of(context).textTheme;
    final meta = [
      if (info.author != null) info.author!,
      if (info.duration != null) Formatters.duration(info.duration),
    ].join(' • ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Thumbnail(info.thumbnailUrl, width: 120),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PlatformBadge(info.platform),
                      const SizedBox(height: 6),
                      Text(info.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(meta, style: text.bodySmall, maxLines: 1),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Resolution', style: text.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in info.formats)
                  ChoiceChip(
                    label: Text(f.sizeBytes == null
                        ? f.label
                        : '${f.label} · ${Formatters.bytes(f.sizeBytes)}'),
                    selected: f == state.selected,
                    onSelected: (_) =>
                        context.read<LinkBloc>().add(FormatSelected(f)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.download_rounded),
                label: Text('Download ${state.selected?.label ?? ''}'),
                onPressed: state.selected == null
                    ? null
                    : () {
                        context
                            .read<DownloadsBloc>()
                            .add(DownloadRequested(info, state.selected!));
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(const SnackBar(
                            content: Text('Download started'),
                            duration: Duration(seconds: 2),
                          ));
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
