import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: AppTheme.black,
            size: 24.sp,
          ),
          onPressed: () {
            widget.onPaymentComplete?.call(false, 'Payment cancelled');
            Navigator.of(context).pop(false);
          },
        ),
        title: Text(
          'Complete Payment',
          style: TextStyle(
            color: AppTheme.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            height: 1.h,
            color: AppTheme.lightGray.withOpacity(0.3),
          ),
        ),
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64.sp,
                      color: Colors.red,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Error loading payment page',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.black,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _errorMessage ?? 'Unknown error',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                        _controller.reload();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading && _errorMessage == null)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Loading payment page...',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

