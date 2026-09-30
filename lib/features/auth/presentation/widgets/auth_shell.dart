import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:navo/core/theme/app_theme.dart';

/// Layout shared by the auth screens: a gradient header carrying the page title,
/// the form below it, and an optional [footer] pinned to the bottom of the screen.
class AuthShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  const AuthShell({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            // At least one screen tall, so the footer sits at the bottom on short forms.
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(icon: icon, title: title, subtitle: subtitle),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, child) => Opacity(
                                opacity: v,
                                child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
                              ),
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (footer != null)
                    SafeArea(
                      top: false,
                      child: Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 16), child: footer),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Header({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final canPop = Navigator.of(context).canPop();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        // Own Material so the back button's ink is painted above the gradient.
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              const Positioned(top: -80, right: -60, child: _Bubble(size: 220)),
              const Positioned(bottom: -70, left: -50, child: _Bubble(size: 150)),
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (canPop)
                      const Padding(
                        padding: EdgeInsets.only(left: 8, top: 4),
                        child: BackButton(color: Colors.white),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, canPop ? 12 : 36, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                            ),
                            child: Icon(icon, size: 30, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            title,
                            style: text.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: text.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  const _Bubble({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)),
    );
  }
}

/// Credit line shown at the bottom of the login and register screens.
class DeveloperCredit extends StatelessWidget {
  const DeveloperCredit({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        text: 'Developed by ',
        children: [
          TextSpan(
            text: 'SDC-SI',
            style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
    );
  }
}
