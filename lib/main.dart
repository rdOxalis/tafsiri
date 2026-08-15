import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/database/sqflite_desktop.dart';
import 'core/licenses.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initSqfliteForDesktop();
  registerExtraLicenses();
  runApp(const ProviderScope(child: TafsiriApp()));
}
