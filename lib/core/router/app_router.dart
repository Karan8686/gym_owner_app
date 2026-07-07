import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/members/presentation/member_detail_screen.dart';
import '../../features/members/presentation/member_list_screen.dart';
import '../../features/members/presentation/add_member_screen.dart';
import '../../features/members/presentation/edit_member_screen.dart';
import '../../features/members/presentation/renew_membership_screen.dart';
import '../../features/payments/presentation/pending_payments_screen.dart';
import '../../features/payments/presentation/verify_payment_screen.dart';
import '../../features/pricing/presentation/plan_pricing_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/workouts/presentation/workout_template_editor_screen.dart';
import '../../features/workouts/presentation/workout_templates_screen.dart';
import '../../features/workouts/presentation/assign_workout_screen.dart';
import '../../features/workouts/presentation/member_workout_editor_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../config/theme.dart';

// ---------------------------------------------------------------------------
// Route paths — single source of truth for navigation strings.
// ---------------------------------------------------------------------------
abstract final class AppRoutes {
  static const String login                = '/login';
  static const String dashboard            = '/';
  static const String memberList           = '/members';
  static const String memberDetail         = '/members/:memberId';
  static const String addMember            = '/members/add';
  static const String editMember           = '/members/:memberId/edit';
  static const String quickRenew           = '/members/:memberId/renew';
  static const String pendingPayments      = '/payments/pending';
  static const String paymentVerification  = '/payments/pending/:paymentId/verify';
  static const String planPricing          = '/settings/pricing';
  static const String workoutTemplates     = '/settings/workouts';
  static const String workoutTemplateEditor = '/settings/workouts/:templateId';
  static const String assignWorkout        = '/members/:memberId/assign-workout';
  static const String analytics            = '/settings/analytics';
  static const String settings             = '/settings';
}

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// ---------------------------------------------------------------------------
// Router — requires a WidgetRef to check auth state for redirects.
// ---------------------------------------------------------------------------
GoRouter appRouter(Ref ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final isOnLogin = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !isOnLogin) return AppRoutes.login;
      if (isLoggedIn && isOnLogin) return AppRoutes.dashboard;
      return null; // no redirect
    },
    routes: <RouteBase>[
      // 1. Login (Rendered outside the shell - full screen)
      GoRoute(
        path: AppRoutes.login,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),

      // Stateful Navigation Shell Route for tabbed navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithBottomNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Branch 1: Members
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.memberList,
                builder: (context, state) => const MemberListScreen(),
                routes: [
                  // 5. Add New Member (Rendered full-screen via rootNavigatorKey)
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const AddMemberScreen(),
                  ),

                  // 4. Member Detail (Rendered full-screen via rootNavigatorKey)
                  GoRoute(
                    path: ':memberId',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final memberId = state.pathParameters['memberId']!;
                      return MemberDetailScreen(memberId: memberId);
                    },
                    routes: [
                      // 6. Edit Member
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final memberId = state.pathParameters['memberId']!;
                          return EditMemberScreen(memberId: memberId);
                        },
                      ),

                      // 7. Quick Renew Membership
                      GoRoute(
                        path: 'renew',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final memberId = state.pathParameters['memberId']!;
                          return RenewMembershipScreen(memberId: memberId);
                        },
                      ),

                      // 13. Assign Workout to Member
                      GoRoute(
                        path: 'assign-workout',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final memberId = state.pathParameters['memberId']!;
                          return AssignWorkoutScreen(memberId: memberId);
                        },
                      ),

                      // 13.5 Edit Member Workout Routine
                      GoRoute(
                        path: 'workout/edit',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final memberId = state.pathParameters['memberId']!;
                          return MemberWorkoutEditorScreen(memberId: memberId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Payments
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.pendingPayments,
                builder: (context, state) => const PendingPaymentsScreen(),
                routes: [
                  // 9. Payment Verification detail (Rendered full-screen via rootNavigatorKey)
                  GoRoute(
                    path: ':paymentId/verify',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final paymentId = state.pathParameters['paymentId']!;
                      return VerifyPaymentScreen(paymentId: paymentId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: More (pricing, workouts, settings, analytics)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  // 10. Plan & Pricing Settings
                  GoRoute(
                    path: 'pricing',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const PlanPricingScreen(),
                  ),
                  // 14. Revenue & Analytics
                  GoRoute(
                    path: 'analytics',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const AnalyticsScreen(),
                  ),
                  // 11. Workout Template Library (moved to More)
                  GoRoute(
                    path: 'workouts',
                    builder: (context, state) => const WorkoutTemplatesScreen(),
                    routes: [
                      // 12. Workout Template Editor
                      GoRoute(
                        path: ':templateId',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final templateId = state.pathParameters['templateId']!;
                          return WorkoutTemplateEditorScreen(templateId: templateId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Stateful Navigation Shell frame containing persistent Material 3 floating pill navbar.
// ---------------------------------------------------------------------------
class ScaffoldWithBottomNavBar extends StatelessWidget {
  const ScaffoldWithBottomNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // render body behind the floating navbar
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(31),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final isSelected = states.contains(WidgetState.selected);
                    return AppText.label.copyWith(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppColors.inkPrimary : AppColors.inkSecondary,
                    );
                  }),
                ),
                child: NavigationBar(
                  height: 68,
                  backgroundColor: AppColors.surface.withValues(alpha: 0.95),
                  elevation: 0, // Drop shadow is handled by the container
                  indicatorColor: AppColors.inkPrimary.withValues(alpha: 0.08),
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) {
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.grid_view_rounded, color: AppColors.inkSecondary),
                      selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.inkPrimary),
                      label: 'DASHBOARD',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_alt_rounded, color: AppColors.inkSecondary),
                      selectedIcon: Icon(Icons.people_alt_rounded, color: AppColors.inkPrimary),
                      label: 'MEMBERS',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.payment_rounded, color: AppColors.inkSecondary),
                      selectedIcon: Icon(Icons.payment_rounded, color: AppColors.inkPrimary),
                      label: 'PAYMENTS',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.more_horiz_rounded, color: AppColors.inkSecondary),
                      selectedIcon: Icon(Icons.more_horiz_rounded, color: AppColors.inkPrimary),
                      label: 'MORE',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

