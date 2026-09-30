import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navo/core/di/injection.dart';
import 'package:navo/core/theme/app_theme.dart';
import 'package:navo/features/auth/presentation/bloc/register/register_bloc.dart';
import 'package:navo/features/auth/presentation/pages/register_otp_page.dart';
import 'package:navo/features/auth/presentation/widgets/auth_shell.dart';
import 'package:navo/features/auth/presentation/widgets/password_field.dart';

const collegeDomain = '@akgec.ac.in';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<RegisterBloc>(), child: const _RegisterView());
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<RegisterBloc>().add(RegisterSubmitted(
          email: _email.text.trim(),
          password: _password.text,
          confirmPassword: _confirm.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterBloc, RegisterState>(
      // React only when a request finishes and this page is on top (not the OTP page).
      listenWhen: (prev, cur) => prev.loading && !cur.loading,
      listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent != true) return;
        if (state.step == RegisterStep.otp) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<RegisterBloc>(),
              child: const RegisterOtpPage(),
            ),
          ));
        } else if (state.error != null) {
          showApiError(context, state.error!,
              inlineFields: {'email', 'password', 'confirm_password'});
        }
      },
      builder: (context, state) {
        final onForm = state.step == RegisterStep.form;
        final err = onForm ? state.error : null;
        return AuthShell(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Create account',
          subtitle: 'Use your college email ($collegeDomain)',
          footer: const DeveloperCredit(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  forceErrorText: err?.field('email'),
                  validator: (v) => (v ?? '').trim().toLowerCase().endsWith(collegeDomain)
                      ? null
                      : 'Only $collegeDomain emails are allowed',
                  decoration: const InputDecoration(
                    labelText: 'College email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _password,
                  textInputAction: TextInputAction.next,
                  serverError: err?.field('password'),
                  validator: validatePassword,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirm,
                  label: 'Confirm password',
                  serverError: err?.field('confirm_password'),
                  validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 28),
                LoadingButton(
                  label: 'Send verification code',
                  loading: state.loading && onForm,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Log in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
