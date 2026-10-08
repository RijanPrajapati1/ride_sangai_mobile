import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authControllerProvider.notifier).sendPasswordReset(_emailController.text.trim());
    if (success && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AuthScaffold(
      title: _sent ? 'Check your inbox' : 'Forgot your password?',
      subtitle: _sent
          ? 'A reset link is on its way.'
          : "Enter your account's email and we'll send you a reset link.",
      showBack: true,
      child: _sent ? _buildSuccess(context) : _buildForm(context, authState.isLoading),
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Email',
            hint: 'you@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            prefixIcon: const Icon(Icons.mail_outline),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          AppButton(label: 'Send Reset Link', onPressed: _submit, isLoading: isLoading),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppDimensions.spaceMd),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(color: context.appColors.primaryLight, shape: BoxShape.circle),
          child: const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        Text(
          'We sent a password reset link to ${_emailController.text.trim()}. '
          "It can take a minute; check your spam folder if it doesn't arrive.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        AppButton(label: 'Back to Log In', onPressed: () => Navigator.of(context).maybePop()),
      ],
    );
  }
}
