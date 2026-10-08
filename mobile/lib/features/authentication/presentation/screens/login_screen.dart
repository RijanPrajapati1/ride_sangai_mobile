import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(authControllerProvider).error ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Log in to find your next ride and catch up with your crew.',
      child: Form(
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
            const SizedBox(height: AppDimensions.spaceMd),
            AppTextField(
              label: 'Password',
              hint: 'Enter your password',
              controller: _passwordController,
              obscureText: _obscure,
              validator: Validators.password,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                tooltip: _obscure ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(RouteNames.forgotPassword),
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            AppButton(label: 'Log In', onPressed: _submit, isLoading: authState.isLoading),
            const SizedBox(height: AppDimensions.spaceMd),
            // Wraps rather than overflowing with large text sizes.
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text("Don't have an account?"),
                TextButton(
                  onPressed: () => context.push(RouteNames.register),
                  child: const Text('Create one'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
