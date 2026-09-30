import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navo/core/di/injection.dart';
import 'package:navo/core/theme/app_theme.dart';
import 'package:navo/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:navo/features/auth/presentation/pages/forgot_otp_page.dart';
import 'package:navo/features/auth/presentation/pages/register_page.dart' show collegeDomain;

/// Step 1 of 3: ask for the email. The same bloc drives the OTP and reset pages.
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<ForgotPasswordBloc>(), child: const _ForgotView());
  }
}

class _ForgotView extends StatefulWidget {
  const _ForgotView();

  @override
  State<_ForgotView> createState() => _ForgotViewState();
}

class _ForgotViewState extends State<_ForgotView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
        listenWhen: (prev, cur) => prev.loading && !cur.loading,
        listener: (context, state) {
          if (ModalRoute.of(context)?.isCurrent != true) return;
          if (state.error != null) {
            showApiError(context, state.error!, inlineFields: {'email'});
          } else if (state.step == ForgotStep.otp) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<ForgotPasswordBloc>(),
                child: const ForgotOtpPage(),
              ),
            ));
          }
        },
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeader(
                  title: 'Forgot password?',
                  subtitle: "Enter your college email and we'll send you a reset code.",
                ),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  forceErrorText: state.error?.field('email'),
                  validator: (v) => (v ?? '').trim().toLowerCase().endsWith(collegeDomain)
                      ? null
                      : 'Only $collegeDomain emails are allowed',
                  decoration: const InputDecoration(
                    labelText: 'College email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 28),
                LoadingButton(
                  label: 'Send reset code',
                  loading: state.loading && state.step == ForgotStep.email,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      context.read<ForgotPasswordBloc>().add(ForgotPasswordRequested(_email.text.trim()));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
