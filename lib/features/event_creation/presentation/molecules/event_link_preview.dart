import 'package:flutter/material.dart';

import '../event_creation_colors.dart';

/// Compact preview of the links attached to an event.
class EventLinkPreview extends StatelessWidget {
  const EventLinkPreview({
    super.key,
    required this.links,
    required this.onRemove,
  });

  final List<Uri> links;
  final ValueChanged<Uri> onRemove;

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) return const SizedBox.shrink();

    final additional = links.length - 1;
    final title =
        '${_siteName(links.first)}${additional > 0 ? ' +$additional' : ''}';

    return Semantics(
      button: true,
      label: 'Ver enlaces añadidos: $title',
      child: InkWell(
        onTap: () => _showLinks(context),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300, minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: EventCreationColors.muted,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: links.length > 1 ? 54 : 34,
                height: 34,
                child: Stack(
                  children: [
                    _LinkLogo(link: links.first),
                    if (links.length > 1)
                      Positioned(left: 20, child: _LinkLogo(link: links[1])),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(width: 5),
            ],
          ),
        ),
      ),
    );
  }

  void _showLinks(BuildContext context) {
    final visibleLinks = List<Uri>.of(links);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('Enlaces del evento'),
                subtitle: Text('Toca la X para quitar un enlace.'),
              ),
              for (final link in visibleLinks)
                ListTile(
                  leading: _LinkLogo(link: link),
                  title: Text(_siteName(link)),
                  subtitle: Text(
                    link.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: 'Quitar enlace de ${_siteName(link)}',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      onRemove(link);
                      setSheetState(() => visibleLinks.remove(link));
                      if (visibleLinks.isEmpty) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _siteName(Uri link) {
    final host = link.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    bool matches(String domain) => host == domain || host.endsWith('.$domain');
    if (matches('instagram.com')) return 'Instagram';
    if (matches('tuboleta.com')) return 'TuBoleta';
    if (matches('facebook.com') || matches('fb.com')) return 'Facebook';
    if (matches('youtube.com') || matches('youtu.be')) return 'YouTube';
    return host;
  }
}

class _LinkLogo extends StatelessWidget {
  const _LinkLogo({required this.link});

  final Uri link;

  @override
  Widget build(BuildContext context) {
    // The favicon endpoint returns the site's icon as a PNG. A globe remains
    // visible while it loads or if it cannot be retrieved.
    final favicon = Uri.https('www.google.com', '/s2/favicons', {
      'domain': link.host,
      'sz': '64',
    });
    const fallback = Icon(
      Icons.public_rounded,
      color: EventCreationColors.blue,
    );

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: EventCreationColors.muted, width: 1.5),
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Image.network(
            favicon.toString(),
            width: 22,
            height: 22,
            fit: BoxFit.contain,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                frame == null && !wasSynchronouslyLoaded ? fallback : child,
            errorBuilder: (context, error, stackTrace) => fallback,
          ),
        ),
      ),
    );
  }
}
