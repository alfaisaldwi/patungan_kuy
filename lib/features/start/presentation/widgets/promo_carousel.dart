import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  static const _banners = [
    (
      icon: Icons.groups_rounded,
      title: 'Patungan? Kuy!',
      subtitle: 'Split bill bareng temen jadi gampang & adil',
      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    ),
    (
      icon: Icons.document_scanner_rounded,
      title: 'Scan struk otomatis',
      subtitle: 'Foto struknya, item & harga kebaca sendiri',
      colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    ),
    (
      icon: Icons.campaign_rounded,
      title: 'Slot promo kamu di sini',
      subtitle: 'Siap dipakai buat iklan & penawaran spesial',
      colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    ),
  ];

  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _banners.length,
          options: CarouselOptions(
            height: 130,
            viewportFraction: 0.92,
            enlargeCenterPage: true,
            enlargeFactor: 0.16,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 700),
            autoPlayCurve: Curves.easeOutCubic,
            onPageChanged: (i, _) => setState(() => _page = i),
          ),
          itemBuilder: (_, i, _) {
            final banner = _banners[i];
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(AppTheme.paddingCard),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: banner.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: [AppTheme.shadowSm],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(46),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Text(
                            'Promo',
                            style: AppTheme.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceSm),
                        Text(
                          banner.title,
                          style: AppTheme.heading3.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          banner.subtitle,
                          style: AppTheme.caption.copyWith(
                            color: Colors.white.withAlpha(217),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMd),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(38),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(banner.icon, color: Colors.white, size: 26),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppTheme.primary : AppTheme.disabled,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
