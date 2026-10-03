import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/place_category.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/utils/geo.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/section_header.dart';
import '../providers/explore_providers.dart';
import '../widgets/place_map.dart';
import '../widgets/place_photo_picker.dart';

/// "Share a place": a rider who knows a spot pins it on the map and tells
/// others what makes it worth the trip.
class SharePlaceScreen extends ConsumerStatefulWidget {
  const SharePlaceScreen({super.key});

  @override
  ConsumerState<SharePlaceScreen> createState() => _SharePlaceScreenState();
}

class _SharePlaceScreenState extends ConsumerState<SharePlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _bestTimeController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final _tipsController = TextEditingController();
  final _mapController = MapController();

  PlaceCategory _category = PlaceCategory.viewpoint;
  final Set<DashboardCategory> _activities = {};
  List<String> _photos = [];
  GeoPoint? _pin;
  bool _locating = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _bestTimeController.dispose();
    _entryFeeController.dispose();
    _tipsController.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    final location = await ref.read(locationServiceProvider).current();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _pin = location.point;
    });
    try {
      _mapController.move(toLatLng(location.point), 15);
    } catch (_) {
      // The map is not on screen yet; it will open at the pin.
    }
    if (location.isApproximate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get your exact location — tap the map to place the pin.')),
      );
    }
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    if (_pin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap the map (or use your location) to pin the place')),
      );
      return;
    }
    if (!valid) return;

    setState(() => _isSubmitting = true);
    try {
      final place = await ref.read(exploreActionsControllerProvider).sharePlace(
            name: _nameController.text,
            description: _descriptionController.text,
            category: _category,
            latitude: _pin!.latitude,
            longitude: _pin!.longitude,
            locationName: _locationController.text,
            photos: _photos,
            activities: _activities.toList(),
            bestTime: _bestTimeController.text,
            tips: _tipsController.text,
            entryFee: _entryFeeController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${place.name}" is now on Explore. Thanks for sharing!')));
      context.pushReplacement(RouteNames.placeDetailsPath(place.id));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(currentLocationProvider).value ?? LocationService.fallback;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Share a place')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          children: [
            Text(
              'Know a hidden gem? Pin it so other riders can find it.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            PlacePhotoPicker(photos: _photos, onChanged: (photos) => setState(() => _photos = photos)),
            const SizedBox(height: AppDimensions.spaceLg),
            const SectionHeader(title: 'The place'),
            const SizedBox(height: AppDimensions.spaceSm),
            AppTextField(
              label: 'Name',
              hint: 'e.g. Taudaha Lake',
              controller: _nameController,
              validator: (v) => Validators.required(v, field: 'Name'),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            AppDropdown<PlaceCategory>(
              label: 'Category',
              value: _category,
              items: PlaceCategory.values,
              labelBuilder: (c) => c.label,
              onChanged: (c) => setState(() => _category = c ?? _category),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            AppTextField(
              label: 'What makes it special?',
              hint: 'The view, the story, how to get there…',
              controller: _descriptionController,
              maxLines: 4,
              validator: (v) => Validators.required(v, field: 'Description'),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            const SectionHeader(title: 'Location'),
            const SizedBox(height: AppDimensions.spaceSm),
            AppTextField(
              label: 'Area',
              hint: 'e.g. Near Kirtipur, Kathmandu',
              controller: _locationController,
              prefixIcon: const Icon(Icons.location_on_outlined),
              validator: (v) => Validators.required(v, field: 'Area'),
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              child: SizedBox(
                height: 240,
                child: PlaceMap(
                  controller: _mapController,
                  center: _pin ?? location.point,
                  zoom: 12,
                  userLocation: location.isApproximate ? null : location.point,
                  pickedPoint: _pin,
                  onMapTap: (point) => setState(() => _pin = point),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _pin == null
                        ? 'Tap the map to drop a pin'
                        : 'Pinned at ${_pin!.latitude.toStringAsFixed(5)}, ${_pin!.longitude.toStringAsFixed(5)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: _pin == null ? AppColors.secondary : null),
                  ),
                ),
                TextButton.icon(
                  onPressed: _locating ? null : _useMyLocation,
                  icon: _locating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location, size: 18),
                  label: const Text("I'm here"),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            const SectionHeader(title: 'Good for'),
            const SizedBox(height: AppDimensions.spaceSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final activity in DashboardCategory.values)
                  FilterChip(
                    avatar: Icon(activity.icon, size: 16),
                    label: Text(activity.label),
                    selected: _activities.contains(activity),
                    onSelected: (selected) => setState(() {
                      selected ? _activities.add(activity) : _activities.remove(activity);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            const SectionHeader(title: 'Tips for visitors'),
            const SizedBox(height: AppDimensions.spaceSm),
            AppTextField(
              label: 'Best time to go',
              hint: 'e.g. Sunrise, October to December',
              controller: _bestTimeController,
              prefixIcon: const Icon(Icons.wb_sunny_outlined),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            AppTextField(
              label: 'Entry fee',
              hint: 'e.g. Free, or Rs 100',
              controller: _entryFeeController,
              prefixIcon: const Icon(Icons.confirmation_number_outlined),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            AppTextField(
              label: 'Local tips',
              hint: 'Road condition, parking, food nearby…',
              controller: _tipsController,
              maxLines: 3,
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            AppButton(label: 'Share place', icon: Icons.send_outlined, isLoading: _isSubmitting, onPressed: _submit),
            const SizedBox(height: AppDimensions.spaceLg),
          ],
        ),
      ),
    );
  }
}
