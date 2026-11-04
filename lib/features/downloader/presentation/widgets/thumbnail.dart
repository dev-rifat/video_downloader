import 'package:flutter/material.dart';

/// Network thumbnail decoded at display size (saves memory vs full-res decode).
class Thumbnail extends StatelessWidget {
  const Thumbnail(this.url, {super.key, required this.width, this.height});
  final String? url;
  final double width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final h = height ?? width * 9 / 16;
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.movie_outlined, color: scheme.outline),
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: width,
        height: h,
        child: url == null
            ? placeholder
            : Image.network(
                url!,
                fit: BoxFit.cover,
                cacheWidth: (width * dpr).round(),
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
