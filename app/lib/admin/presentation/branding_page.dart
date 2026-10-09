import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/widgets/widgets.dart';
import '../application/admin_providers.dart';
import '../domain/config_schema.dart';
import 'common.dart';
import 'config_editor.dart';
import 'settings_page.dart' show textField;

/// Picks an image; returns its bytes and extension, or null on cancel.
typedef LogoPicker = Future<({List<int> bytes, String ext})?> Function();

Future<({List<int> bytes, String ext})?> _pickWithImagePicker() async {
  final f = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (f == null) return null;
  final dot = f.name.lastIndexOf('.');
  final ext = dot < 0 ? 'png' : f.name.substring(dot + 1);
  return (bytes: await f.readAsBytes(), ext: ext == 'jpg' ? 'jpeg' : ext);
}

final logoPickerProvider = Provider<LogoPicker>((ref) => _pickWithImagePicker);

class BrandingPage extends ConsumerWidget {
  const BrandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return ref
        .watch(platformConfigAdminProvider)
        .when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: adminErrorText(context, e),
            onRetry: () => ref.invalidate(platformConfigAdminProvider),
          ),
          data: (c) => AdminPage(
            title: l.adminNavBranding,
            child: BrandingEditor(saved: c['branding']),
          ),
        );
  }
}

class BrandingEditor extends ConsumerWidget {
  const BrandingEditor({super.key, required this.saved});

  final Object? saved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return ConfigKeyEditor(
      configKey: 'branding',
      title: l.adminNavBranding,
      subtitle: l.adminBrandingReleaseNote,
      saved: saved,
      builder: (context, d, changed) {
        final m = d as Map;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.md,
          children: [
            FieldRow(
              children: [
                textField(
                  context,
                  m,
                  'app_name_bn',
                  l.adminAppNameBn,
                  rule: requiredText,
                ),
                textField(
                  context,
                  m,
                  'app_name_en',
                  l.adminAppNameEn,
                  rule: requiredText,
                ),
              ],
            ),
            FieldRow(
              children: [
                textField(context, m, 'tagline_bn', l.adminTaglineBn),
                textField(context, m, 'tagline_en', l.adminTaglineEn),
              ],
            ),
            SubHeading(l.adminLogo),
            _LogoField(m: m, changed: changed),
            SubHeading(l.adminAccent),
            FieldRow(
              children: [
                _AccentField(
                  m: m,
                  field: 'accent_light',
                  label: l.adminAccentLight,
                  surfaces: [AppPalette.light.surface, AppPalette.light.bg],
                  changed: changed,
                ),
                _AccentField(
                  m: m,
                  field: 'accent_dark',
                  label: l.adminAccentDark,
                  surfaces: [AppPalette.dark.surface, AppPalette.dark.bg],
                  changed: changed,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LogoField extends ConsumerStatefulWidget {
  const _LogoField({required this.m, required this.changed});

  final Map m;
  final VoidCallback changed;

  @override
  ConsumerState<_LogoField> createState() => _LogoFieldState();
}

class _LogoFieldState extends ConsumerState<_LogoField> {
  bool _busy = false;
  String? _error;

  Future<void> _upload() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picked = await ref.read(logoPickerProvider)();
      if (picked == null) return;
      final url = await ref
          .read(adminRepositoryProvider)
          .uploadLogo(Uint8List.fromList(picked.bytes), picked.ext);
      widget.m['logo_url'] = url;
      widget.changed();
    } catch (e) {
      if (mounted) setState(() => _error = adminErrorText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final url = widget.m['logo_url'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.sm,
      children: [
        Row(
          spacing: AppSpace.lg,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                border: Border.all(color: p.border),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: url == null
                  ? Text('ম', style: Theme.of(context).textTheme.headlineSmall)
                  : Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          Icon(Icons.broken_image, color: p.inkTertiary),
                    ),
            ),
            AppButton(
              label: url == null ? l.adminLogoUpload : l.adminLogoReplace,
              icon: Icons.upload,
              loading: _busy,
              variant: AppButtonVariant.secondary,
              onPressed: _busy ? null : _upload,
            ),
            if (url != null)
              TextButton(
                onPressed: () {
                  widget.m['logo_url'] = null;
                  widget.changed();
                },
                child: Text(l.adminLogoRemove),
              ),
          ],
        ),
        Text(
          url == null ? l.adminLogoDefault : l.adminLogoSaveHint,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        if (_error != null) Text(_error!, style: TextStyle(color: p.due)),
      ],
    );
  }
}

class _AccentField extends StatelessWidget {
  const _AccentField({
    required this.m,
    required this.field,
    required this.label,
    required this.surfaces,
    required this.changed,
  });

  final Map m;
  final String field;
  final String label;

  /// The theme surfaces the accent sits on (surface, bg).
  final List<Color> surfaces;
  final VoidCallback changed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final color = parseHex(m[field] as String?);
    final ratio = color == null
        ? null
        : surfaces
              .map((s) => contrastRatio(color, s))
              .reduce((a, b) => a < b ? a : b);
    final ok = ratio != null && ratio >= minAccentContrast;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [
        TextFormField(
          initialValue: '${m[field] ?? ''}',
          decoration: InputDecoration(labelText: label, helperText: '#RRGGBB'),
          validator: (v) => invalidText(context, hexColor(v)),
          onChanged: (v) {
            m[field] = v.trim();
            changed();
          },
        ),
        // Preview on the surface it will sit on.
        Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: surfaces.first,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            spacing: AppSpace.sm,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color ?? Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.borderStrong),
                ),
              ),
              Expanded(
                child: Text(
                  ratio == null
                      ? l.adminErrHex
                      : l.adminContrast(ratio.toStringAsFixed(2)),
                  style: TextStyle(
                    color: surfaces.first.computeLuminance() > 0.5
                        ? AppPalette.light.ink
                        : AppPalette.dark.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (ratio != null)
          Text(
            ok ? l.adminContrastOk : l.adminContrastLow,
            style: TextStyle(color: ok ? p.advance : p.warning),
          ),
      ],
    );
  }
}
