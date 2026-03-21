import 'package:flutter/material.dart';

/// Theme-aware colors so screens respect light/dark mode instead of hardcoded [kBg]/[kSurface].
extension AppThemeColors on BuildContext {
  Color get appBg => Theme.of(this).scaffoldBackgroundColor;
  Color get appSurface => Theme.of(this).colorScheme.surface;
  Color get appSurface2 => Theme.of(this).colorScheme.surfaceContainerHighest;
  Color get appBorder => Theme.of(this).colorScheme.outline;
  Color get appText => Theme.of(this).colorScheme.onSurface;
  Color get appTextSub => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get appTextMuted => Theme.of(this).colorScheme.onSurfaceVariant.withAlpha(180);
  Color get appShadow => Theme.of(this).colorScheme.shadow;
}
