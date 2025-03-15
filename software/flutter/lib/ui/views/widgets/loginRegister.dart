import 'package:flutter/material.dart';

import 'customButton.dart';

class LoginRegisterWidget extends StatelessWidget {
  final String loginText;
  final String registerText;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  const LoginRegisterWidget({
    super.key,
    required this.onLogin,
    required this.onRegister,
    required this.loginText,
    required this.registerText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomButton(
          onTap: onLogin,
          text: "Login",
          isLoading: false,
        ),
        CustomButton(
          onTap: onRegister,
          text: "Register",
          isLoading: false,
        ),
      ],
    );
  }
}
