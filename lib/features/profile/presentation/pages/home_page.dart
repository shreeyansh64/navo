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
                              if (state.profile?.gateToken != null && state.profile!.gateToken!.isNotEmpty) ...[
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.green.shade300, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded, color: Colors.green.shade700, size: 28),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Gate Token Assigned',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          Text(
                                            'Token #${state.profile!.gateToken}',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: scheme.shadow.withValues(alpha: 0.12),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Image.memory(
                                  qrBytes(qr),
                                  width: 240,
                                  height: 240,
                                  gaplessPlayback: true,
                                  filterQuality: FilterQuality.none,
                                ),
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
                                const SizedBox(height: 4),
                                Text(
                                  '${state.profile!.studentNumber} • ${state.profile!.branch ?? ''} (${state.profile!.section})',
                                  style: TextStyle(color: scheme.onSurfaceVariant),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              if (state.status == HomeStatus.offline) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Offline · showing saved pass',
                                  style: TextStyle(color: scheme.onSurfaceVariant),
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
          const Icon(Icons.cloud_off_rounded, size: 48),
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
