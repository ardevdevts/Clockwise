import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/tasks/tasks_page.dart';
import '../../features/habits/habits_page.dart';
import '../scaffold_with_navbar.dart';

int numberOfDestinations = 2;

final appRouter = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return SafeArea(
          child: ScaffoldWithNavBar(navigationShell: navigationShell, numberOfDestinations: numberOfDestinations),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const TasksPage(),
            ),
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
      ],
    ),
  ],
);


