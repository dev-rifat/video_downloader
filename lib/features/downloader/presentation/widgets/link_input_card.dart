import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/link_bloc.dart';

class LinkInputCard extends StatefulWidget {
  const LinkInputCard({super.key});

  @override
  State<LinkInputCard> createState() => _LinkInputCardState();
}

class _LinkInputCardState extends State<LinkInputCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit([String? value]) {
    FocusScope.of(context).unfocus();
    context.read<LinkBloc>().add(LinkSubmitted(value ?? _controller.text));
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    _controller.text = text;
    _submit(text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LinkBloc, LinkState>(
      // Keep the field in sync when a link arrives via the share sheet.
      listenWhen: (a, b) => a.input != b.input,
      listener: (_, s) {
        if (_controller.text != s.input) _controller.text = s.input;
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                onSubmitted: _submit,
                decoration: InputDecoration(
                  hintText: 'Paste video link',
                  prefixIcon: const Icon(Icons.link_rounded),
                  suffixIcon: ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (_, v, _) => v.text.isEmpty
                        ? IconButton(
                            tooltip: 'Paste',
                            icon: const Icon(Icons.content_paste_rounded),
                            onPressed: _paste,
                          )
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _controller.clear();
                              context.read<LinkBloc>().add(const LinkCleared());
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              BlocSelector<LinkBloc, LinkState, bool>(
                selector: (s) => s.status == LinkStatus.loading,
                builder: (_, loading) => FilledButton.icon(
                  onPressed: loading ? null : _submit,
                  icon: loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search_rounded),
                  label: Text(loading ? 'Fetching…' : 'Fetch video'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
