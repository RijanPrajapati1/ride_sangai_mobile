import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/ride_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../widgets/follow_list_sheet.dart';
import '../../../messages/presentation/providers/message_providers.dart';
import '../../../rides/presentation/providers/ride_providers.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_providers.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwnProfile = userId == ref.watch(currentUserIdProvider);
    final profileAsync = ref.watch(profileProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? 'My Profile' : 'Profile'),
        automaticallyImplyLeading: !isOwnProfile,
        actions: isOwnProfile
            ? [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push(RouteNames.settings),
                ),
              ]
            : null,
      ),
      body: profileAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, st) => AppErrorWidget(
          message: _errorMessage(e),
          onRetry: () => ref.invalidate(profileProvider(userId)),
        ),
        data: (profile) => _ProfileBody(profile: profile, isOwnProfile: isOwnProfile || profile.isMe),
      ),
    );
  }
}

/// The message to show for a failed request.
String _errorMessage(Object error) =>
    error is AppException ? error.message : 'Something went wrong. Please try again.';

class _ProfileBody extends ConsumerWidget {
  final UserProfile profile;
  final bool isOwnProfile;

  const _ProfileBody({required this.profile, required this.isOwnProfile});

  Future<void> _toggleFollow(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(profileControllerProvider).toggleFollow(profile.id, isCurrentlyFollowing: profile.isFollowing);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
      }
    }
  }

  Future<void> _message(BuildContext context, WidgetRef ref) async {
    try {
      final conversation = await ref.read(messageActionsControllerProvider).openConversationWith(
            userId: profile.id,
            userName: profile.name,
            userAvatarUrl: profile.avatarUrl,
          );
      if (context.mounted) context.push(RouteNames.conversationPath(conversation.id));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizedRidesAsync = ref.watch(userOrganizedRidesProvider(profile.id));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(profileProvider(profile.id));
        ref.invalidate(userOrganizedRidesProvider(profile.id));
      },
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: [
          Center(child: AppAvatar(imageUrl: profile.avatarUrl, name: profile.name, size: AppDimensions.avatarXl)),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(profile.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 4),
          if (profile.location.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: context.appColors.textMuted),
                const SizedBox(width: 4),
                Flexible(child: Text(profile.location, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          if (profile.isPrivate && !isOwnProfile) ...[
            const SizedBox(height: AppDimensions.spaceSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 16, color: context.appColors.textMuted),
                const SizedBox(width: 4),
                Text('This profile is private', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
          if (profile.bio.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spaceSm),
            Text(profile.bio, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          ],
          const SizedBox(height: AppDimensions.spaceMd),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              AppChip(label: profile.experienceLevel.label, icon: Icons.emoji_events_outlined, selected: true),
              AppChip(label: profile.preferredRideType.label, icon: profile.preferredRideType.icon),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          StatCardRow(
            stats: [
              StatCard(value: '${profile.totalRides}', label: 'Rides'),
              StatCard(value: '${profile.completedRides}', label: 'Completed'),
              StatCard(value: '${profile.followersCount}', label: 'Followers'),
              StatCard(value: '${profile.followingCount}', label: 'Following'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => showFollowListSheet(context, userId: profile.id, type: FollowListType.followers),
                child: const Text('View followers'),
              ),
              TextButton(
                onPressed: () => showFollowListSheet(context, userId: profile.id, type: FollowListType.following),
                child: const Text('View following'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          if (isOwnProfile)
            AppOutlinedButton(
              label: 'Edit Profile',
              icon: Icons.edit_outlined,
              onPressed: () => context.push(RouteNames.editProfile),
            )
          else
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: profile.isFollowing ? 'Following' : 'Follow',
                    icon: profile.isFollowing ? Icons.check : Icons.person_add_alt_1_outlined,
                    onPressed: () => _toggleFollow(context, ref),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: AppOutlinedButton(
                    label: 'Message',
                    icon: Icons.chat_bubble_outline,
                    onPressed: () => _message(context, ref),
                  ),
                ),
              ],
            ),
          if (profile.cyclingInterests.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spaceLg),
            Text('Cycling interests', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppDimensions.spaceSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final interest in profile.cyclingInterests) AppChip(label: interest)],
            ),
          ],
          const SizedBox(height: AppDimensions.spaceLg),
          const SectionHeader(title: 'Rides Organized'),
          const SizedBox(height: AppDimensions.spaceSm),
          organizedRidesAsync.when(
            loading: () => const SizedBox(height: 100, child: LoadingWidget()),
            error: (e, st) => AppErrorWidget(message: _errorMessage(e)),
            data: (rides) {
              if (rides.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMd),
                  child: Text(
                    'No rides organized yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return Column(
                children: [
                  for (final ride in rides.take(3)) ...[
                    RideCard(ride: ride, onTap: () => context.push(RouteNames.rideDetailsPath(ride.id))),
                    const SizedBox(height: AppDimensions.spaceSm),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
