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

const sections = ['S-1', 'S-2', 'S-3', 'S-4', 'S-5', 'S-6', 'S-7', 'S-8', 'S-9', 'S-10', 'S-11',
  'S-12', 'S-13', 'S-14', 'S-15', 'S-16', 'S-17', 'S-18', 'S-19', 'S-20', 'S-21', 'S-22', 'S-23',
  'S-24', 'S-25', 'S-26', 'S-27'];

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
  final _email = getIt<TokenStorage>().email;
  String? _section;
  File? _image;

  @override
  void dispose() {
    _name.dispose();
    _studentNumber.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1080, imageQuality: 85);
    if (picked == null || !mounted) return;

    final ext = picked.path.split('.').last.toLowerCase();
    if (!_imageExtensions.contains(ext)) {
      return showSnack(context, 'Please pick a JPEG, PNG or WebP image.');
    }
    if (await picked.length() > _maxImageBytes) {
      if (mounted) showSnack(context, 'Image must be 5 MB or smaller.');
      return;
    }
    setState(() => _image = File(picked.path));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CompleteProfileBloc>().add(CompleteProfileSubmitted(
          fullName: _name.text.trim(),
          section: _section!,
          studentNumber: _studentNumber.text.trim(),
          image: _image,
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
                inlineFields: {'full_name', 'section', 'student_number', 'image'});
          }
        },
        builder: (context, state) {
          final err = state.error;
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
                    err?.field('image') ?? 'Photo (optional)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: err?.field('image') != null ? scheme.error : scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<String?>(
                    future: _email,
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
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your student number' : null,
                    decoration: const InputDecoration(
                      labelText: 'Student number',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _section,
                    menuMaxHeight: 320,
                    forceErrorText: err?.field('section'),
                    validator: (v) => v == null ? 'Select your section' : null,
                    decoration: const InputDecoration(
                      labelText: 'Section',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    items: [for (final s in sections) DropdownMenuItem(value: s, child: Text(s))],
                    onChanged: (v) => setState(() => _section = v),
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
