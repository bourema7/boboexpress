import 'package:flutter/material.dart';

class CartAnimationHelper {
  static void runAddToCartAnimation({
    required BuildContext context,
    required GlobalKey widgetKey,
    required GlobalKey cartKey,
    required String imageUrl,
    required Function onComplete,
  }) async {
    final RenderBox? widgetBox =
        widgetKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? cartBox =
        cartKey.currentContext?.findRenderObject() as RenderBox?;

    if (widgetBox == null || cartBox == null) {
      onComplete();
      return;
    }

    final Offset widgetOffset = widgetBox.localToGlobal(Offset.zero);
    final Offset cartOffset = cartBox.localToGlobal(Offset.zero);

    final OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _FlyingItem(
          startOffset: widgetOffset,
          endOffset: cartOffset,
          imageUrl: imageUrl,
          onComplete: () {
            entry.remove();
            onComplete();
          },
        );
      },
    );

    overlayState?.insert(entry);
  }
}

class _FlyingItem extends StatefulWidget {
  final Offset startOffset;
  final Offset endOffset;
  final String imageUrl;
  final VoidCallback onComplete;

  const _FlyingItem({
    required this.startOffset,
    required this.endOffset,
    required this.imageUrl,
    required this.onComplete,
  });

  @override
  State<_FlyingItem> createState() => _FlyingItemState();
}

class _FlyingItemState extends State<_FlyingItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = Tween<Offset>(
      begin: widget.startOffset,
      end: widget.endOffset,
    ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 0.2), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn));

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _animation.value.dx,
          top: _animation.value.dy,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: 1.0 - (_controller.value * 0.5),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2), blurRadius: 10)
                  ],
                  image: widget.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(widget.imageUrl),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: widget.imageUrl.isEmpty
                    ? const Icon(Icons.shopping_basket, color: Colors.orange)
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
