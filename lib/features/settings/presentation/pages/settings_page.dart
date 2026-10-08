import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/onboarding/showcase_tour.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _replayTour(BuildContext context) async {
    await ShowcaseTour.resetAll();
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ShowcaseTour.startIfFirstTime(
      canStart: () => true,
      delay: const Duration(milliseconds: 450),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.isDark,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text('Pengaturan', style: AppTheme.heading3),
          backgroundColor: AppTheme.background,
          surfaceTintColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.paddingPage,
            AppTheme.spaceSm,
            AppTheme.paddingPage,
            AppTheme.space2xl,
          ),
          children: [
            const _SectionLabel('Tampilan'),
            _Card(
              child: _Tile(
                icon: isDark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                title: 'Mode gelap',
                subtitle: isDark ? 'Aktif' : 'Nonaktif',
                selected: isDark,
                onTap: () => ThemeController.setMode(
                  isDark ? ThemeMode.light : ThemeMode.dark,
                ),
                trailing: Switch.adaptive(
                  value: isDark,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppTheme.primary,
                  onChanged: (on) => ThemeController.setMode(
                    on ? ThemeMode.dark : ThemeMode.light,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceXl),
            const _SectionLabel('Panduan'),
            _Card(
              child: _Tile(
                icon: Icons.tips_and_updates_outlined,
                title: 'Ulangi tur aplikasi',
                subtitle: 'Tampilkan lagi panduan cara pakai',
                onTap: () => _replayTour(context),
              ),
            ),
            const SizedBox(height: AppTheme.spaceXl),
            const _SectionLabel('Tentang'),
            _Card(child: _About(isDark: isDark)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppTheme.spaceSm),
      child: Text(
        text.toUpperCase(),
        style: AppTheme.caption.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool selected;

  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceLg,
            vertical: AppTheme.spaceMd,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryLight : AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.label),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTheme.bodySmall),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textHint,
                    size: 20,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _About extends StatelessWidget {
  final bool isDark;
  const _About({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceXl,
      ),
      child: Column(
        children: [
          Image.asset(
            isDark
                ? 'assets/branding/logo_horizontal.png'
                : 'assets/branding/logo_horizontal_light.png',
            width: 180,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            'Bagi tagihan bareng temen, tanpa ribet.',
            style: AppTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceMd),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              return Text(
                info == null
                    ? ' '
                    : 'Versi ${info.version} (${info.buildNumber})',
                style: AppTheme.caption,
              );
            },
          ),
        ],
      ),
    );
  }
}
