import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/core/services/supabase_service.dart';

import 'package:flutter_application_1/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_application_1/features/auth/presentation/pages/register_page.dart';
import 'package:flutter_application_1/features/auth/presentation/pages/onboarding_page.dart';
import 'package:flutter_application_1/features/auth/presentation/pages/profile_onboarding_page.dart';
import 'package:flutter_application_1/features/auth/presentation/pages/splash_page.dart';

import 'package:flutter_application_1/features/home/presentation/pages/home_page.dart';
import 'package:flutter_application_1/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter_application_1/features/profile/presentation/pages/profile_edit_page.dart';

import 'package:flutter_application_1/features/sessions/data/models/session_model.dart';
import 'package:flutter_application_1/features/sessions/presentation/pages/sessions_page.dart';
import 'package:flutter_application_1/features/sessions/presentation/pages/teacher_sessions_page.dart';

import 'package:flutter_application_1/features/teachers/presentation/pages/teachers_page.dart';
import 'package:flutter_application_1/features/teachers/presentation/pages/teacher_availability_page.dart';
import 'package:flutter_application_1/features/teachers/presentation/pages/teacher_dashboard_page.dart';
import 'package:flutter_application_1/features/teachers/presentation/pages/teacher_edit_profile_page.dart';
import 'package:flutter_application_1/features/teachers/data/models/teacher_model.dart';

import 'package:flutter_application_1/features/trainings/presentation/pages/trainings_page.dart';
import 'package:flutter_application_1/features/guidance/presentation/pages/guidance_page.dart';
import 'package:flutter_application_1/features/community/presentation/pages/community_page.dart';

import 'package:flutter_application_1/features/meditations/presentation/pages/meditations_page.dart';
import 'package:flutter_application_1/features/meditations/presentation/pages/teacher_meditations_page.dart';

import 'package:flutter_application_1/features/main/presentation/pages/main_shell_page.dart';

import 'package:flutter_application_1/features/booking/presentation/pages/booking_page.dart';
import 'package:flutter_application_1/features/booking/presentation/pages/booking_success_page.dart';

import 'package:flutter_application_1/features/notifications/data/presentation/pages/notifications_page.dart';

import 'package:flutter_application_1/features/video_call/presentation/pages/video_call_page.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();

    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

Future<String> fetchCurrentUserRole(String userId) async {
  try {
    final response = await supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    return response?['role']?.toString() ?? 'student';
  } catch (_) {
    return 'student';
  }
}

Future<Map<String, dynamic>?> fetchCurrentUserProfileStatus(
  String userId,
) async {
  try {
    final response = await supabase
        .from('profiles')
        .select('role, onboarding_completed')
        .eq('id', userId)
        .maybeSingle();

    return response;
  } catch (_) {
    return null;
  }
}

bool hasStringValue(Map<String, dynamic> map, String key) {
  final value = map[key];
  return value is String && value.trim().isNotEmpty;
}

double parseExtraDouble(Map<String, dynamic> map, String key) {
  final value = map[key];

  if (value == null) return 0;

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  refreshListenable: GoRouterRefreshStream(
    supabase.auth.onAuthStateChange,
  ),
  redirect: (context, state) async {
    final user = supabase.auth.currentUser;
    final location = state.uri.path;

    final publicRoutes = [
      '/splash',
      '/login',
      '/register',
      '/onboarding',
    ];

    final teacherOnlyRoutes = [
      '/teacher-dashboard',
      '/teacher-edit-profile',
      '/teacher-sessions',
      '/teacher-availability',
      '/teacher-meditations',
    ];

    final studentOnlyRoutes = [
      '/home',
      '/sessions',
      '/profile',
      '/profile-edit',
      '/profile-onboarding',
      '/teachers',
      '/booking',
      '/booking-success',
      '/trainings',
      '/guidance',
      '/community',
      '/notifications',
      '/meditations',
    ];

    final isPublicRoute = publicRoutes.contains(location);
    final isTeacherOnlyRoute = teacherOnlyRoutes.contains(location);
    final isStudentOnlyRoute = studentOnlyRoutes.contains(location);

    if (user == null) {
      if (isPublicRoute) {
        return null;
      }

      return '/login';
    }

    final profileStatus = await fetchCurrentUserProfileStatus(user.id);

    final role = profileStatus?['role']?.toString() ?? 'student';
    final onboardingCompleted =
        profileStatus?['onboarding_completed'] == true;

    if (isPublicRoute) {
      if (role == 'teacher') {
        return '/teacher-dashboard';
      }

      if (!onboardingCompleted) {
        return '/profile-onboarding';
      }

      return '/home';
    }

    if (role == 'student' &&
        !onboardingCompleted &&
        location != '/profile-onboarding') {
      return '/profile-onboarding';
    }

    if (role == 'student' && isTeacherOnlyRoute) {
      return '/home';
    }

    if (role == 'teacher' && isStudentOnlyRoute) {
      return '/teacher-dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),

    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),

    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),

    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),

    GoRoute(
      path: '/profile-onboarding',
      builder: (context, state) => const ProfileOnboardingPage(),
    ),

    GoRoute(
      path: '/teacher-dashboard',
      builder: (context, state) => const TeacherDashboardPage(),
    ),

    GoRoute(
      path: '/teacher-meditations',
      builder: (context, state) => const TeacherMeditationsPage(),
    ),

    GoRoute(
      path: '/teacher-edit-profile',
      redirect: (context, state) {
        if (state.extra is! TeacherModel) {
          return '/teacher-dashboard';
        }

        return null;
      },
      builder: (context, state) {
        final teacher = state.extra as TeacherModel;

        return TeacherEditProfilePage(teacher: teacher);
      },
    ),

    GoRoute(
      path: '/teacher-sessions',
      builder: (context, state) => const TeacherSessionsPage(),
    ),

    GoRoute(
      path: '/teacher-availability',
      redirect: (context, state) {
        final extra = state.extra;

        if (extra is! Map<String, dynamic>) {
          return '/teacher-dashboard';
        }

        if (!hasStringValue(extra, 'teacherId') ||
            !hasStringValue(extra, 'teacherName')) {
          return '/teacher-dashboard';
        }

        return null;
      },
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;

        return TeacherAvailabilityPage(
          teacherId: extra['teacherId'] as String,
          teacherName: extra['teacherName'] as String,
        );
      },
    ),

    GoRoute(
      path: '/video-call',
      redirect: (context, state) {
        final extra = state.extra;

        if (extra is! Map<String, dynamic>) {
          final user = supabase.auth.currentUser;

          if (user == null) {
            return '/login';
          }

          return '/home';
        }

        if (extra['session'] is! SessionModel) {
          return '/home';
        }

        return null;
      },
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final session = extra['session'] as SessionModel;
        final participantName = extra['participantName']?.toString() ?? '';

        return VideoCallPage(
          session: session,
          participantName: participantName,
        );
      },
    ),

    ShellRoute(
      builder: (context, state, child) => MainShellPage(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),

        GoRoute(
          path: '/sessions',
          builder: (context, state) => const SessionsPage(),
        ),

        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),

        GoRoute(
          path: '/profile-edit',
          redirect: (context, state) {
            final extra = state.extra;

            if (extra is! Map<String, dynamic>) {
              return '/profile';
            }

            return null;
          },
          builder: (context, state) {
            final profile = state.extra as Map<String, dynamic>;

            return ProfileEditPage(profile: profile);
          },
        ),

        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsPage(),
        ),

        GoRoute(
          path: '/teachers',
          builder: (context, state) => const TeachersPage(),
        ),

        GoRoute(
          path: '/meditations',
          builder: (context, state) => const MeditationsPage(),
        ),

        GoRoute(
          path: '/booking',
          redirect: (context, state) {
            final extra = state.extra;

            if (extra is! Map<String, dynamic>) {
              return '/teachers';
            }

            if (!hasStringValue(extra, 'teacherId') ||
                !hasStringValue(extra, 'teacherName') ||
                !hasStringValue(extra, 'currency')) {
              return '/teachers';
            }

            final sessionPrice = parseExtraDouble(extra, 'sessionPrice');

            if (sessionPrice <= 0) {
              return '/teachers';
            }

            return null;
          },
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;

            return BookingPage(
              teacherId: extra['teacherId'] as String,
              teacherName: extra['teacherName'] as String,
              sessionPrice: parseExtraDouble(extra, 'sessionPrice'),
              currency: extra['currency'] as String,
            );
          },
        ),

        GoRoute(
          path: '/booking-success',
          redirect: (context, state) {
            final extra = state.extra;

            if (extra is! Map<String, dynamic>) {
              return '/sessions';
            }

            if (!hasStringValue(extra, 'teacherName') ||
                !hasStringValue(extra, 'sessionDate') ||
                !hasStringValue(extra, 'sessionTime')) {
              return '/sessions';
            }

            return null;
          },
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;

            return BookingSuccessPage(
              teacherName: extra['teacherName'] as String,
              sessionDate: extra['sessionDate'] as String,
              sessionTime: extra['sessionTime'] as String,
              notes: extra['notes'] as String?,
            );
          },
        ),

        GoRoute(
          path: '/trainings',
          builder: (context, state) => const TrainingsPage(),
        ),

        GoRoute(
          path: '/guidance',
          builder: (context, state) => const GuidancePage(),
        ),

        GoRoute(
          path: '/community',
          builder: (context, state) => const CommunityPage(),
        ),
      ],
    ),
  ],
);