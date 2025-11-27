import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Login', style: AppTextStyles.headline),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter your permanent login code', style: AppTextStyles.body),
              const SizedBox(height: 24),
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF1E0042),
                  border: OutlineInputBorder(),
                  hintText: 'ARU123',
                ),
                style: AppTextStyles.codeInput,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Code required' : null,
              ),
              const SizedBox(height: 32),
              Obx(
                () => ElevatedButton(
                  onPressed: _authController.isLoading.value
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _authController.loginWithCode(_codeController.text);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: _authController.isLoading.value
                      ? const CircularProgressIndicator(color: AppColors.white)
                      : Text('Continue', style: AppTextStyles.buttonStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
