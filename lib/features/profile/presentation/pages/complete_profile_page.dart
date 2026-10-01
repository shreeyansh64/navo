import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:navo/app_router.dart';
import 'package:navo/core/api/api_error.dart';
import 'package:navo/core/di/injection.dart';
import 'package:navo/core/storage/token_storage.dart';
import 'package:navo/core/theme/app_theme.dart';
import 'package:navo/features/auth/presentation/widgets/logout_button.dart';
import 'package:navo/features/profile/presentation/bloc/complete_profile/complete_profile_bloc.dart';
import 'package:navo/features/profile/presentation/pages/home_page.dart';

final firstYearSections = [for (int i = 1; i <= 25; i++) 'S$i'];
const secondYearSections = ['1', '2', '3'];

/// Dropdown label -> value sent to the API.
const years = {'1st year': '1st year', '2nd year': '2nd year'};

/// Must match the backend's BranchValidator.
const branches = [
  'ME',
  'ECE',
  'EE',
  'CSE',
  'CSE(HINDI)',
  'AIML',
  'CSE(DS)',
  'CSE(AIML)',
  'IT',
  'CS',
  'CS IT',
  'CE',
  'MBA',
  'MCA',
];

class CompleteProfilePage extends StatelessWidget {
  const CompleteProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<CompleteProfileBloc>(), child: const _CompleteProfileView());
  }
}

class _CompleteProfileView extends StatefulWidget {
  const _CompleteProfileView();

  @override
  State<_CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<_CompleteProfileView> {
  static const _maxImageBytes = 5 * 1024 * 1024;
  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _studentNumber = TextEditingController();
  final _emailFuture = getIt<TokenStorage>().email;
  String? _userEmail;
  String? _section;
  String? _year;
  String? _branch;
  File? _image;
  bool _imageMissing = false;

  @override
  void initState() {
    super.initState();
    getIt<TokenStorage>().email.then((email) {
      if (mounted) setState(() => _userEmail = email);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _studentNumber.dispose();
    super.dispose();
  }

  List<String> get _availableSections {
    if (_year == '1st year') return firstYearSections;
    if (_year == '2nd year') return secondYearSections;
    return const [];
  }

  /// Camera only: the photo has to be taken on the spot, not picked from the gallery.
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final ext = picked.path.split('.').last.toLowerCase();
    if (!_imageExtensions.contains(ext)) {
      return showSnack(context, 'Please pick a JPEG, PNG or WebP image.');
    }
    if (await picked.length() > _maxImageBytes) {
      if (mounted) showSnack(context, 'Image must be 5 MB or smaller.');
      return;
    }
    setState(() {
      _image = File(picked.path);
      _imageMissing = false;
    });
  }

  void _submit() {
    final formValid = _formKey.currentState!.validate();
    setState(() => _imageMissing = _image == null);
    if (!formValid || _image == null) return;
    context.read<CompleteProfileBloc>().add(CompleteProfileSubmitted(
          fullName: _name.text.trim(),
          section: _section!,
          year: _year!,
          branch: _branch!,
          studentNumber: _studentNumber.text.trim(),
          image: _image!,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(actions: const [LogoutButton()]),
      body: BlocConsumer<CompleteProfileBloc, CompleteProfileState>(
        listener: (context, state) {
          if (state.done) goTo(const HomePage());
          // student_number_taken is shown inline under the student number field.
          if (state.error != null && state.error!.code != ApiErrorCode.studentNumberTaken) {
            showApiError(context, state.error!,
                inlineFields: {'full_name', 'section', 'year', 'branch', 'student_number', 'image'});
          }
        },
        builder: (context, state) {
          final err = state.error;
          final imageError = err?.field('image') ?? (_imageMissing ? 'Take a photo to continue' : null);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PageHeader(
                    title: 'Complete your profile',
                    subtitle: 'These details are shown at the gate when your pass is scanned.',
                  ),
                  Center(
                    child: GestureDetector(
                      onTap: state.loading ? null : _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: scheme.primaryContainer,
                            backgroundImage: _image != null ? FileImage(_image!) : null,
                            child: _image == null
                                ? Icon(Icons.person_outline, size: 48, color: scheme.onPrimaryContainer)
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              radius: 17,
                              backgroundColor: scheme.primary,
                              child: Icon(Icons.camera_alt_rounded, size: 18, color: scheme.onPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    imageError ?? (_image == null ? 'Tap to take a photo' : 'Tap to retake'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: imageError != null ? scheme.error : scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<String?>(
                    future: _emailFuture,
                    builder: (context, snap) => snap.data == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TextFormField(
                              initialValue: snap.data,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                            ),
                          ),
                  ),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    forceErrorText: err?.field('full_name'),
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your full name' : null,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _studentNumber,
                    textInputAction: TextInputAction.next,
                    forceErrorText: err?.code == ApiErrorCode.studentNumberTaken
                        ? err!.displayMessage
                        : err?.field('student_number'),
                    validator: (v) {
                      final val = (v ?? '').trim();
                      if (val.isEmpty) return 'Enter your student number';
                      if (!RegExp(r'^(25|26)\d{5,6}$').hasMatch(val)) {
                        return 'Student number must be 7-8 digits starting with 25 or 26';
                      }
                      if (_userEmail != null && _userEmail!.isNotEmpty) {
                        final email = _userEmail!.toLowerCase();
                        if (email.endsWith('@akgec.ac.in') && !email.contains(val.toLowerCase())) {
                          return 'Email must contain the student number: $val';
                        }
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Student number',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _year,
                    forceErrorText: err?.field('year'),
                    validator: (v) => v == null ? 'Select your year' : null,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    items: [
                      for (final y in years.entries) DropdownMenuItem(value: y.value, child: Text(y.key)),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _year = v;
                        if (!_availableSections.contains(_section)) {
                          _section = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _branch,
                    menuMaxHeight: 320,
                    forceErrorText: err?.field('branch'),
                    validator: (v) => v == null ? 'Select your branch' : null,
                    decoration: const InputDecoration(
                      labelText: 'Branch',
                      prefixIcon: Icon(Icons.account_tree_outlined),
                    ),
                    items: [for (final b in branches) DropdownMenuItem(value: b, child: Text(b))],
                    onChanged: (v) => setState(() => _branch = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey('section_$_year'),
                    initialValue: _section,
                    menuMaxHeight: 320,
                    forceErrorText: err?.field('section'),
                    validator: (v) => v == null ? 'Select your section' : null,
                    decoration: InputDecoration(
                      labelText: 'Section',
                      hintText: _year == null ? 'Select year first' : null,
                      prefixIcon: const Icon(Icons.groups_outlined),
                    ),
                    items: [
                      for (final s in _availableSections) DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: _year == null ? null : (v) => setState(() => _section = v),
                  ),
                  const SizedBox(height: 28),
                  LoadingButton(label: 'Get my pass', loading: state.loading, onPressed: _submit),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
