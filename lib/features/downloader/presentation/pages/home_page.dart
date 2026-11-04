import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../settings/presentation/settings_sheet.dart';
import '../bloc/downloads_bloc.dart';
import '../widgets/download_tile.dart';
import '../widgets/link_input_card.dart';
import '../widgets/video_preview_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloader'),
        actions: [
          IconButton(
            tooltip: 'Gallery',
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: () =>
                context.read<DownloadsBloc>().add(const GalleryOpened()),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => SettingsSheet.show(context),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  LinkInputCard(),
                  SizedBox(height: 12),
                  VideoPreviewSection(),
                  SizedBox(height: 20),
                ]),
              ),
            ),
            BlocSelector<DownloadsBloc, DownloadsState, List<String>>(
              selector: (s) => s.ids,
              builder: (context, ids) {
                if (ids.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: ids.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => i == 0
                        ? Text('Downloads',
                            style: Theme.of(context).textTheme.titleMedium)
                        : DownloadTile(key: ValueKey(ids[i - 1]), id: ids[i - 1]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
