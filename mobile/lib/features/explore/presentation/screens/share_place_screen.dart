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
import '../../../../core/location/reverse_geocoder.dart';
import '../../../../core/utils/geo.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/section_header.dart';
import '../providers/explore_providers.dart';
import '../../domain/entities/place.dart';
import '../utils/error_message.dart';
import '../widgets/place_map.dart';
import '../widgets/place_photo_picker.dart';

/// "Share a place": a rider who knows a spot pins it on the map and tells
/// others what makes it worth the trip.
class SharePlaceScreen extends ConsumerStatefulWidget {
  /// When set, the form edits this place instead of sharing a new one.
  final Place? place;

  const SharePlaceScreen({super.key, this.place});

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

  /// The rider's exact position from the "I'm here" button, if it worked;
  /// shown as the blue dot even when the app-wide location was approximate.
  GeoPoint? _me;
  bool _locating = false;
  bool _isSubmitting = false;

  bool get _isEditing => widget.place != null;

  @override
  void initState() {
    super.initState();
    final place = widget.place;
    if (place == null) return;
    _nameController.text = place.name;
    _descriptionController.text = place.description;
    _locationController.text = place.locationName;
    _bestTimeController.text = place.bestTime ?? '';
    _entryFeeController.text = place.entryFee ?? '';
    _tipsController.text = place.tips ?? '';
    _category = place.category;
    _activities.addAll(place.activities);
    _photos = List.of(place.photos);
    _pin = place.point;
    // The saved area is the rider's own wording; don't overwrite it.
    _areaEditedByUser = true;
  }

  /// Once the rider types their own area, a new pin no longer overwrites it.
  bool _areaEditedByUser = false;
  int _geocodeRequest = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _bestTimeController.dispose();
    _entryFeeController.dispose();
    _tipsController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _setPin(GeoPoint point) {
    setState(() => _pin = point);
    _fillArea(point);
  }

  Future<void> _fillArea(GeoPoint point) async {
    if (_areaEditedByUser) return;
    final request = ++_geocodeRequest;
    final name = await ref.read(reverseGeocoderProvider).areaName(point);
    // Ignore stale answers from an earlier pin, or if the rider took over.
    if (!mounted || request != _geocodeRequest || _areaEditedByUser || name == null) return;
    // Keep a valid cursor: assigning bare text leaves the selection invalid,
    // which can make the field feel stuck until it is re-tapped.
    _locationController.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    final location = await ref.read(locationServiceProvider).current();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _pin = location.point;
      if (!location.isApproximate) _me = location.point;
    });
    try {
      _mapController.move(toLatLng(location.point), 15);
    } catch (_) {
      // The map is not on screen yet; it will open at the pin.
    }
    if (!location.isApproximate) _fillArea(location.point);
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
      if (_isEditing) {
        await ref.read(exploreActionsControllerProvider).updatePlace(
              widget.place!.id,
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Place updated.')));
        context.pop();
        return;
      }
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(currentLocationProvider).value ?? LocationService.fallback;
    // The map opens before the location resolves (centered on the fallback),
    // so move to the rider once their real position arrives, unless they
    // have already started pinning somewhere.
    ref.listen(currentLocationProvider, (previous, next) {
      final resolved = next.value;
      if (resolved == null || resolved.isApproximate || _pin != null) return;
      try {
        _mapController.move(toLatLng(resolved.point), 14);
      } catch (_) {
        // The map is not on screen yet; it will open at the location.
      }
    });
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit place' : 'Share a place')),
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
            // Every field sits on one white card so the form reads as a
            // single unit against the grey page background.
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(padding: EdgeInsets.zero, title: 'The place'),
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
                  const SectionHeader(padding: EdgeInsets.zero, title: 'Location'),
                  const SizedBox(height: AppDimensions.spaceSm),
                  AppTextField(
                    label: 'Area',
                    hint: 'e.g. Near Kirtipur, Kathmandu',
                    controller: _locationController,
                    onChanged: (value) {
                      _areaEditedByUser = value.trim().isNotEmpty;
                      _geocodeRequest++; // drop any lookup still in flight
                    },
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
                        userLocation: _me ?? (location.isApproximate ? null : location.point),
                        pickedPoint: _pin,
                        onMapTap: _setPin,
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
                  const SectionHeader(padding: EdgeInsets.zero, title: 'Good for'),
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
                  const SectionHeader(padding: EdgeInsets.zero, title: 'Tips for visitors'),
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
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            AppButton(label: _isEditing ? 'Save changes' : 'Share place', icon: _isEditing ? Icons.check : Icons.send_outlined, isLoading: _isSubmitting, onPressed: _submit),
            const SizedBox(height: AppDimensions.spaceLg),
          ],
        ),
      ),
    );
  }
}

/// Loads a place and opens it in the form for the rider who shared it.
class EditPlaceScreen extends ConsumerWidget {
  final String placeId;

  const EditPlaceScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeAsync = ref.watch(placeDetailsProvider(placeId));
    return placeAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const LoadingWidget()),
      error: (e, st) => Scaffold(
        appBar: AppBar(),
        body: AppErrorWidget(message: errorMessage(e), onRetry: () => ref.invalidate(placeDetailsProvider(placeId))),
      ),
      data: (place) => SharePlaceScreen(place: place),
    );
  }
}
