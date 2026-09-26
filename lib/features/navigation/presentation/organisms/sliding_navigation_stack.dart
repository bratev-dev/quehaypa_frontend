import 'package:flutter/material.dart';

/// Keeps tab state while sliding opaque screens without exposing the background.
class SlidingNavigationStack extends StatefulWidget {
  const SlidingNavigationStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<SlidingNavigationStack> createState() => _SlidingNavigationStackState();
}

class _SlidingNavigationStackState extends State<SlidingNavigationStack> {
  int? previousIndex;

  @override
  void didUpdateWidget(SlidingNavigationStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      previousIndex = MediaQuery.disableAnimationsOf(context)
          ? null
          : oldWidget.index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (var index = 0; index < widget.children.length; index++)
            Offstage(
              offstage:
                  index != widget.index &&
                  (reduceMotion || index != previousIndex),
              child: IgnorePointer(
                ignoring: index != widget.index,
                child: ExcludeSemantics(
                  excluding: index != widget.index,
                  child: TickerMode(
                    enabled: index == widget.index || previousIndex != null,
                    child: AnimatedSlide(
                      offset: index == widget.index
                          ? Offset.zero
                          : Offset(index < widget.index ? -1 : 1, 0),
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      onEnd: reduceMotion
                          ? null
                          : () {
                              if (mounted &&
                                  index == widget.index &&
                                  previousIndex != null) {
                                setState(() => previousIndex = null);
                              }
                            },
                      child: ColoredBox(
                        color: const Color(0xFF121212),
                        child: widget.children[index],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
