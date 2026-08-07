import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../scanner/presentation/bloc/scanner_bloc.dart';

void showScanPicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusXl),
      ),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.disabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            title: Text('Kamera', style: AppTheme.body),
            subtitle: Text(
              'Langsung foto struk kamu',
              style: AppTheme.bodySmall,
            ),
            onTap: () {
              Navigator.pop(context);
              context.read<ScannerBloc>().add(
                const PickAndScanImage(fromCamera: true),
              );
            },
          ),
          const Divider(indent: 56),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accentLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.photo_library,
                color: AppTheme.accent,
                size: 20,
              ),
            ),
            title: Text('Galeri', style: AppTheme.body),
            subtitle: Text(
              'Pilih foto struk dari galeri',
              style: AppTheme.bodySmall,
            ),
            onTap: () {
              Navigator.pop(context);
              context.read<ScannerBloc>().add(const PickAndScanImage());
            },
          ),
        ],
      ),
    ),
  );
}
