import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

enum ToastType { success, error, info }

class Toast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
  }) {
    // Create an OverlayEntry
    final OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
      ),
    );

    // Insert the OverlayEntry into the Overlay
    Overlay.of(context).insert(overlayEntry);

    // Remove the toast after a few seconds
    Timer(const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;

  const _ToastWidget({required this.message, required this.type});

  @override
  _ToastWidgetState createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // --- FIX: Adjusted animation to be less dramatic ---
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5), // Start animation closer to the top bar
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map<ToastType, dynamic> toastDetails = {
      ToastType.success: {
        'icon': Icons.check_circle_outline_rounded,
        'color': Colors.green.shade400,
      },
      ToastType.error: {
        'icon': Icons.error_outline_rounded,
        'color': Colors.red.shade400,
      },
      ToastType.info: {
        'icon': Icons.info_outline_rounded,
        'color': Colors.blue.shade400,
      },
    };

    return Positioned(
      // --- FIX: Positioned the toast 96px from the top. ---
      // This is the height of the TopNavigationBar (80px) + a 16px margin.
      top: 96.0,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withAlpha(60), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        toastDetails[widget.type]['icon'],
                        color: toastDetails[widget.type]['color'],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}