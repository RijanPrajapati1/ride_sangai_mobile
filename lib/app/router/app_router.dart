import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/community/presentation/screens/post_detail_screen.dart';
import '../../features/create_ride/presentation/screens/create_ride_screen.dart';
import '../../features/groups/presentation/screens/create_group_screen.dart';
import '../../features/groups/presentation/screens/group_chat_screen.dart';
import '../../features/groups/presentation/screens/groups_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/messages/presentation/screens/chat_screen.dart';
import '../../features/messages/presentation/screens/conversations_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/providers/onboarding_providers.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/ride_requests/presentation/screens/ride_requests_screen.dart';
import '../../features/rides/presentation/screens/my_rides_screen.dart';
import '../../features/rides/presentation/screens/ride_details_screen.dart';
import '../../features/rides/presentation/screens/ride_participants_screen.dart';
import '../../features/rides/presentation/screens/rides_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../app_shell.dart';
import '../splash_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final onboardingAsync = ref.watch(onboardingCompleteProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute = location == RouteNames.login ||
          location == RouteNames.register ||
          location == RouteNames.forgotPassword;
      final isOnboardingRoute = location == RouteNames.onboarding;
      final isSplash = location == RouteNames.splash;

      if (authState.status == AuthStatus.unknown || onboardingAsync.isLoading) {
        return isSplash ? null : RouteNames.splash;
      }

      final onboardingDone = onboardingAsync.value ?? false;
      if (!onboardingDone) {
        return isOnboardingRoute ? null : RouteNames.onboarding;
      }

      final authenticated = authState.status == AuthStatus.authenticated;
      if (!authenticated) {
        return isAuthRoute ? null : RouteNames.login;
      }

      final isAdmin = authState.user?.isAdmin ?? false;
      final isAdminRoute = location == RouteNames.admin;
      const riderShellRoots = {
        RouteNames.home,
        RouteNames.rides,
        RouteNames.community,
        RouteNames.profile,
      };

      if (isAdmin) {
        // Admins can still drill into a rider/ride/post's detail page (pushed
        // on top of the dashboard) to review it before moderating — only the
        // rider bottom-nav tabs themselves are off-limits.
        final blocked = isSplash || isOnboardingRoute || isAuthRoute || riderShellRoots.contains(location);
        return blocked ? RouteNames.admin : null;
      }
      if (isAdminRoute) {
        return RouteNames.home;
      }

      if (isSplash || isOnboardingRoute || isAuthRoute) {
        return RouteNames.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: RouteNames.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: RouteNames.admin, builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(path: RouteNames.onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: RouteNames.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: RouteNames.register, builder: (context, state) => const RegisterScreen()),
      GoRoute(path: RouteNames.forgotPassword, builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: RouteNames.createRide, builder: (context, state) => const CreateRideScreen()),
      GoRoute(path: RouteNames.myRides, builder: (context, state) => const MyRidesScreen()),
      GoRoute(
        path: RouteNames.rideDetails,
        builder: (context, state) => RideDetailsScreen(rideId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RouteNames.rideParticipants,
        builder: (context, state) => RideParticipantsScreen(rideId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RouteNames.rideRequests,
        builder: (context, state) => RideRequestsScreen(rideId: state.pathParameters['id']!),
      ),
      GoRoute(path: RouteNames.notifications, builder: (context, state) => const NotificationsScreen()),
      GoRoute(
        path: RouteNames.communityPost,
        builder: (context, state) => PostDetailScreen(postId: state.pathParameters['postId']!),
      ),
      GoRoute(path: RouteNames.groups, builder: (context, state) => const GroupsScreen()),
      // Must be declared before RouteNames.groupChat ('/groups/:id'): same
      // sibling-route ordering rule as editProfile vs userProfile below.
      GoRoute(path: RouteNames.createGroup, builder: (context, state) => const CreateGroupScreen()),
      GoRoute(
        path: RouteNames.groupChat,
        builder: (context, state) => GroupChatScreen(groupId: state.pathParameters['id']!),
      ),
      // Must be declared before RouteNames.userProfile ('/profile/:userId'):
      // go_router matches sibling routes in declaration order, and the
      // wildcard would otherwise swallow '/profile/edit' as userId='edit'.
      GoRoute(path: RouteNames.editProfile, builder: (context, state) => const EditProfileScreen()),
      GoRoute(
        path: RouteNames.userProfile,
        builder: (context, state) => ProfileScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(path: RouteNames.settings, builder: (context, state) => const SettingsScreen()),
      GoRoute(path: RouteNames.messages, builder: (context, state) => const ConversationsScreen()),
      GoRoute(
        path: RouteNames.conversation,
        builder: (context, state) => ChatScreen(conversationId: state.pathParameters['conversationId']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: RouteNames.home, builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RouteNames.rides, builder: (context, state) => const RidesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RouteNames.community, builder: (context, state) => const CommunityScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.profile,
              builder: (context, state) => const ProfileScreen(userId: AppConstants.currentUserId),
            ),
          ]),
        ],
      ),
    ],
  );
});
