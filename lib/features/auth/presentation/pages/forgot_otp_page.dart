import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navo/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:navo/features/auth/presentation/pages/reset_password_page.dart';
import 'package:navo/features/auth/presentation/widgets/otp_view.dart';

/// Step 2 of 3. Expects the [ForgotPasswordBloc] via BlocProvider.value.
class ForgotOtpPage extends StatelessWidget {
  const ForgotOtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listenWhen: (prev, cur) => prev.loading && !cur.loading,
      listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent != true) return;
        if (state.error == null && state.step == ForgotStep.reset) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<ForgotPasswordBloc>(),
              child: const ResetPasswordPage(),
            ),
          ));
        }
      },
      builder: (context, state) => OtpView(
        email: state.email,
        timer: state.otp,
        loading: state.loading,
        errorText: state.error?.displayMessage,
        onSubmit: (otp) => context.read<ForgotPasswordBloc>().add(ForgotOtpSubmitted(otp)),
        onResend: () => context.read<ForgotPasswordBloc>().add(ForgotOtpResent()),
      ),
    );
  }
}
