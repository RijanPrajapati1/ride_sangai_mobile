import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/chip_input_field.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_providers.dart';
import '../widgets/avatar_picker.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider(AppConstants.currentUserId));

    return Scaffold(
      appBar: const AppAppBar(title: 'Edit Profile'),
      body: profileAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, st) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(profileProvider(AppConstants.currentUserId)),
        ),
        data: (profile) => _EditProfileForm(profile: profile),
      ),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  final UserProfile profile;

  const _EditProfileForm({required this.profile});

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late String _avatarUrl;
  late ExperienceLevel _experienceLevel;
  late RideType _preferredRideType;
  late List<String> _interests;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _bioController = TextEditingController(text: widget.profile.bio);
    _locationController = TextEditingController(text: widget.profile.location);
    _avatarUrl = widget.profile.avatarUrl;
    _experienceLevel = widget.profile.experienceLevel;
    _preferredRideType = widget.profile.preferredRideType;
    _interests = List.of(widget.profile.cyclingInterests);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final updated = widget.profile.copyWith(
      name: _nameController.text.trim(),
      avatarUrl: _avatarUrl,
      bio: _bioController.text.trim(),
      location: _locationController.text.trim(),
      experienceLevel: _experienceLevel,
      preferredRideType: _preferredRideType,
      cyclingInterests: _interests,
    );
    await ref.read(profileControllerProvider).updateProfile(updated);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: [
          Center(
            child: AvatarPicker(
              name: widget.profile.name,
              avatarUrl: _avatarUrl,
              onChanged: (url) => setState(() => _avatarUrl = url),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          AppTextField(
            label: 'Name',
            controller: _nameController,
            validator: (v) => Validators.required(v, field: 'Name'),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppTextField(
            label: 'Bio',
            controller: _bioController,
            maxLines: 3,
            validator: (v) => Validators.required(v, field: 'Bio'),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppTextField(
            label: 'Location',
            controller: _locationController,
            validator: (v) => Validators.required(v, field: 'Location'),
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppDropdown<ExperienceLevel>(
            label: 'Experience',
            value: _experienceLevel,
            items: ExperienceLevel.values,
            labelBuilder: (e) => e.label,
            onChanged: (v) => setState(() => _experienceLevel = v ?? _experienceLevel),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppDropdown<RideType>(
            label: 'Preferred ride type',
            value: _preferredRideType,
            items: RideType.values,
            labelBuilder: (t) => t.label,
            onChanged: (v) => setState(() => _preferredRideType = v ?? _preferredRideType),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          ChipInputField(
            label: 'Cycling interests',
            hint: 'e.g. Hill Climbs, Gravel',
            values: _interests,
            onChanged: (v) => setState(() => _interests = v),
          ),
          const SizedBox(height: AppDimensions.spaceXl),
          AppButton(label: 'Save Changes', onPressed: _save, isLoading: _isSaving),
        ],
      ),
    );
  }
}
