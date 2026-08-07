import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../calculator/presentation/pages/calculator_page.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../widgets/promo_carousel.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  void _open(BuildContext context, CalculatorStartAction action) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => HomePage(startAction: action)));
  }

  void _openHistory(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HomePage(initialTab: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spaceLg),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppTheme.primaryGradient,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [AppTheme.shadowSm],
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMd),
                  Text('PatunganKuy', style: AppTheme.heading3),
                  const Spacer(),
                  IconButton(
                    tooltip: AppTheme.isDark ? 'Mode terang' : 'Mode gelap',
                    onPressed: ThemeController.toggle,
                    icon: Icon(
                      AppTheme.isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space2xl),
              Text(
                'Mau bagi tagihan\ngimana?',
                style: AppTheme.heading1.copyWith(fontSize: 28, height: 1.2),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              Text(
                'Pilih cara masukin pesanan. Sisanya biar '
                'PatunganKuy yang hitungin.',
                style: AppTheme.body.copyWith(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.space2xl),
              _ChoiceCard(
                icon: Icons.document_scanner_rounded,
                iconBg: AppTheme.primaryLight,
                iconColor: AppTheme.primary,
                title: 'Scan Struk',
                badge: 'OTOMATIS',
                description:
                    'Foto atau pilih gambar struk. Item & harga kebaca '
                    'otomatis, tinggal dibagi ke temen.',
                onTap: () => _open(context, CalculatorStartAction.scan),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              _ChoiceCard(
                icon: Icons.edit_note_rounded,
                iconBg: AppTheme.accentLight,
                iconColor: AppTheme.accent,
                title: 'Tulis Manual',
                description:
                    'Ketik sendiri pesanan tiap orang. '
                    'Cocok buat tagihan yang simpel.',
                onTap: () => _open(context, CalculatorStartAction.manual),
              ),
              const SizedBox(height: AppTheme.space2xl),
              const PromoCarousel(),
              const SizedBox(height: AppTheme.spaceLg),
              TextButton(
                onPressed: () => _openHistory(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 44),
                  alignment: Alignment.centerLeft,
                ),
                child: Text(
                  'Lihat riwayat tagihan',
                  style: AppTheme.label.copyWith(
                    color: AppTheme.primary,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space2xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? badge;
  final String description;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.badge,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: [AppTheme.shadowSm],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingCard + 4),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: AppTheme.spaceLg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: AppTheme.label.copyWith(fontSize: 16),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: AppTheme.spaceSm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull,
                                ),
                              ),
                              child: Text(
                                badge!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: AppTheme.bodySmall.copyWith(height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
