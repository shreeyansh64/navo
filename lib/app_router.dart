import 'package:flutter/material.dart';
import 'package:navo/features/auth/domain/model/auth_models.dart';
import 'package:navo/features/auth/presentation/pages/login_page.dart';
import 'package:navo/features/gate/presentation/pages/scanner_page.dart';
import 'package:navo/features/profile/presentation/pages/complete_profile_page.dart';
import 'package:navo/features/profile/presentation/pages/home_page.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// First screen on app launch, from the stored session role (null = logged out).
Widget startPage(UserRole? role) => switch (role) {
      null => const LoginPage(),
      UserRole.admin => const ScannerPage(),
      UserRole.student => const HomePage(),
    };

Widget pageAfterLogin(LoginResult r) {
  if (r.role == UserRole.admin) return const ScannerPage();
  return r.hasProfile ? const HomePage() : const CompleteProfilePage();
}

/// Replaces the whole stack with [page].
void goTo(Widget page) {
  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => page),
    (_) => false,
  );
}
