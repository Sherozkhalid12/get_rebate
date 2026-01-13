import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/theme/app_theme.dart';

/// Professional Flutter Snackbar Helper
/// Shows snackbars from the top with smooth iOS-like animation
class SnackbarHelper {
  static OverlayEntry? _currentOverlay;

  /// Get the current context (from GetX or provided)
  /// Tries multiple methods to find a valid context with overlay
  static BuildContext? _getContext([BuildContext? context]) {
    // First try the provided context
    if (context != null) {
      try {
        // Check if this context has an overlay
        Overlay.of(context, rootOverlay: true);
        return context;
      } catch (e) {
        // Context doesn't have overlay, try to find Navigator context
        try {
          final navigator = Navigator.of(context, rootNavigator: true);
          if (navigator.context.mounted) {
            return navigator.context;
          }
        } catch (e2) {
          // Navigator also failed
        }
      }
    }
    
    // Try Get.context
    try {
      final getContext = Get.context;
      if (getContext != null) {
        try {
          Overlay.of(getContext, rootOverlay: true);
          return getContext;
        } catch (e) {
          // Try Navigator
          try {
            final navigator = Navigator.of(getContext, rootNavigator: true);
            if (navigator.context.mounted) {
              return navigator.context;
            }
          } catch (e2) {
            // Navigator also failed
          }
        }
      }
    } catch (e) {
      // Get.context also failed
    }
    
    return null;
  }

  /// Show a success snackbar (using app blue)
  static void showSuccess(
    String message, {
    BuildContext? context,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final ctx = _getContext(context);
    if (ctx == null) {
      if (kDebugMode) print('⚠️ SnackbarHelper: No context available');
      return;
    }
    _showSnackbar(
      ctx,
      message: message,
      title: title ?? 'Success',
      backgroundColor: AppTheme.primaryBlue,
      icon: Icons.check_circle_rounded,
      iconColor: AppTheme.white,
      duration: duration,
    );
  }

  /// Show an error snackbar (using darker blue for distinction)
  static void showError(
    String message, {
    BuildContext? context,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    final ctx = _getContext(context);
    if (ctx == null) {
      if (kDebugMode) print('⚠️ SnackbarHelper: No context available');
      return;
    }
    _showSnackbar(
      ctx,
      message: message,
      title: title ?? 'Error',
      backgroundColor: AppTheme.darkBlue,
      icon: Icons.error_rounded,
      iconColor: AppTheme.white,
      duration: duration,
    );
  }

  /// Show an info/information snackbar
  static void showInfo(
    String message, {
    BuildContext? context,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final ctx = _getContext(context);
    if (ctx == null) {
      if (kDebugMode) print('⚠️ SnackbarHelper: No context available');
      return;
    }
    _showSnackbar(
      ctx,
      message: message,
      title: title ?? 'Information',
      backgroundColor: AppTheme.primaryBlue,
      icon: Icons.info_rounded,
      iconColor: AppTheme.white,
      duration: duration,
    );
  }

  /// Show a warning snackbar (using light blue for distinction)
  static void showWarning(
    String message, {
    BuildContext? context,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final ctx = _getContext(context);
    if (ctx == null) {
      if (kDebugMode) print('⚠️ SnackbarHelper: No context available');
      return;
    }
    _showSnackbar(
      ctx,
      message: message,
      title: title ?? 'Notice',
      backgroundColor: AppTheme.lightBlue,
      icon: Icons.warning_rounded,
      iconColor: AppTheme.white,
      duration: duration,
    );
  }

  /// Show a validation snackbar (for form validation)
  static void showValidation(
    String message, {
    BuildContext? context,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    final ctx = _getContext(context);
    if (ctx == null) {
      if (kDebugMode) print('⚠️ SnackbarHelper: No context available');
      return;
    }
    _showSnackbar(
      ctx,
      message: message,
      title: title ?? 'Required Information',
      backgroundColor: AppTheme.primaryBlue,
      icon: Icons.info_rounded,
      iconColor: AppTheme.white,
      duration: duration,
    );
  }

  /// Internal method to show the snackbar from top with smooth iOS-like animation
  static void _showSnackbar(
    BuildContext context, {
    required String message,
    required String title,
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    required Duration duration,
  }) {
    try {
      // Dismiss any existing snackbar first
      _dismiss();

      // Try to get overlay - use rootOverlay for better compatibility
      OverlayState? overlay;
      try {
        overlay = Overlay.of(context, rootOverlay: true);
      } catch (e) {
        // Silently try without rootOverlay (don't log - this is expected in some cases)
        try {
          overlay = Overlay.of(context);
        } catch (e2) {
          // Try to find a better context via Navigator
          try {
            final navigator = Navigator.of(context, rootNavigator: true);
            if (navigator.context.mounted) {
              try {
                overlay = Overlay.of(navigator.context, rootOverlay: true);
              } catch (e3) {
                // Navigator context also doesn't have overlay, use fallback silently
                _showFallbackSnackbar(context, message, title, backgroundColor, icon, iconColor, duration);
                return;
              }
            } else {
              // Navigator context not mounted, use fallback silently
              _showFallbackSnackbar(context, message, title, backgroundColor, icon, iconColor, duration);
              return;
            }
          } catch (e3) {
            // Navigator also failed, use fallback silently
            _showFallbackSnackbar(context, message, title, backgroundColor, icon, iconColor, duration);
            return;
          }
        }
      }

      if (overlay == null) {
        if (kDebugMode) {
          print('⚠️ SnackbarHelper: Overlay is null, using fallback');
        }
        _showFallbackSnackbar(context, message, title, backgroundColor, icon, iconColor, duration);
        return;
      }

      // Calculate top position - below app bar
      final topPadding = MediaQuery.of(context).padding.top;
      final appBarHeight = AppBar().preferredSize.height;
      final topPosition = topPadding + appBarHeight + 8.0; // Position below app bar with small gap

      // Create overlay entry with smooth animation
      _currentOverlay = OverlayEntry(
        builder: (context) => _AnimatedSnackbar(
          message: message,
          title: title,
          backgroundColor: backgroundColor,
          icon: icon,
          iconColor: iconColor,
          topPosition: topPosition,
          onDismiss: _dismiss,
        ),
      );

      // Insert overlay
      overlay.insert(_currentOverlay!);

      // Auto dismiss after duration
      Future.delayed(duration, () {
        _dismiss();
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ SnackbarHelper: Error showing snackbar: $e');
        print('   Stack trace: $stackTrace');
      }
      // Fallback to ScaffoldMessenger
      _showFallbackSnackbar(context, message, title, backgroundColor, icon, iconColor, duration);
    }
  }

  /// Fallback to ScaffoldMessenger if overlay fails
  static void _showFallbackSnackbar(
    BuildContext context,
    String message,
    String title,
    Color backgroundColor,
    IconData icon,
    Color iconColor,
    Duration duration,
  ) {
    try {
      // Try to get ScaffoldMessenger from the context
      ScaffoldMessengerState? messenger;
      try {
        messenger = ScaffoldMessenger.of(context);
      } catch (e) {
        // Try to find via Navigator
        try {
          final navigator = Navigator.of(context, rootNavigator: true);
          if (navigator.context.mounted) {
            messenger = ScaffoldMessenger.of(navigator.context);
          }
        } catch (e2) {
          // Try Get.context as last resort
          try {
            final getContext = Get.context;
            if (getContext != null) {
              messenger = ScaffoldMessenger.of(getContext);
            }
          } catch (e3) {
            if (kDebugMode) {
              print('❌ SnackbarHelper: Could not find ScaffoldMessenger: $e3');
            }
            return;
          }
        }
      }
      
      if (messenger == null) {
        if (kDebugMode) {
          print('❌ SnackbarHelper: ScaffoldMessenger is null');
        }
        return;
      }
      
      // At this point, messenger is guaranteed to be non-null
      final nonNullMessenger = messenger;
      nonNullMessenger.clearSnackBars();
      
      // Get MediaQuery from the context (try multiple methods)
      BuildContext? queryContext = context;
      try {
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.context.mounted) {
          queryContext = navigator.context;
        }
      } catch (e) {
        // Use original context
      }
      
      double topPadding = 0;
      double screenHeight = 800;
      try {
        if (queryContext != null) {
          final mediaQuery = MediaQuery.of(queryContext);
          topPadding = mediaQuery.padding.top;
          screenHeight = mediaQuery.size.height;
        }
      } catch (e) {
        // Use defaults if MediaQuery fails
        topPadding = 24.0;
        screenHeight = 800;
      }
      
      final appBarHeight = AppBar().preferredSize.height;
      final topMargin = topPadding + appBarHeight + 8.0;
      
      nonNullMessenger.showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    nonNullMessenger.hideCurrentSnackBar();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.fixed,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          duration: duration,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
          dismissDirection: DismissDirection.horizontal,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ SnackbarHelper: Fallback also failed: $e');
      }
    }
  }

  /// Dismiss current snackbar
  static void _dismiss() {
    if (_currentOverlay != null) {
      try {
        _currentOverlay!.remove();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ SnackbarHelper: Error removing overlay: $e');
        }
      }
      _currentOverlay = null;
    }
  }

  /// Show a simple message snackbar (no title, just message)
  static void showMessage(
    String message, {
    BuildContext? context,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    final ctx = _getContext(context);
    if (ctx == null) {
      if (kDebugMode) print('⚠️ SnackbarHelper: No context available');
      return;
    }
    
    try {
      _dismiss();
      ScaffoldMessenger.of(ctx).clearSnackBars();
      
      final mediaQuery = MediaQuery.of(ctx);
      final topPadding = mediaQuery.padding.top;
      final screenHeight = mediaQuery.size.height;
      final appBarHeight = AppBar().preferredSize.height;
      final topMargin = topPadding + appBarHeight + 8.0;
      
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppTheme.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: AppTheme.primaryBlue,
          behavior: SnackBarBehavior.fixed,
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: duration,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          elevation: 6,
          dismissDirection: DismissDirection.horizontal,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ SnackbarHelper: Error showing message: $e');
      }
    }
  }
}

/// Animated snackbar widget with smooth iOS-like slide-down animation
class _AnimatedSnackbar extends StatefulWidget {
  final String message;
  final String? title;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final double topPosition;
  final VoidCallback onDismiss;

  const _AnimatedSnackbar({
    required this.message,
    this.title,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.topPosition,
    required this.onDismiss,
  });

  @override
  State<_AnimatedSnackbar> createState() => _AnimatedSnackbarState();
}

class _AnimatedSnackbarState extends State<_AnimatedSnackbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 250),
      vsync: this,
    );

    // Smooth iOS-like slide down animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2), // Start from above screen
      end: Offset.zero, // End at final position
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic, // iOS-like easing
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    // Start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    if (mounted) {
      await _controller.reverse();
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.topPosition,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: widget.title != null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title!,
                                style: const TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.message,
                                style: const TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            widget.message,
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _handleDismiss,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
