import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/presentation/account_screen.dart';
import '../features/audit/presentation/audit_screen.dart';
import '../features/audit/presentation/my_activity_screen.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/profile_setup_screen.dart';
import '../features/auth/presentation/reset_code_screen.dart';
import '../features/auth/presentation/set_new_password_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/duty/presentation/duty_screen.dart';
import '../features/export/presentation/export_screen.dart';
import '../features/meals/presentation/meal_types_screen.dart';
import '../features/meals/presentation/meals_screen.dart';
import '../features/messages/domain/message_draft.dart';
import '../features/messages/presentation/messages_screens.dart';
import '../features/messages/presentation/new_message_screen.dart';
import '../features/mess/application/mess_providers.dart';
import '../features/mess/domain/member.dart';
import '../features/mess/presentation/due_reminders_screen.dart';
import '../features/mess/presentation/mess_screens.dart';
import '../features/money/presentation/money_screen.dart';
import '../features/money/presentation/months_screen.dart';
import '../features/month/presentation/month_end_review_screen.dart';
import '../features/notices/presentation/notices_screen.dart';
import '../features/push/presentation/inbox_screen.dart';
import '../features/push/presentation/push_screens.dart';
import '../features/recurring/presentation/meal_defaults_screen.dart';
import '../features/recurring/presentation/recurring_screen.dart';
import '../features/reminders/presentation/reminders_screen.dart';
import '../features/today/presentation/today_screen.dart';
import 'dates.dart';
import 'failure_text.dart';
import 'shell.dart';
import 'widgets/widgets.dart';

const homePath = '/today';

DateTime? _dayParam(String? v) {
  final d = DateTime.tryParse(v ?? '');
  return d == null ? null : dayOnly(d);
}

/// Where [location] should go given the session, or null to stay.
///
/// [memberships] null means "still loading". An invite `code` query param is
/// carried through sign-in and profile setup so a deep link survives them.
/// Each call is one step; go_router re-runs it on the redirected location.
/// [recovering]: a reset-password link opened the app; hold the user on
/// `/auth/reset-password` until the new password is saved.
String? decideRedirect({
  required bool signedIn,
  bool recovering = false,
  required bool profileComplete,
  required List<Membership>? memberships,
  required String location,
}) {
  final uri = Uri.parse(location);
  final path = uri.path;
  final segments = uri.pathSegments;

  // Invite deep link: /join/:code
  if (segments.length == 2 && segments.first == 'join') {
    return _withCode('/onboarding/join', segments[1]);
  }
  final code = uri.queryParameters['code'];
  final inviteCode = path == '/onboarding/join' || path.startsWith('/auth/')
      ? code
      : null;

  if (!signedIn) {
    if (path == '/auth/reset-code') return null;
    return path == '/auth/sign-in'
        ? null
        : _withCode('/auth/sign-in', inviteCode);
  }
  if (recovering) {
    return path == '/auth/reset-password' ? null : '/auth/reset-password';
  }
  if (!profileComplete) {
    return path == '/auth/profile'
        ? null
        : _withCode('/auth/profile', inviteCode);
  }
  if (memberships == null) return null;

  final onboarding = path == '/onboarding' || path.startsWith('/onboarding/');
  if (path == '/' || path.startsWith('/auth/')) {
    return inviteCode == null
        ? homePath
        : _withCode('/onboarding/join', inviteCode);
  }

  final statuses = memberships.map((m) => m.member.status);
  if (!statuses.contains(MemberStatus.active)) {
    if (statuses.contains(MemberStatus.pending)) {
      // Pending users may still join or create another mess.
      return path == '/pending' || onboarding ? null : '/pending';
    }
    return onboarding ? null : '/onboarding';
  }
  // Active members may still create/join another mess.
  return path == '/pending' ? homePath : null;
}

String _withCode(String path, String? code) => code == null || code.isEmpty
    ? path
    : Uri(path: path, queryParameters: {'code': code}).toString();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  void bump(Object? _, Object? _) => refresh.value++;
  ref.listen(authStateProvider, bump);
  ref.listen(passwordRecoveryProvider, bump);
  ref.listen(myProfileProvider, bump);
  ref.listen(myMembershipsProvider, bump);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      if (!auth.hasValue) return null; // splash shows loading / error
      final signedIn = auth.value != null;
      final profile = ref.read(myProfileProvider);
      if (signedIn && (profile.isLoading || !profile.hasValue)) return null;
      final memberships = ref.read(myMembershipsProvider);
      return decideRedirect(
        signedIn: signedIn,
        recovering: ref.read(passwordRecoveryProvider),
        profileComplete: profile.value?.fullName.trim().isNotEmpty ?? false,
        memberships: memberships.isLoading ? null : memberships.value,
        location: state.uri.toString(),
      );
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const _SplashScreen()),
      GoRoute(path: '/join/:code', builder: (_, _) => const _SplashScreen()),
      // Phone login (PhoneScreen) disabled until an SMS provider is funded.
      GoRoute(
        path: '/auth/sign-in',
        builder: (_, state) =>
            SignInScreen(inviteCode: state.uri.queryParameters['code']),
      ),
      GoRoute(
        path: '/auth/reset-code',
        // Redirect sends a deep link without an email back to sign-in.
        redirect: (_, state) => state.extra is String ? null : '/auth/sign-in',
        builder: (_, state) => ResetCodeScreen(email: state.extra! as String),
      ),
      GoRoute(
        path: '/auth/reset-password',
        builder: (_, _) => const SetNewPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/profile',
        builder: (_, _) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const MessOnboardingScreen(),
        routes: [
          GoRoute(path: 'create', builder: (_, _) => const CreateMessScreen()),
          GoRoute(
            path: 'join',
            builder: (_, state) =>
                JoinMessScreen(initialCode: state.uri.queryParameters['code']),
          ),
        ],
      ),
      GoRoute(
        path: '/pending',
        builder: (_, _) => const PendingApprovalScreen(),
      ),
      StatefulShellRoute(
        builder: (_, _, shell) => AppShell(shell: shell),
        navigatorContainerBuilder: AppShell.branchContainer,
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: homePath, builder: (_, _) => const TodayScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/meals',
                builder: (_, state) => MealsScreen(
                  initialDate: _dayParam(state.uri.queryParameters['date']),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/bazar', builder: (_, _) => const BazarScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/money',
                builder: (_, state) => MoneyScreen(
                  tab: MoneyTab.values
                      .asNameMap()[state.uri.queryParameters['tab']],
                ),
                routes: [
                  GoRoute(
                    path: 'months',
                    builder: (_, _) => const MonthsScreen(),
                    routes: [
                      GoRoute(
                        path: 'review',
                        builder: (_, state) => MonthEndReviewScreen(
                          start: DateTime.tryParse(
                            state.uri.queryParameters['start'] ?? '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (_, _) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'members',
                    builder: (_, _) => const MembersScreen(),
                  ),
                  GoRoute(
                    path: 'invite',
                    builder: (_, _) => const InviteScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (_, _) => const MessSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'account',
                    builder: (_, _) => const AccountScreen(),
                  ),
                  GoRoute(
                    path: 'audit',
                    builder: (_, _) => const AuditScreen(),
                  ),
                  GoRoute(
                    path: 'activity',
                    builder: (_, _) => const MyActivityScreen(),
                  ),
                  GoRoute(path: 'duty', builder: (_, _) => const DutyScreen()),
                  GoRoute(
                    path: 'meal-types',
                    builder: (_, _) => const MealTypesScreen(),
                  ),
                  GoRoute(
                    path: 'notices',
                    builder: (_, _) => const NoticesScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (_, state) =>
                            NoticeDetailScreen(id: state.pathParameters['id']!),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'messages',
                    builder: (_, _) => const MessagesInboxScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (_, state) => NewMessageScreen(
                          draft: state.extra is MessageDraft
                              ? state.extra! as MessageDraft
                              : null,
                        ),
                      ),
                      GoRoute(
                        path: 'group',
                        builder: (_, _) => const GroupThreadScreen(),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (_, state) =>
                            ThreadScreen(id: state.pathParameters['id']!),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'export',
                    builder: (_, _) => const ExportScreen(),
                  ),
                  GoRoute(
                    path: 'reminders',
                    builder: (_, _) => const RemindersScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (_, _) => const NotificationSettingsScreen(),
                    routes: [
                      GoRoute(
                        path: 'inbox',
                        builder: (_, _) => const InboxScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'meal-defaults',
                    builder: (_, _) => const MealDefaultsScreen(),
                  ),
                  GoRoute(
                    path: 'recurring',
                    builder: (_, _) => const RecurringScreen(),
                  ),
                  GoRoute(
                    path: 'due-reminders',
                    builder: (_, _) => const DueRemindersScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Shown while the session loads; offers retry if a load failed.
class _SplashScreen extends ConsumerWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = [
      ref.watch(authStateProvider),
      ref.watch(myProfileProvider),
      ref.watch(myMembershipsProvider),
    ].where((a) => a.hasError && !a.isLoading).firstOrNull?.error;
    return Scaffold(
      body: SafeArea(
        child: error == null
            ? const LoadingView()
            : ErrorView(
                message: failureText(context, error),
                onRetry: () {
                  ref.invalidate(myProfileProvider);
                  ref.invalidate(myMembershipsProvider);
                },
              ),
      ),
    );
  }
}
