import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navo/core/api/api_error.dart';
import 'package:navo/core/theme/app_theme.dart';
import 'package:navo/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:navo/features/auth/presentation/widgets/password_field.dart';

/// Step 3 of 3. Expects the [ForgotPasswordBloc] via BlocProvider.value.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  static const _otpErrors = {
    ApiErrorCode.invalidOtp,
    ApiErrorCode.otpExpired,
    ApiErrorCode.otpAttemptLimit,
  };

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ForgotPasswordBloc>().add(
          PasswordResetSubmitted(password: _password.text, confirmPassword: _confirm.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
        listenWhen: (prev, cur) => prev.loading && !cur.loading,
        listener: (context, state) {
          final e = state.error;
          if (state.step == ForgotStep.done) {
            showSnack(context, 'Password changed. Please log in.', error: false);
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (e != null) {
            showApiError(context, e, inlineFields: {'password', 'confirm_password'});
            // The code is no longer usable, so send the user back to request a new one.
            if (_otpErrors.contains(e.code)) Navigator.of(context).pop();
          }
        },
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeader(title: 'New password', subtitle: 'Choose a password with at least 8 characters.'),
                PasswordField(
                  controller: _password,
                  label: 'New password',
                  textInputAction: TextInputAction.next,
                  serverError: state.error?.field('password'),
                  validator: validatePassword,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirm,
                  label: 'Confirm password',
                  serverError: state.error?.field('confirm_password'),
                  validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 28),
                LoadingButton(label: 'Reset password', loading: state.loading, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
