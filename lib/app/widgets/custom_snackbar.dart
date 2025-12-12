import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/theme/app_theme.dart';

class CustomSnackbar {
  static OverlayEntry? _currentOverlay;

  /// Show a validation/info snackbar with app theme blue color
  static void showValidation(String message) {
    _show(
      message: message,
      title: 'Missing Information',
      backgroundColor: AppTheme.primaryBlue,
      icon: Icons.info_outline,
      duration: const Duration(seconds: 4),
    );
  }

  /// Show a success snackbar with app theme green color
  static void showSuccess(String title, String message) {
    _show(
      message: message,
      title: title,
      backgroundColor: AppTheme.lightGreen,
      icon: Icons.check_circle,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show an error snackbar with red color
  static void showError(String message) {
    _show(
      message: message,
      title: 'Error',
      backgroundColor: Colors.red.shade600,
      icon: Icons.error_outline,
      duration: const Duration(seconds: 3),
    );
  }

  static void _show({
    required String message,
    required String title,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    debugPrint('📢 CustomSnackbar._show called: $title - $message');
    
    // Dismiss any existing snackbar
    dismiss();

    // Use WidgetsBinding to ensure we're in a valid frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get context from GetX navigator key
      final context = Get.key.currentContext ?? Get.context;
      if (context == null) {
        debugPrint('❌ No context available');
        return;
      }

      _showOverlay(context, message, title, backgroundColor, icon, duration);
    });
  }

  static void _showOverlay(
    BuildContext context,
    String message,
    String title,
    Color backgroundColor,
    IconData icon,
    Duration duration,
  ) {
    // Get overlay with proper error handling
    OverlayState? overlay;
    try {
      overlay = Overlay.of(context, rootOverlay: true);
    } catch (e) {
      debugPrint('❌ Error getting overlay: $e');
      // Try without rootOverlay
      try {
        overlay = Overlay.of(context);
      } catch (e2) {
        debugPrint('❌ Error getting overlay (fallback): $e2');
        // Last resort: use GetX snackbar
        _showGetXFallback(title, message, backgroundColor);
        return;
      }
    }

    if (overlay == null) {
      debugPrint('❌ No overlay available, using GetX fallback');
      _showGetXFallback(title, message, backgroundColor);
      return;
    }

    // Create overlay entry
    _currentOverlay = OverlayEntry(
      builder: (context) => _SnackbarOverlay(
        message: message,
        title: title,
        backgroundColor: backgroundColor,
        icon: icon,
        onDismiss: dismiss,
      ),
    );

    // Insert overlay
    try {
      overlay.insert(_currentOverlay!);
      debugPrint('✅ Snackbar overlay inserted');
    } catch (e) {
      debugPrint('❌ Error inserting overlay: $e');
      _currentOverlay = null;
      return;
    }

    // Auto dismiss after duration
    Future.delayed(duration, () {
      dismiss();
    });
  }

  static void dismiss() {
    if (_currentOverlay != null) {
      _currentOverlay!.remove();
      _currentOverlay = null;
      debugPrint('✅ Snackbar dismissed');
    }
  }

  static void _showGetXFallback(String title, String message, Color backgroundColor) {
    try {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: backgroundColor,
        colorText: AppTheme.white,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
        snackStyle: SnackStyle.FLOATING,
      );
      debugPrint('✅ GetX fallback snackbar shown');
    } catch (e) {
      debugPrint('❌ GetX fallback also failed: $e');
    }
  }
}

class _SnackbarOverlay extends StatefulWidget {
  final String message;
  final String title;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onDismiss;

  const _SnackbarOverlay({
    required this.message,
    required this.title,
    required this.backgroundColor,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_SnackbarOverlay> createState() => _SnackbarOverlayState();
}

class _SnackbarOverlayState extends State<_SnackbarOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start from bottom
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: false,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: widget.backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            widget.icon,
                            color: AppTheme.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    color: AppTheme.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.message,
                                  style: const TextStyle(
                                    color: AppTheme.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppTheme.white,
                              size: 20,
                            ),
                            onPressed: _handleDismiss,
                          ),
                        ],
                      ),
                    ),
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
