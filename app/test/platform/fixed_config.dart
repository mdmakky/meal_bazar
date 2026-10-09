import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:meal_bazar/core/platform/platform_config.dart';

class _Fixed extends PlatformConfigNotifier {
  _Fixed(this.config);

  final PlatformConfig config;

  @override
  PlatformConfig build() => config;
}

/// Pins the platform config to [json] (no cache, no network).
Override platformConfig(Map<String, Object?> json) => platformConfigProvider
    .overrideWith(() => _Fixed(PlatformConfig.fromJson(json)));

/// Features [off] set to false.
Override flagsOff(List<String> off) => platformConfig({
  'features': {for (final f in off) f: false},
});
