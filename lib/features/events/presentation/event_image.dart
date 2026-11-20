import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config_provider.dart';

class EventImage extends ConsumerWidget {
  const EventImage({super.key, this.url, this.height = 180, this.placeholder});
  final String? url;
  final double height;
  final Widget? placeholder;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = placeholder ?? SizedBox(height: height);
    if (url == null || url!.isEmpty) return fallback;
    final absolute = Uri.parse(ref.watch(appConfigProvider).apiBaseUrl)
        .resolve(url!)
        .toString();
    return Image.network(
      absolute,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stack) => fallback,
    );
  }
}
