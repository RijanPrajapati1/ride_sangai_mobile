import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/dashboard_category_provider.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_date_picker_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_time_picker_field.dart';
import '../../../../shared/widgets/chip_input_field.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../rides/domain/entities/ride.dart';
import '../../../rides/presentation/providers/ride_providers.dart';
import '../providers/create_ride_providers.dart';
import '../widgets/cover_image_picker.dart';

class CreateRideScreen extends ConsumerStatefulWidget {
  /// When set, the form edits this ride instead of creating a new one.
  final Ride? ride;

  const CreateRideScreen({super.key, this.ride});

  @override
  ConsumerState<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends ConsumerState<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _durationController = TextEditingController();
  final _maxParticipantsController = TextEditingController(text: '20');

  DateTime? _date;
  TimeOfDay? _time;
  late DashboardCategory _category;
  late RideType _rideType;
  RideDifficulty _difficulty = RideDifficulty.easy;
  List<String> _requirements = ['Helmet'];
  String? _imageUrl;
  bool _isSubmitting = false;

  bool get _isEditing => widget.ride != null;

  static String _number(num value) => value == value.truncate() ? value.toInt().toString() : value.toString();

  @override
  void initState() {
    super.initState();
    final ride = widget.ride;
    if (ride == null) {
      _category = ref.read(selectedDashboardCategoryProvider);
      _rideType = _category.rideTypes.first;
      return;
    }
    _category = DashboardCategory.values.firstWhere(
      (c) => c.rideTypes.contains(ride.rideType),
      orElse: () => ref.read(selectedDashboardCategoryProvider),
    );
    _rideType = ride.rideType;
    _difficulty = ride.difficulty;
    _titleController.text = ride.title;
    _descriptionController.text = ride.description;
    _locationController.text = ride.meetingPoint;
    _distanceController.text = _number(ride.distanceKm);
    _durationController.text = ride.durationMinutes.toString();
    _maxParticipantsController.text = ride.maxParticipants.toString();
    _date = DateTime(ride.date.year, ride.date.month, ride.date.day);
    _time = TimeOfDay.fromDateTime(ride.date);
    _requirements = List.of(ride.requirements);
    _imageUrl = ride.imageUrl.isEmpty ? null : ride.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and start time')),
      );
      return;
    }
    if (!isValid) return;

    setState(() => _isSubmitting = true);
    final date = DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    final Ride ride;
    try {
      final controller = ref.read(createRideControllerProvider);
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final meetingPoint = _locationController.text.trim();
      final distanceKm = double.parse(_distanceController.text.trim());
      final durationMinutes = int.parse(_durationController.text.trim());
      final maxParticipants = int.parse(_maxParticipantsController.text.trim());
      ride = _isEditing
          ? await controller.update(
              widget.ride!.id,
              title: title,
              description: description,
              date: date,
              meetingPoint: meetingPoint,
              rideType: _rideType,
              difficulty: _difficulty,
              distanceKm: distanceKm,
              durationMinutes: durationMinutes,
              maxParticipants: maxParticipants,
              requirements: _requirements,
              imageUrl: _imageUrl,
            )
          : await controller.submit(
              title: title,
              description: description,
              date: date,
              meetingPoint: meetingPoint,
              rideType: _rideType,
              difficulty: _difficulty,
              distanceKm: distanceKm,
              durationMinutes: durationMinutes,
              maxParticipants: maxParticipants,
              requirements: _requirements,
              imageUrl: _imageUrl,
            );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final message = error is AppException
          ? error.message
          : error is FormatException
              ? 'Please enter whole numbers for duration and participants.'
              : 'Something went wrong. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${ride.title}" was ${_isEditing ? 'updated' : 'created'}!')),
    );
    if (_isEditing) {
      context.pop();
    } else {
      context.pushReplacement(RouteNames.rideDetailsPath(ride.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${_isEditing ? 'Edit' : 'Create'} ${_category.activitySingular}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          children: [
            CoverImagePicker(imageUrl: _imageUrl, onChanged: (url) => setState(() => _imageUrl = url)),
            const SizedBox(height: AppDimensions.spaceLg),
            // Every field sits on one white card so the form reads as a
            // single unit against the grey page background.
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(padding: EdgeInsets.zero, title: '${_category.activitySingular} details'),
                  const SizedBox(height: AppDimensions.spaceSm),
                  AppTextField(
                    label: '${_category.activitySingular} title',
                    hint: 'e.g. Kathmandu Sunrise Ride',
                    controller: _titleController,
                    validator: (v) => Validators.required(v, field: 'Title'),
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  AppTextField(
                    label: 'Description',
                    hint: 'Tell riders what to expect',
                    controller: _descriptionController,
                    maxLines: 4,
                    validator: (v) => Validators.required(v, field: 'Description'),
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  AppTextField(
                    label: 'Meeting location',
                    hint: 'e.g. Ratna Park, Kathmandu',
                    controller: _locationController,
                    validator: (v) => Validators.required(v, field: 'Meeting location'),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  const SectionHeader(padding: EdgeInsets.zero, title: 'Schedule'),
                  const SizedBox(height: AppDimensions.spaceSm),
                  Row(
                    children: [
                      Expanded(
                        child: AppDatePickerField(
                          label: 'Date',
                          value: _date,
                          onChanged: (d) => setState(() => _date = d),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceSm),
                      Expanded(
                        child: AppTimePickerField(
                          label: 'Start time',
                          value: _time,
                          onChanged: (t) => setState(() => _time = t),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  const SectionHeader(padding: EdgeInsets.zero, title: 'Details'),
                  const SizedBox(height: AppDimensions.spaceSm),
                  AppDropdown<RideType>(
                    label: 'Type',
                    value: _rideType,
                    items: _category.rideTypes,
                    labelBuilder: (t) => t.label,
                    onChanged: (t) => setState(() => _rideType = t ?? _rideType),
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  AppDropdown<RideDifficulty>(
                    label: 'Difficulty',
                    value: _difficulty,
                    items: RideDifficulty.values,
                    labelBuilder: (d) => d.label,
                    onChanged: (d) => setState(() => _difficulty = d ?? _difficulty),
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Distance (km)',
                          hint: '20',
                          controller: _distanceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => Validators.number(v, field: 'Distance'),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceSm),
                      Expanded(
                        child: AppTextField(
                          label: 'Duration (min)',
                          hint: '90',
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          validator: (v) => Validators.number(v, field: 'Duration'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  AppTextField(
                    label: 'Maximum participants',
                    controller: _maxParticipantsController,
                    keyboardType: TextInputType.number,
                    validator: (v) => Validators.number(v, field: 'Maximum participants'),
                    prefixIcon: const Icon(Icons.groups_outlined),
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  ChipInputField(
                    label: 'Requirements',
                    hint: 'e.g. Helmet, front & rear lights',
                    values: _requirements,
                    onChanged: (r) => setState(() => _requirements = r),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXl),
            AppButton(label: _isEditing ? 'Save changes' : 'Create ${_category.activitySingular}', onPressed: _submit, isLoading: _isSubmitting),
            const SizedBox(height: AppDimensions.spaceLg),
          ],
        ),
      ),
    );
  }
}

/// Loads a ride and opens it in the form for its organizer to edit.
class EditRideScreen extends ConsumerWidget {
  final String rideId;

  const EditRideScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideAsync = ref.watch(rideDetailsProvider(rideId));
    return rideAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const LoadingWidget()),
      error: (e, st) => Scaffold(
        appBar: AppBar(),
        body: AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(rideDetailsProvider(rideId))),
      ),
      data: (ride) => CreateRideScreen(ride: ride),
    );
  }
}
