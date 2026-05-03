import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_application_1/features/auth/presentation/pages/register_page.dart';
import 'package:flutter_application_1/features/auth/presentation/pages/onboarding_page.dart';
import 'package:flutter_application_1/features/home/presentation/pages/home_page.dart';
import 'package:flutter_application_1/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter_application_1/features/sessions/presentation/pages/sessions_page.dart';
import 'package:flutter_application_1/features/teachers/presentation/pages/teachers_page.dart';
import 'package:flutter_application_1/features/trainings/presentation/pages/trainings_page.dart';
import 'package:flutter_application_1/features/guidance/presentation/pages/guidance_page.dart';
import 'package:flutter_application_1/features/community/presentation/pages/community_page.dart';
import 'package:flutter_application_1/features/main/presentation/pages/main_shell_page.dart';
import 'package:flutter_application_1/features/booking/presentation/pages/booking_page.dart';
import 'package:flutter_application_1/features/teachers/presentation/pages/teacher_availability_page.dart';
import 'package:flutter_application_1/features/teachers/presentation/pages/teacher_dashboard_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),

    /// 🔥 TEACHER DASHBOARD (EKLEDİK)
    GoRoute(
      path: '/teacher-dashboard',
      builder: (context, state) => const TeacherDashboardPage(),
    ),

    /// AVAILABILITY
    GoRoute(
      path: '/teacher-availability',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;

        return TeacherAvailabilityPage(
          teacherId: extra['teacherId'] as String,
          teacherName: extra['teacherName'] as String,
        );
      },
    ),

    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
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
          builder: (context, state) => SessionsPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),

    GoRoute(
      path: '/teachers',
      builder: (context, state) => const TeachersPage(),
    ),

    GoRoute(
      path: '/booking',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;

        return BookingPage(
          teacherId: extra['teacherId'] as String,
          teacherName: extra['teacherName'] as String,
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
);