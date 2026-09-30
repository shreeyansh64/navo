import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? serverError;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;

  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.serverError,
    this.validator,
    this.textInputAction = TextInputAction.done,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      textInputAction: widget.textInputAction,
      forceErrorText: widget.serverError,
      validator: widget.validator ?? (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
    );
  }
}

String? validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Enter your password';
  if (v.length < 8 || v.length > 16) return 'Password must be between 8 and 16 characters';
  if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Password must contain at least one uppercase letter';
  if (!RegExp(r'[a-z]').hasMatch(v)) return 'Password must contain at least one lowercase letter';
  if (!RegExp(r'[0-9]').hasMatch(v)) return 'Password must contain at least one number';
  return null;
}
