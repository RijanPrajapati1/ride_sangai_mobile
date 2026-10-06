import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/explore_providers.dart';
import '../utils/error_message.dart';
import '../widgets/place_card.dart';

/// The rider's "want to go" list.
class SavedPlacesScreen extends ConsumerWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedPlacesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved places')),
      body: savedAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, st) => AppErrorWidget(message: errorMessage(e), onRetry: () => ref.invalidate(savedPlacesProvider)),
        data: (places) {
          if (places.isEmpty) {
            return EmptyState(
              icon: Icons.bookmarks_outlined,
              title: 'Nothing saved yet',
              message: 'Tap the bookmark on any place to keep it on your "want to go" list.',
              actionLabel: 'Explore places',
              onAction: () => context.pop(),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(savedPlacesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.spaceMd),
              itemCount: places.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceSm),
              itemBuilder: (context, index) {
                final place = places[index];
                return PlaceCard(
                  place: place,
                  onTap: () => context.push(RouteNames.placeDetailsPath(place.id)),
                  onToggleSave: () async {
                    try {
                      await ref.read(exploreActionsControllerProvider).toggleSave(place.id, isCurrentlySaved: true);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(e))));
                      }
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
