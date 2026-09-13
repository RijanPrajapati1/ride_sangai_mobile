class RouteNames {
  RouteNames._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  static const home = '/home';
  static const admin = '/admin';

  static const rides = '/rides';
  static const rideDetails = '/rides/:id';
  static const rideParticipants = '/rides/:id/participants';
  static const rideRequests = '/rides/:id/requests';
  static const createRide = '/create-ride';
  static const myRides = '/my-rides';

  static const messages = '/messages';
  static const conversation = '/messages/:conversationId';

  static const notifications = '/notifications';

  static const community = '/community';
  static const communityPost = '/community/:postId';

  static const groups = '/groups';
  static const createGroup = '/groups/create';
  static const groupChat = '/groups/:id';

  static const profile = '/profile';
  static const userProfile = '/profile/:userId';
  static const editProfile = '/profile/edit';

  static const settings = '/settings';

  static String rideDetailsPath(String id) => '/rides/$id';
  static String rideParticipantsPath(String id) => '/rides/$id/participants';
  static String rideRequestsPath(String id) => '/rides/$id/requests';
  static String conversationPath(String id) => '/messages/$id';
  static String communityPostPath(String id) => '/community/$id';
  static String groupChatPath(String id) => '/groups/$id';
  static String userProfilePath(String id) => '/profile/$id';
}
