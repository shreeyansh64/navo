import 'package:flutter/material.dart';
import 'package:navo/core/api/api_error.dart';

class AppTheme {
  static const seed = Color(0xFF3949AB);

  /// Header gradient of the auth screens.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF283593), seed, Color(0xFF5160C2)],
  );

  static ThemeData get light {
    // The generated primary is a muted tone of the seed; use the seed itself so
    // buttons match the brand gradient.
    final scheme = ColorScheme.fromSeed(seedColor: seed).copyWith(primary: seed);
    final radius = BorderRadius.circular(14);
    OutlineInputBorder inputBorder([BorderSide side = BorderSide.none]) =>
        OutlineInputBorder(borderRadius: radius, borderSide: side);
    Color fieldIconColor(Set<WidgetState> states) {
      if (states.contains(WidgetState.error)) return scheme.error;
      if (states.contains(WidgetState.focused)) return scheme.primary;
      return scheme.onSurfaceVariant;
    }

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: scheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        prefixIconColor: WidgetStateColor.resolveWith(fieldIconColor),
        border: inputBorder(),
        enabledBorder: inputBorder(),
        focusedBorder: inputBorder(BorderSide(color: scheme.primary, width: 1.5)),
        errorBorder: inputBorder(BorderSide(color: scheme.error)),
        focusedErrorBorder: inputBorder(BorderSide(color: scheme.error, width: 1.5)),
        errorMaxLines: 3,
      ),
      // Height only: full-width buttons get their width from a stretched parent,
      // so buttons in dialogs and rows keep their natural size.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 54),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 54),
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    );
  }
}

void showSnack(BuildContext context, String message, {bool error = true}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? scheme.error : null,
    ));
}

/// Button that swaps its label for a spinner while [loading].
class LoadingButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const LoadingButton({super.key, required this.label, required this.loading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
          : Text(label),
    );
  }
}

/// Title + subtitle block used at the top of the auth and profile screens.
class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const PageHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(subtitle, style: t.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Shows [e] as a snackbar unless it is a validation error whose fields are
/// already rendered inline on the form (listed in [inlineFields]).
void showApiError(BuildContext context, ApiException e, {Set<String> inlineFields = const {}}) {
  final allInline = e.code == ApiErrorCode.validation &&
      e.fields.isNotEmpty &&
      e.fields.keys.every(inlineFields.contains);
  if (!allInline) showSnack(context, e.displayMessage);
}
