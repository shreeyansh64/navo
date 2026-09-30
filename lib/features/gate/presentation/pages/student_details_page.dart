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
  bool _isReassigning = false;
  bool _userClearedError = false;

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  /// Image URLs may be relative to the server root or contain host mismatch.
  String _absolute(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    final base = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000/api';
    final baseUri = Uri.parse(base);
    final rootUri = Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
    );

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      if (uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          (baseUri.host != 'localhost' && uri.host != baseUri.host)) {
        return uri.replace(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.hasPort ? baseUri.port : null,
        ).toString();
      }
      return trimmed;
    }

    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return rootUri.resolve(path).toString();
  }

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
          setState(() => _userClearedError = false);
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
          final tokenError = _userClearedError
              ? null
              : (e?.code == ApiErrorCode.gateTokenExists
                  ? e!.displayMessage
                  : e?.field('token_number') ?? e?.field('qr_token'));
          final hasAssignedToken = student.gateToken != null && student.gateToken!.isNotEmpty;

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
                        ClipOval(
                          child: Container(
                            width: 96,
                            height: 96,
                            color: scheme.primaryContainer,
                            child: (student.imageUrl != null && student.imageUrl!.trim().isNotEmpty)
                                ? Image.network(
                                    _absolute(student.imageUrl!),
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.person, size: 48, color: scheme.onPrimaryContainer);
                                    },
                                  )
                                : Icon(Icons.person, size: 48, color: scheme.onPrimaryContainer),
                          ),
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
                            _Detail(
                              label: 'Year',
                              value: switch (student.year) { '1' => '1st', '2' => '2nd', final y => y ?? '-' },
                            ),
                            _Detail(label: 'Section', value: student.section),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                if (hasAssignedToken && !_isReassigning) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade400, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_rounded, color: Colors.green.shade700, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'Token Already Assigned',
                              style: text.titleMedium?.copyWith(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '#${student.gateToken}',
                          style: text.headlineMedium?.copyWith(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This student is already checked in.',
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isReassigning = true;
                        _token.text = student.gateToken ?? '';
                        _userClearedError = false;
                      });
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Reassign / Change Token'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scan Next Student'),
                  ),
                ] else ...[
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _token,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      style: text.headlineSmall,
                      forceErrorText: tokenError,
                      onChanged: (_) {
                        if (!_userClearedError && tokenError != null) {
                          setState(() => _userClearedError = true);
                        }
                      },
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a token number' : null,
                      decoration: InputDecoration(
                        labelText: _isReassigning ? 'New token number' : 'Token number',
                        prefixIcon: const Icon(Icons.confirmation_number_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  LoadingButton(
                    label: _isReassigning ? 'Update token' : 'Assign token',
                    loading: state.status == GateStatus.assigning,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        setState(() => _userClearedError = false);
                        context.read<GateBloc>().add(GateTokenSubmitted(_token.text.trim()));
                      }
                    },
                  ),
                  if (_isReassigning) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isReassigning = false;
                          _userClearedError = false;
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ],
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
