import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../app_colors.dart';
import '../controllers/auth_controller.dart';
import '../controllers/game_controller.dart';
import '../routes/app_routes.dart';

class WebviewGameScreen extends StatefulWidget {
  const WebviewGameScreen({super.key});

  @override
  State<WebviewGameScreen> createState() => _WebviewGameScreenState();
}

class _WebviewGameScreenState extends State<WebviewGameScreen> {
  final GameController _gameController = Get.find<GameController>();
  final AuthController _authController = Get.find<AuthController>();
  late final WebViewController _webViewController;
  String? _loginCode;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _loginCode = args?['loginCode'] ?? _authController.storedLoginCode;
    if (_loginCode == null) {
      Get.offAllNamed(Routes.login);
      return;
    }
    final url = 'https://app.spelldaily.com/?code=$_loginCode';
    
    // Set user agent to mimic Chrome desktop browser
    const userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    
    // Create platform-specific WebViewController
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    
    _webViewController = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white) // White background like normal browser
      ..setUserAgent(userAgent)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // Page started loading
          },
          onPageFinished: (String url) async {
            // Inject JavaScript to mask WebView detection
            await _injectStealthScript();
            // Also inject immediately using DOM ready check
            await _injectOnDOMReady();
          },
          onWebResourceError: (WebResourceError error) {
            // Handle errors if needed
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'StealthChannel',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('Stealth: ${message.message}');
        },
      );
    
    // Configure Android-specific settings for full browser experience
    if (_webViewController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      final androidController =
          _webViewController.platform as AndroidWebViewController;

      // Enable media playback (audio/video) - allows sound to play
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }
    
    _webViewController.loadRequest(Uri.parse(url));
  }

  /// Injects JavaScript to mask WebView detection
  Future<void> _injectStealthScript() async {
    const script = '''
      (function() {
        // Remove webdriver flag
        Object.defineProperty(navigator, 'webdriver', {
          get: () => undefined,
        });
        
        // Add chrome object
        if (!window.chrome) {
          window.chrome = {};
        }
        window.chrome.runtime = {};
        
        // Override plugins
        Object.defineProperty(navigator, 'plugins', {
          get: () => [1, 2, 3, 4, 5],
        });
        
        // Override languages
        Object.defineProperty(navigator, 'languages', {
          get: () => ['en-US', 'en'],
        });
        
        // Override permissions
        if (window.navigator.permissions && window.navigator.permissions.query) {
          const originalQuery = window.navigator.permissions.query;
          window.navigator.permissions.query = (parameters) => (
            parameters.name === 'notifications' ?
              Promise.resolve({ state: Notification.permission }) :
              originalQuery(parameters)
          );
        }
        
        // Override platform
        Object.defineProperty(navigator, 'platform', {
          get: () => 'Win32',
        });
        
        // Override hardwareConcurrency
        Object.defineProperty(navigator, 'hardwareConcurrency', {
          get: () => 8,
        });
        
        // Override deviceMemory
        Object.defineProperty(navigator, 'deviceMemory', {
          get: () => 8,
        });
        
        // Remove automation indicators
        delete navigator.__proto__.webdriver;
      })();
    ''';
    
    try {
      await _webViewController.runJavaScript(script);
      debugPrint('Stealth script injected successfully');
    } catch (e) {
      debugPrint('Failed to inject stealth script: $e');
    }
  }

  /// Injects script when DOM is ready
  Future<void> _injectOnDOMReady() async {
    const script = '''
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
          // Re-apply stealth after DOM loads
          Object.defineProperty(navigator, 'webdriver', {
            get: () => undefined,
          });
        });
      }
    ''';
    
    try {
      await _webViewController.runJavaScript(script);
    } catch (e) {
      debugPrint('Failed to inject DOM ready script: $e');
    }
  }

  Future<bool> _onWillPop() async {
    await _gameController.onWebViewClosed();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loginCode == null) {
      return const SizedBox.shrink();
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Spell Daily',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _gameController.onWebViewClosed(),
            ),
          ],
        ),
        body: WebViewWidget(controller: _webViewController),
      ),
    );
  }
}

