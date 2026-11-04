import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/server_settings.dart';
import 'settings_cubit.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => BlocProvider.value(
          value: context.read<SettingsCubit>(),
          child: const SettingsSheet(),
        ),
      );

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late final _endpoint =
      TextEditingController(text: context.read<SettingsCubit>().state.endpoint);
  late final _key =
      TextEditingController(text: context.read<SettingsCubit>().state.apiKey);
  String? _error;

  @override
  void dispose() {
    _endpoint.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final err = await context
        .read<SettingsCubit>()
        .save(ServerSettings(endpoint: _endpoint.text, apiKey: _key.text));
    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Universal server', style: text.titleLarge),
          const SizedBox(height: 6),
          Text(
            'YouTube (360p) and public Facebook videos work without a server. '
            'Add a cobalt-compatible server to unlock Instagram, TikTok, X and '
            'HD resolutions.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _endpoint,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'Server URL',
              hintText: 'https://your-cobalt-instance.com',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _key,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'API key (optional)'),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}
