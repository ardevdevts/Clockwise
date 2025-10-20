import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/tasks/tasks_page.dart';
import '../../features/habits/habits_page.dart';
import '../../features/notes/notes_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/welcome_page.dart';
import '../scaffold_with_navbar.dart';

int numberOfDestinations = 3;

final appRouter = GoRouter(
  initialLocation: '/welcome',
  routes: [
    // Welcome/Splash route
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),
    // Login route
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    // Main app routes with bottom navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return SafeArea(
          child: ScaffoldWithNavBar(
            navigationShell: navigationShell,
            numberOfDestinations: numberOfDestinations,
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const TasksPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/habits',
              builder: (context, state) => const HabitsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notes',
              builder: (context, state) => const NotesPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
