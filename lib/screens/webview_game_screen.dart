import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.purple)
      ..loadRequest(Uri.parse(url));
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

