import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can always log back in with the same account.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) context.go(RouteNames.login);
    }
  }

  static String _message(Object error) =>
      error is AppException ? error.message : 'Something went wrong. Please try again.';

  /// Saves one or more toggles and shows the server's message if it fails.
  Future<void> _save(BuildContext context, Future<void> Function() change) async {
    try {
      await change();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_message(e))));
      }
    }
  }

  Future<void> _setThemeMode(WidgetRef ref, ThemeMode mode) async {
    await ref.read(themeModeProvider.notifier).setThemeMode(mode);
    // Keep the account's dark-mode preference in sync (best effort: the theme
    // is applied locally either way).
    try {
      await ref.read(profileControllerProvider).setPreferences(darkModeEnabled: mode == ThemeMode.dark);
    } on AppException {
      // Ignored: offline or server error; the local theme still changed.
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );
    if (password == null || !context.mounted) return;
    try {
      await ref.read(profileControllerProvider).deleteAccount(password);
      if (context.mounted) context.go(RouteNames.login);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_message(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(userPreferencesProvider);
    final themeMode = ref.watch(themeModeProvider);
    final controller = ref.read(profileControllerProvider);

    return Scaffold(
      appBar: const AppAppBar(title: 'Settings'),
      body: preferencesAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, st) => AppErrorWidget(message: _message(e), onRetry: () => ref.invalidate(userPreferencesProvider)),
        data: (prefs) => ListView(
          children: [
            const _SectionLabel('Account'),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Edit Profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RouteNames.editProfile),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Privacy'),
              trailing: Switch(
                value: prefs.publicProfile,
                onChanged: (v) => _save(context, () => controller.setPreferences(publicProfile: v)),
              ),
              subtitle: const Text('Make my profile visible to other riders'),
            ),
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Show riding stats'),
              trailing: Switch(
                value: prefs.showRidingStats,
                onChanged: (v) => _save(context, () => controller.setPreferences(showRidingStats: v)),
              ),
            ),
            const Divider(height: 1),
            const _SectionLabel('Notifications'),
            SwitchListTile(
              secondary: const Icon(Icons.alarm),
              title: const Text('Ride reminders'),
              value: prefs.pushRideReminders,
              onChanged: (v) => _save(context, () => controller.setPreferences(pushRideReminders: v)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.chat_bubble_outline),
              title: const Text('Messages'),
              value: prefs.pushMessages,
              onChanged: (v) => _save(context, () => controller.setPreferences(pushMessages: v)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.groups_outlined),
              title: const Text('Community activity'),
              value: prefs.pushCommunityActivity,
              onChanged: (v) => _save(context, () => controller.setPreferences(pushCommunityActivity: v)),
            ),
            const Divider(height: 1),
            const _SectionLabel('Appearance'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd, vertical: AppDimensions.spaceXs),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto_outlined)),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
                ],
                selected: {themeMode},
                onSelectionChanged: (selection) => _setThemeMode(ref, selection.first),
              ),
            ),
            const Divider(height: 1),
            const _SectionLabel('Support'),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support articles coming soon')),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.rate_review_outlined),
              title: const Text('Send feedback'),
              subtitle: const Text('Report a bug or share an idea'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RouteNames.feedback),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Yatrix'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: AppConstants.appVersion,
                applicationLegalese: AppConstants.appTagline,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd),
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context, ref),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd),
              child: TextButton.icon(
                onPressed: () => _confirmDeleteAccount(context, ref),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Delete Account'),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXl),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDimensions.spaceMd, AppDimensions.spaceMd, AppDimensions.spaceMd, AppDimensions.spaceXs),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Asks for the password before permanently deleting the account. Pops the
/// entered password, or null when cancelled.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This permanently removes your account and everything you own: rides, posts, groups and messages. '
            'Enter your password to confirm.',
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Password'),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: _passwordController.text.isEmpty
              ? null
              : () => Navigator.of(context).pop(_passwordController.text),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
