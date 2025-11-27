import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../controllers/auth_controller.dart';
import '../controllers/game_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

/// In-app WebView host for the Spell Daily game.
///
/// Loads `https://app.spelldaily.com/?code={loginCode}` and relies on the
/// web app to update Firestore when the game is completed.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameController _gameController = Get.find<GameController>();
  final AuthController _authController = Get.find<AuthController>();

  WebViewController? _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final code = _authController.loginCode ?? '';
    if (code.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar('Error', 'Login code is missing');
        Get.back();
      });
      return;
    }

    final url = 'https://app.spelldaily.com/?code=$code';

    try {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) {
                setState(() => _isLoading = true);
              }
            },
            onPageFinished: (_) {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
            onWebResourceError: (error) {
              if (mounted) {
                setState(() => _isLoading = false);
                Get.snackbar('Error', 'Failed to load game: ${error.description}');
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(url));
    } catch (e) {
      if (mounted) {
        Get.snackbar('Error', 'Failed to initialize WebView: ${e.toString()}');
        Get.back();
      }
    }
  }

  Future<bool> _handleWillPop() async {
    await _gameController.onWebViewClosed();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _gameController.onWebViewClosed();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text('Spell Daily Game', style: AppTextStyles.headline),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              await _gameController.onWebViewClosed();
            },
          ),
        ),
        body: _webViewController != null
            ? Stack(
                children: [
                  WebViewWidget(controller: _webViewController!),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.orange),
                    ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              ),
      ),
    );
  }
}


