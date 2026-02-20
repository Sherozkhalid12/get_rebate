import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Payment Web View Widget for Stripe Checkout
/// Displays the Stripe checkout URL in an in-app web view
/// and handles payment success/failure callbacks
class PaymentWebView extends StatefulWidget {
  final String checkoutUrl;
  final Function(bool success, String? message)? onPaymentComplete;

  const PaymentWebView({
    super.key,
    required this.checkoutUrl,
    this.onPaymentComplete,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _extractAndPrintSessionId();
    _initializeWebView();
  }

  void _extractAndPrintSessionId() {
    try {
      // Extract session ID from checkout URL
      // Stripe checkout URLs typically have format: https://checkout.stripe.com/c/pay/cs_test_... or cs_live_...
      final uri = Uri.parse(widget.checkoutUrl);
      final pathSegments = uri.pathSegments;
      
      // Session ID is typically in the path after /pay/
      // e.g., /c/pay/cs_test_a18zyHkYPoZF6Uz8VJ43dRYM9rX8xD7LJRa9kSoJCEgzRh0pwKRJlhTbQu
      String? sessionId;
      
      // Look for segment starting with 'cs_' (checkout session)
      for (final segment in pathSegments) {
        if (segment.startsWith('cs_')) {
          sessionId = segment;
          break;
        }
      }
      
      // If not found in path, try extracting from URL string directly
      if (sessionId == null) {
        final regex = RegExp(r'cs_(test|live)_[A-Za-z0-9]+');
        final match = regex.firstMatch(widget.checkoutUrl);
        if (match != null) {
          sessionId = match.group(0);
        }
      }
      
      if (kDebugMode) {
        if (sessionId != null) {
          print('💳 Stripe Checkout Session ID: $sessionId');
        } else {
          print('⚠️ Could not extract session ID from URL: ${widget.checkoutUrl}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error extracting session ID: $e');
      }
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            
            // Check URL immediately when navigation starts
            _checkPaymentStatus(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            
            // Check for payment success/failure indicators in the URL
            _checkPaymentStatus(url);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = error.description;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Check URL on navigation request as well
            _checkPaymentStatus(request.url);
            // Allow all navigation
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }


  void _checkPaymentStatus(String url) {
    if (url.isEmpty) return;
    
    if (kDebugMode) {
      print('🔍 Checking payment status for URL: $url');
    }

    // Check for Stripe success indicators
    // Stripe checkout success URLs typically contain these patterns:
    // - checkout.stripe.com with success parameters
    // - payment_intent_client_secret with success
    // - session_id with success status
    // - Redirects to success page after payment
    final lowerUrl = url.toLowerCase();
    
    // Check for success indicators (broader pattern matching)
    if (lowerUrl.contains('success') || 
        lowerUrl.contains('payment_success') ||
        lowerUrl.contains('payment_succeeded') ||
        (lowerUrl.contains('checkout.stripe.com') && 
         (lowerUrl.contains('session_id') || lowerUrl.contains('payment_intent')) &&
         !lowerUrl.contains('cancel') && !lowerUrl.contains('error'))) {
      // Payment successful - wait a bit to ensure page is fully loaded
      if (kDebugMode) {
        print('✅ Payment successful detected from URL');
      }
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          widget.onPaymentComplete?.call(true, 'Payment successful');
          Navigator.of(context).pop(true);
        }
      });
      return;
    }
    
    // Check for cancellation/failure indicators
    if (lowerUrl.contains('cancel') || 
        lowerUrl.contains('payment_failed') ||
        lowerUrl.contains('payment_declined') ||
        lowerUrl.contains('error') ||
        (lowerUrl.contains('checkout.stripe.com') && 
         (lowerUrl.contains('cancel') || lowerUrl.contains('error')))) {
      // Payment cancelled or failed
      if (kDebugMode) {
        print('❌ Payment cancelled/failed detected from URL');
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          widget.onPaymentComplete?.call(false, 'Payment cancelled');
          Navigator.of(context).pop(false);
        }
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.sp),
            decoration: BoxDecoration(
              color: AppTheme.lightGray.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.close_rounded,
              color: AppTheme.darkGray,
              size: 20.sp,
            ),
          ),
          onPressed: () {
            widget.onPaymentComplete?.call(false, 'Payment cancelled');
            Navigator.of(context).pop(false);
          },
          style: IconButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size(44.w, 44.h),
          ),
        ),
        title: Text(
          'Complete Payment',
          style: TextStyle(
            color: AppTheme.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            height: 1.h,
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            color: AppTheme.lightGray.withOpacity(0.5),
          ),
        ),
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            _buildErrorState(context)
          else
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
              child: WebViewWidget(controller: _controller),
            ),
          if (_isLoading && _errorMessage == null)
            _buildLoadingOverlay(context),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 32.w),
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: AppTheme.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.04),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpinKitFadingCircle(
                color: AppTheme.primaryBlue,
                size: 48.sp,
              ),
              SizedBox(height: 24.h),
              Text(
                'Loading secure payment',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.black,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Please wait while we connect to the payment provider',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppTheme.mediumGray,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(28.w),
          child: Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: Colors.red.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.sp),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 48.sp,
                    color: Colors.red.shade600,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Payment page unavailable',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  _errorMessage ?? 'Unable to load the payment form. Please check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.mediumGray,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 28.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                      _controller.reload();
                    },
                    icon: Icon(Icons.refresh_rounded, size: 20.sp),
                    label: Text(
                      'Try again',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
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

