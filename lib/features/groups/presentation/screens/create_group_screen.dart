import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/group_providers.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final group = await ref.read(groupActionsControllerProvider).create(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${group.name}" was created!')),
    );
    context.pushReplacement(RouteNames.groupChatPath(group.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          children: [
            AppTextField(
              label: 'Group name',
              hint: 'e.g. Kathmandu Riders',
              controller: _nameController,
              validator: (v) => Validators.required(v, field: 'Group name'),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            AppTextField(
              label: 'Description',
              hint: 'What is this group about?',
              controller: _descriptionController,
              maxLines: 4,
              validator: (v) => Validators.required(v, field: 'Description'),
            ),
            const SizedBox(height: AppDimensions.spaceXl),
            AppButton(label: 'Create Group', onPressed: _submit, isLoading: _isSubmitting),
          ],
        ),
      ),
    );
  }
}
