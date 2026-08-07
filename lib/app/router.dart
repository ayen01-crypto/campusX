import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/models.dart';
import '../screens/auth_flow.dart';
import '../screens/catalog_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/main_shell.dart';
import '../screens/profile_pages.dart';
import '../screens/splash_screen.dart';

GoRouter buildRouter() => GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
        GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
        GoRoute(path: '/university', builder: (context, state) => const UniversityScreen()),
        GoRoute(path: '/interests', builder: (context, state) => const InterestsScreen()),
        GoRoute(path: '/app', builder: (context, state) => const MainShell()),
        GoRoute(path: '/saved', builder: (context, state) => const SavedScreen()),
        GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
        GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        GoRoute(
          path: '/catalog/:kind',
          builder: (context, state) {
            final value = state.pathParameters['kind'];
            final kind = ListingKind.values.firstWhere(
              (item) => item.name == value,
              orElse: () => ListingKind.marketplace,
            );
            return CatalogScreen(kind: kind);
          },
        ),
        GoRoute(
          path: '/listing/:id',
          builder: (context, state) => ListingDetailScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/chat/:id',
          builder: (context, state) => ChatScreen(conversationId: state.pathParameters['id']!),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('CampusX')),
        body: Center(child: Text(state.error?.toString() ?? 'Page not found')),
      ),
    );
