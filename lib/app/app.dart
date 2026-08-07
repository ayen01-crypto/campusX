import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import 'router.dart';

final routerProvider = Provider((ref) => buildRouter());

class CampusXApp extends ConsumerWidget {
  const CampusXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(campusProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'CampusX',
      debugShowCheckedModeBanner: false,
      theme: campusTheme(Brightness.light),
      darkTheme: campusTheme(Brightness.dark),
      themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
