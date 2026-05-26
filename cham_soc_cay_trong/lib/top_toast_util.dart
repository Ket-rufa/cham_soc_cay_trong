import 'package:flutter/material.dart';

class TopToast {
  static void show(
    BuildContext context,
    String message, {
    Color backgroundColor = const Color(0xFF25BB57),
    IconData icon = Icons.check_circle_outline,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _TopToastWidget(
          message: message,
          backgroundColor: backgroundColor,
          icon: icon,
          onDismiss: () {
            overlayEntry.remove();
          },
          duration: duration,
        );
      },
    );

    overlayState.insert(overlayEntry);
  }
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onDismiss;
  final Duration duration;

  const _TopToastWidget({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.backgroundColor.withValues(alpha: 0.24),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.backgroundColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.backgroundColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Color(0xFF1B2A22),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
