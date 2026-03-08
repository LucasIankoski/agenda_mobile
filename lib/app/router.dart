import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/classrooms/presentation/pages/classrooms_page.dart';
import '../features/students/presentation/pages/students_page.dart';
import '../features/students/presentation/pages/student_detail_page.dart';
import '../features/classrooms/presentation/pages/classroom_detail_page.dart';
import '../features/diaries/presentation/pages/diary_detail_page.dart';
import '../features/diaries/presentation/pages/diary_new_page.dart';
import '../features/home/home_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(ref.watch(authControllerProvider.notifier).stream),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isSplash = location == '/splash';
      final isAuthRoute = location.startsWith('/auth');

      final authState = ref.read(authControllerProvider);
      final isLoading = authState.isLoading;
      final authSession = authState.valueOrNull;
      final isLogged = authSession?.isAuthenticated == true;
      final isParent = isLogged && authSession?.isParent == true;

      if (isSplash) {
        if (isLoading) {
          return null;
        }
        if (!isLogged) return '/auth/login';
        return isParent ? '/students' : '/';
      }

      if (isLoading) {
        return '/splash';
      }

      if (!isLogged && !isAuthRoute) {
        return '/auth/login';
      }

      if (isLogged && isAuthRoute) {
        return isParent ? '/students' : '/';
      }

      if (isParent) {
        final canAccessStudentList = location == '/students';
        final canAccessStudentDetail = location.startsWith('/students/');
        final canAccessDiaryDetail = location.startsWith('/diaries/') && location != '/diaries/new';
        final allowedRoute = canAccessStudentList || canAccessStudentDetail || canAccessDiaryDetail;
        if (!allowedRoute) {
          return '/students';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(child: ClassroomsPage()),
          ),
          GoRoute(
            path: '/students',
            pageBuilder: (context, state) => const NoTransitionPage(child: StudentsPage()),
          ),
          GoRoute(
            path: '/students/:id',
            builder: (context, state) => StudentDetailPage(studentId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/classrooms/:id',
            builder: (context, state) => ClassroomDetailPage(classroomId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/diaries/new',
            builder: (context, state) {
              final studentId = state.uri.queryParameters['studentId'];
              return DiaryNewPage(prefilledStudentId: studentId);
            },
          ),
          GoRoute(
            path: '/diaries/:id',
            builder: (context, state) => DiaryDetailPage(diaryId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});

/// Adaptador de stream para o GoRouter atualizar redirects.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
