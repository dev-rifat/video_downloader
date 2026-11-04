import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injector.dart';
import 'core/platform/share_intent_service.dart';
import 'core/theme/app_theme.dart';
import 'features/downloader/presentation/bloc/downloads_bloc.dart';
import 'features/downloader/presentation/bloc/link_bloc.dart';
import 'features/downloader/presentation/pages/home_page.dart';
import 'features/settings/presentation/settings_cubit.dart';

class DownloaderApp extends StatelessWidget {
  const DownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<LinkBloc>()),
        BlocProvider(
            create: (_) => sl<DownloadsBloc>()..add(const DownloadsStarted())),
        BlocProvider(create: (_) => sl<SettingsCubit>()),
      ],
      child: MaterialApp(
        title: 'Downloader',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const _ShareListener(child: HomePage()),
      ),
    );
  }
}

/// Feeds links shared from other apps (Facebook, YouTube, …) into [LinkBloc].
class _ShareListener extends StatefulWidget {
  const _ShareListener({required this.child});
  final Widget child;

  @override
  State<_ShareListener> createState() => _ShareListenerState();
}

class _ShareListenerState extends State<_ShareListener> {
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    final share = sl<ShareIntentService>();
    share.initialText().then(_handle);
    _sub = share.textStream.listen(_handle);
  }

  void _handle(String? text) {
    if (text == null || text.trim().isEmpty || !mounted) return;
    context.read<LinkBloc>().add(LinkSubmitted(text));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
