import 'package:get_it/get_it.dart';
import 'package:navo/core/di/auth_di.dart';
import 'package:navo/core/di/core_di.dart';
import 'package:navo/core/di/gate_di.dart';
import 'package:navo/core/di/profile_di.dart';

final getIt = GetIt.instance;

void setup() {
  setupCore();
  setupAuth();
  setupProfile();
  setupGate();
}
