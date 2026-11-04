import 'package:flutter/material.dart';

import '../../domain/entities/video_platform.dart';

class PlatformBadge extends StatelessWidget {
  const PlatformBadge(this.platform, {super.key});
  final VideoPlatform platform;

  static const _colors = {
    VideoPlatform.youtube: Color(0xFFFF0033),
    VideoPlatform.facebook: Color(0xFF1877F2),
    VideoPlatform.instagram: Color(0xFFE1306C),
    VideoPlatform.tiktok: Color(0xFF111111),
    VideoPlatform.twitter: Color(0xFF111111),
    VideoPlatform.other: Color(0xFF64748B),
  };

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: _colors[platform],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            platform.label,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      );
}
