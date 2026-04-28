import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/classrooms/presentation/pages/classrooms_page.dart';
import '../features/students/presentation/pages/students_page.dart';
import '../features/students/presentation/pages/student_detail_page.dart';
import '../features/students/presentation/pages/student_diaries_page.dart';
import '../features/students/presentation/pages/student_gallery_page.dart';
import '../features/students/presentation/pages/student_notes_page.dart';
import '../features/classrooms/presentation/pages/classroom_detail_page.dart';
import '../features/diaries/presentation/pages/diary_detail_page.dart';
import '../features/diaries/presentation/pages/diary_new_page.dart';
import '../features/home/home_shell.dart';
import '../features/platform/presentation/pages/schools_page.dart';
import '../features/users/presentation/pages/user_detail_page.dart';
import '../features/users/presentation/pages/users_page.dart';

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
      final isAdmin = isLogged && authSession?.isAdmin == true;
      final isSuperAdmin = isLogged && authSession?.isSuperAdmin == true;

      if (isSplash) {
        if (isLoading) {
          return null;
        }
        if (!isLogged) return '/auth/login';
        if (isSuperAdmin) return '/platform/schools';
        return isParent ? '/students' : '/';
      }

      if (isLoading) {
        return '/splash';
      }

      if (!isLogged && !isAuthRoute) {
        return '/auth/login';
      }

      if (isLogged && isAuthRoute) {
        if (isSuperAdmin) return '/platform/schools';
        return isParent ? '/students' : '/';
      }

      if (!isAdmin && location.startsWith('/users')) {
        return isParent ? '/students' : '/';
      }

      if (!isSuperAdmin && location.startsWith('/platform')) {
        return isParent ? '/students' : '/';
      }

      if (isSuperAdmin && !location.startsWith('/platform')) {
        return '/platform/schools';
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
            path: '/users',
            pageBuilder: (context, state) => const NoTransitionPage(child: UsersPage()),
          ),
          GoRoute(
            path: '/platform/schools',
            pageBuilder: (context, state) => const NoTransitionPage(child: SchoolsPage()),
          ),
          GoRoute(
            path: '/students/:id/diaries',
            builder: (context, state) => StudentDiariesPage(studentId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/students/:id/notes',
            builder: (context, state) => StudentNotesPage(studentId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/students/:id/gallery',
            builder: (context, state) => StudentGalleryPage(studentId: state.pathParameters['id']!),
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
            path: '/users/:id',
            builder: (context, state) => UserDetailPage(userId: state.pathParameters['id']!),
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
