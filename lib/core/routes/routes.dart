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
        return ScaffoldWithNavBar(navigationShell: navigationShell, numberOfDestinations: numberOfDestinations);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: GlobalKey<NavigatorState>(),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const TasksPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: GlobalKey<NavigatorState>(),
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


