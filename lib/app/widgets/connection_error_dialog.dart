import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/theme/app_theme.dart';

/// Professional dialog shown when connection/timeout/internet errors occur.
/// Uses modern design with clear messaging and retry action.
class ConnectionErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ConnectionErrorDialog({
    super.key,
    this.title = 'Connection Issue',
    this.message =
        'We\'re unable to connect right now. Please check your internet connection and try again.',
    this.onRetry,
    this.onDismiss,
  });

  /// Shows the connection error dialog safely (handles overlay timing).
  /// Uses addPostFrameCallback to avoid "No Overlay widget found" when called from onInit.
  static void show({
    String? title,
    String? message,
    VoidCallback? onRetry,
  }) {
    void tryShow([int attempt = 0]) {
      if (Get.overlayContext == null) {
        if (attempt < 5) {
          WidgetsBinding.instance.addPostFrameCallback((_) => tryShow(attempt + 1));
        }
        return;
      }
      if (Get.isDialogOpen == true) return; // Avoid stacking dialogs
      Get.dialog(
        ConnectionErrorDialog(
          title: title ?? 'Connection Issue',
          message: message ??
              'We\'re unable to connect right now. Please check your internet connection and try again.',
          onRetry: onRetry,
        ),
        barrierDismissible: false,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => tryShow());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                    fontSize: 20,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mediumGray,
                    height: 1.5,
                    fontSize: 15,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tips: Check Wi‑Fi or mobile data, try moving to a better signal area, or restart your router.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mediumGray.withOpacity(0.9),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                if (onRetry != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                        onRetry?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppTheme.primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ),
                if (onRetry != null) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      onDismiss?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(onRetry != null ? 'OK' : 'Got it'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
