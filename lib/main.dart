import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/app_state.dart';
import 'core/app_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = AppStorage();
  final initialState = await storage.loadState();

  runApp(
    ProviderScope(
      overrides: [
        appStorageProvider.overrideWithValue(storage),
        initialCampusStateProvider.overrideWithValue(initialState),
      ],
      child: const CampusXApp(),
    ),
  );
}
