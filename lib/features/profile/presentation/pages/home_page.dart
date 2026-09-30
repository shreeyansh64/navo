import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navo/app_router.dart';
import 'package:navo/core/di/injection.dart';
import 'package:navo/features/auth/presentation/widgets/logout_button.dart';
import 'package:navo/features/profile/domain/model/student_profile.dart';
import 'package:navo/features/profile/presentation/bloc/home/home_bloc.dart';
import 'package:navo/features/profile/presentation/pages/complete_profile_page.dart';

/// Student home: just the entry QR.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeBloc>()..add(HomeLoadRequested()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Entry pass'), actions: const [LogoutButton()]),
      body: BlocConsumer<HomeBloc, HomeState>(
        listenWhen: (prev, cur) => cur.status == HomeStatus.profileIncomplete,
        listener: (context, state) => goTo(const CompleteProfilePage()),
        builder: (context, state) {
          final qr = state.qrDataUri;
          return RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<HomeBloc>()..add(HomeLoadRequested());
              await bloc.stream.firstWhere((s) => s.status != HomeStatus.loading);
            },
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: Center(
                    child: qr == null
                        ? _Placeholder(state: state)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _FlipCard(
                                front: _CardFace(
                                  child: Image.memory(
                                    qrBytes(qr),
                                    width: 240,
                                    height: 240,
                                    gaplessPlayback: true,
                                    filterQuality: FilterQuality.none,
                                  ),
                                ),
                                back: _CardFace(child: _TokenFace(token: state.profile?.gateToken)),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.swipe_rounded, size: 16, color: scheme.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Swipe to see your gate token',
                                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              if (state.profile != null) ...[
                                const SizedBox(height: 20),
                                Text(
                                  state.profile!.fullName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _Pill(icon: Icons.numbers_rounded, label: state.profile!.studentNumber),
                                      if (state.profile!.branch?.isNotEmpty ?? false)
                                        _Pill(icon: Icons.account_tree_outlined, label: state.profile!.branch!),
                                      _Pill(icon: Icons.groups_outlined, label: state.profile!.section),
                                    ],
                                  ),
                                ),
                              ],
                              if (state.status == HomeStatus.offline) ...[
                                const SizedBox(height: 16),
                                _Pill(
                                  icon: Icons.cloud_off_rounded,
                                  label: 'Offline · showing saved pass',
                                  background: scheme.surfaceContainerHighest,
                                  foreground: scheme.onSurfaceVariant,
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Card that flips around its Y axis when swiped horizontally.
class _FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  const _FlipCard({required this.front, required this.back});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  // Drag distance (px) that corresponds to a half turn.
  static const _dragExtent = 280.0;

  // Rotation angle in radians; a multiple of pi when at rest.
  late final AnimationController _angle = AnimationController.unbounded(vsync: this);

  @override
  void dispose() {
    _angle.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _angle.stop();
    _angle.value += d.delta.dx / _dragExtent * math.pi;
  }

  void _onDragEnd(DragEndDetails d) {
    final turns = _angle.value / math.pi;
    final velocity = d.velocity.pixelsPerSecond.dx;
    final double target;
    if (velocity.abs() > 300) {
      target = (velocity > 0 ? turns.ceilToDouble() : turns.floorToDouble());
    } else {
      target = turns.roundToDouble();
    }
    _angle.animateTo(target * math.pi, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: AnimatedBuilder(
        animation: _angle,
        builder: (context, _) {
          final angle = _angle.value;
          final showBack = math.cos(angle) < 0;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: widget.back,
                  )
                : widget.front,
          );
        },
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final Widget child;
  const _CardFace({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.16),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SizedBox(width: 240, height: 240, child: child),
    );
  }
}

/// Small rounded label with a leading icon, used for the profile details under the pass.
class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? background;
  final Color? foreground;
  const _Pill({required this.icon, required this.label, this.background, this.foreground});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = foreground ?? scheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? scheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
          ),
        ],
      ),
    );
  }
}

class _TokenFace extends StatelessWidget {
  final String? token;
  const _TokenFace({required this.token});

  @override
  Widget build(BuildContext context) {
    final assigned = token != null && token!.isNotEmpty;
    if (!assigned) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_number_outlined, size: 56, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(
            'No token assigned',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_rounded, size: 48, color: Colors.green.shade700),
        const SizedBox(height: 8),
        Text(
          'GATE TOKEN',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: Colors.green.shade800,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            '#$token',
            style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.green.shade900),
          ),
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  final HomeState state;
  const _Placeholder({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status != HomeStatus.failure) return const CircularProgressIndicator();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(state.error?.displayMessage ?? 'Could not load your pass.', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.read<HomeBloc>().add(HomeLoadRequested()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
