import 'package:flutter/material.dart';
import 'package:navo/app_router.dart';
import 'package:navo/core/di/injection.dart';
import 'package:navo/features/auth/domain/repository/auth_repository.dart';
import 'package:navo/features/auth/presentation/pages/login_page.dart';

/// No logout endpoint exists: dropping the stored tokens is the logout.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok != true) return;
    await getIt<AuthRepository>().logout();
    goTo(const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Log out',
      icon: const Icon(Icons.logout_rounded),
      onPressed: () => _logout(context),
    );
  }
}
