import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:navo/app_router.dart';
import 'package:navo/core/api/api_client.dart';
import 'package:navo/core/di/injection.dart';
import 'package:navo/core/theme/app_theme.dart';
import 'package:navo/features/auth/domain/repository/auth_repository.dart';
import 'package:navo/features/auth/presentation/pages/login_page.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  setup();

  getIt<ApiClient>().onSessionExpired = () {
    goTo(const LoginPage());
    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Your session expired. Please log in again.')),
    );
  };

  final role = await getIt<AuthRepository>().currentRole();
  runApp(Navo(home: startPage(role)));
}

class Navo extends StatelessWidget {
  final Widget home;
  const Navo({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: home,
    );
  }
}
