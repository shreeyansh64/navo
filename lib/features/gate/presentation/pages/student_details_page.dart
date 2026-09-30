import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:navo/core/api/api_error.dart';
import 'package:navo/core/theme/app_theme.dart';
import 'package:navo/features/gate/presentation/bloc/gate/gate_bloc.dart';

/// Shows the verified student and assigns a gate token.
/// Expects a [GateBloc] via BlocProvider.value; pops with the created GateEntry.
class StudentDetailsPage extends StatefulWidget {
  const StudentDetailsPage({super.key});

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _token = TextEditingController();

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  /// Image URLs may be relative to the server root.
  String _absolute(String url) => Uri.parse(dotenv.env['BASE_URL']!).resolve(url).toString();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Student')),
      body: BlocConsumer<GateBloc, GateState>(
        listenWhen: (prev, cur) => prev.status == GateStatus.assigning,
        listener: (context, state) {
          if (state.status == GateStatus.assigned) return Navigator.of(context).pop(state.entry);
          final e = state.error;
          if (e == null) return;
          switch (e.code) {
            case ApiErrorCode.gateTokenExists || ApiErrorCode.validation:
              break; // shown under the token field
            case ApiErrorCode.invalidQr:
              showSnack(context, e.displayMessage);
              Navigator.of(context).pop();
            default:
              showSnack(context, e.displayMessage);
          }
        },
        // After a reset the student is gone while this page animates out; keep the last frame.
        buildWhen: (prev, cur) => cur.student != null,
        builder: (context, state) {
          final student = state.student!;
          final e = state.error;
          final tokenError = e?.code == ApiErrorCode.gateTokenExists
              ? e!.displayMessage
              : e?.field('token_number') ?? e?.field('qr_token');
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: scheme.primaryContainer,
                          foregroundImage: student.imageUrl == null || student.imageUrl!.isEmpty
                              ? null
                              : NetworkImage(_absolute(student.imageUrl!)),
                          child: Icon(Icons.person, size: 48, color: scheme.onPrimaryContainer),
                        ),
                        const SizedBox(height: 16),
                        Text(student.fullName,
                            textAlign: TextAlign.center,
                            style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        if (student.email != null)
                          Text(student.email!, style: TextStyle(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _Detail(label: 'Student no.', value: student.studentNumber),
                            _Detail(label: 'Branch', value: student.branch ?? '-'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _Detail(label: 'Year', value: student.year ?? '-'),
                            _Detail(label: 'Section', value: student.section),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _token,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    style: text.headlineSmall,
                    forceErrorText: tokenError,
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a token number' : null,
                    decoration: const InputDecoration(
                      labelText: 'Token number',
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                LoadingButton(
                  label: 'Assign token',
                  loading: state.status == GateStatus.assigning,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      context.read<GateBloc>().add(GateTokenSubmitted(_token.text.trim()));
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;
  const _Detail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: t.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
