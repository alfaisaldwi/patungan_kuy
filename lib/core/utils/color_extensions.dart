import 'package:flutter/material.dart';

extension ColorOpacity on Color {
  Color withOpacityValue(double opacity) =>
      withValues(alpha: opacity.clamp(0.0, 1.0));
}
