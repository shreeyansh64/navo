import 'package:flutter/material.dart';
import 'package:navo/app_router.dart';
import 'package:navo/core/di/injection.dart';
import 'package:navo/features/auth/domain/repository/auth_repository.dart';
import 'package:navo/features/auth/presentation/pages/login_page.dart';

/// No logout endpoint exists: dropping the stored tokens is the logout.
class LogoutButton extends StatelessWidget {
  /// Icon colour; defaults to the surrounding icon button theme.
  final Color? color;

  const LogoutButton({super.key, this.color});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.logout_rounded, color: scheme.error),
          title: const Text('Log out?'),
          content: const Text(
            "You'll need to log in again to see your pass.",
            textAlign: TextAlign.center,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Log out'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    await getIt<AuthRepository>().logout();
    goTo(const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Log out',
      color: color,
      icon: const Icon(Icons.logout_rounded),
      onPressed: () => _logout(context),
    );
  }
}
