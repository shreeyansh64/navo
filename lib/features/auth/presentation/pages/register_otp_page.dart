import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navo/app_router.dart';
import 'package:navo/features/auth/presentation/bloc/register/register_bloc.dart';
import 'package:navo/features/auth/presentation/widgets/otp_view.dart';
import 'package:navo/features/profile/presentation/pages/complete_profile_page.dart';

/// Expects a [RegisterBloc] from the register page via BlocProvider.value.
class RegisterOtpPage extends StatelessWidget {
  const RegisterOtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterBloc, RegisterState>(
      listenWhen: (prev, cur) => prev.step != cur.step && cur.step == RegisterStep.done,
      listener: (context, state) => goTo(const CompleteProfilePage()),
      builder: (context, state) => OtpView(
        email: state.email,
        timer: state.otp,
        loading: state.loading,
        errorText: state.error?.displayMessage,
        onSubmit: (otp) => context.read<RegisterBloc>().add(RegisterOtpSubmitted(otp)),
        onResend: () => context.read<RegisterBloc>().add(RegisterOtpResent()),
      ),
    );
  }
}
