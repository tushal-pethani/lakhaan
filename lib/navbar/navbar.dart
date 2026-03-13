import 'dart:convert';

import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../clients/client_screen.dart';
import '../profile/profile_screen.dart';
import '../login/login_screen.dart';
import '../storage/app_data_store.dart';
import '../theme/app_theme.dart';
import '../services/translation_service.dart';

/// Flutter version of the React `Navbar` component.
///
/// Props roughly mirror the React version:
/// - [onNewInvoice]: callback when user taps "Add New Invoice" in the drawer.
/// - [onLogout]: optional callback when user logs out (defaults to simple Navigator pop to `/login` route name).
/// - [userName], [userEmail]: current user's display info.
class Navbar extends StatefulWidget implements PreferredSizeWidget {
  const Navbar({
    super.key,
    this.onNewInvoice,
    this.onLogout,
    this.userName,
    this.userEmail,
  });

  final VoidCallback? onNewInvoice;
  final VoidCallback? onLogout;
  final String? userName;
  final String? userEmail;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  void _pushPage(Widget page, {bool clearStack = false}) {
    if (clearStack) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => page),
        (route) => false,
      );
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }
  }

  String get _avatarLetter {
    final name = widget.userName;
    if (name != null && name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return 'U';
  }

  Widget _buildAvatar(ThemeData theme) {
    return ValueListenableBuilder<StoredProfile?>(
      valueListenable: AppDataStore.instance.profileNotifier,
      builder: (context, profile, child) {
        final logoBase64 = profile?.companyLogoBase64;

        if (logoBase64 != null && logoBase64.isNotEmpty) {
          try {
            return Image.memory(
              base64Decode(logoBase64),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildLetterAvatar(theme),
            );
          } catch (e) {
            return _buildLetterAvatar(theme);
          }
        }
        return _buildLetterAvatar(theme);
      },
    );
  }

  Widget _buildLetterAvatar(ThemeData theme) {
    return Align(
      alignment: Alignment.center,
      child: Text(
        _avatarLetter,
        style: theme.textTheme.labelMedium!.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      centerTitle: false,
      titleSpacing: 0,
      leadingWidth: 64,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: RichText(
        text: TextSpan(
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          children: [
            const TextSpan(text: 'Lakh'),
            TextSpan(
              text: 'aan',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.language_rounded),
          tooltip: 'Change Language',
          onSelected: (code) {
            TranslationService.instance.setLanguage(code);
            AppDataStore.instance.settings.languageCode = code;
            AppDataStore.instance.saveSettings(); // Optional: if you have a save settings explicitly, or we can just rely on the in-memory persistence for now if not implemented. We should add a save method properly.
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'en',
              child: Text('English'),
            ),
            const PopupMenuItem(
              value: 'gu',
              child: Text('ગુજરાતી'),
            ),
            const PopupMenuItem(
              value: 'hi',
              child: Text('हिन्दी'),
            ),
          ],
        ),
        IconButton(
          icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round),
          tooltip: 'Toggle Theme',
          onPressed: AppTheme.toggleTheme,
        ),
        GestureDetector(
          onTap: () => showProfileDialog(context),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildAvatar(theme),
          ),
        ),
      ],
    );
  }
}

/// Drawer that mirrors the React sidebar overlay menu.
///
/// Use together with [Navbar] by setting it as the `drawer` of your `Scaffold`.
class NavbarDrawer extends StatelessWidget {
  const NavbarDrawer({
    super.key,
    this.onNewInvoice,
    this.onLogout,
    this.userName,
    this.userEmail,
  });

  final VoidCallback? onNewInvoice;
  final VoidCallback? onLogout;
  final String? userName;
  final String? userEmail;

  void _pushPage(BuildContext context, Widget page, {bool clearStack = false}) {
    Navigator.of(context).pop(); // close drawer
    if (clearStack) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => page),
        (route) => false,
      );
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }
  }

  String get _avatarLetter {
    final name = userName;
    if (name != null && name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      children: [
                        const TextSpan(text: 'Lakh'),
                        TextSpan(
                          text: 'aan',
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard_outlined),
                    title: Text('Dashboard'.tr),
                    onTap: () => _pushPage(
                      context,
                      const DashboardScreen(),
                      clearStack: true,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.group_outlined),
                    title: Text('Add New Client'.tr),
                    onTap: () => _pushPage(context, const ClientsScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text('Logout'.tr),
                    onTap: () {
                      Navigator.of(context).pop();
                      if (onLogout != null) {
                        onLogout!();
                      }
                      // Let _AuthGate handle the screen redirection when auth state changes.
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _avatarLetter,
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName ?? 'User',
                          style: theme.textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (userEmail != null)
                          Text(
                            userEmail!,
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
