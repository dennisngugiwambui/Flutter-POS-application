import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_repository.dart';
import '../domain/shop_settings_model.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final settingsProvider = FutureProvider<ShopSettingsModel>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return await repository.getSettings();
});
