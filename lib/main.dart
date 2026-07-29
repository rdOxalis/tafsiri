import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/database/sqflite_desktop.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initSqfliteForDesktop();
  runApp(const ProviderScope(child: TafsiriApp()));
}
