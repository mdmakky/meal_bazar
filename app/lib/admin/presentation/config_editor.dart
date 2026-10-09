import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../application/admin_providers.dart';
import '../domain/config_schema.dart';
import 'common.dart';

typedef DraftBuilder =
    Widget Function(BuildContext context, dynamic draft, VoidCallback changed);

/// Edits one platform_config key. Holds a deep-copied draft (server value
/// over defaults); Save validates the form, then [validate] on the whole
/// draft, then [beforeSave] (a confirm dialog), then `admin_set_config`.
class ConfigKeyEditor extends ConsumerStatefulWidget {
  const ConfigKeyEditor({
    super.key,
    required this.configKey,
    required this.title,
    required this.saved,
    required this.builder,
    this.subtitle,
    this.validate,
    this.beforeSave,
  });

  final String configKey;
  final String title;
  final String? subtitle;
  final Object? saved;
  final DraftBuilder builder;
  final String? Function(BuildContext context, dynamic draft)? validate;
  final Future<bool> Function(BuildContext context, dynamic draft)? beforeSave;

  @override
  ConsumerState<ConfigKeyEditor> createState() => ConfigKeyEditorState();
}

class ConfigKeyEditorState extends ConsumerState<ConfigKeyEditor> {
  final _form = GlobalKey<FormState>();
  late dynamic draft = withDefaults(widget.configKey, widget.saved);
  bool _saving = false;
  String? _error;

  void changed() => setState(() {});

  Future<void> save() async {
    setState(() => _error = null);
    if (!(_form.currentState?.validate() ?? true)) return;
    final err = widget.validate?.call(context, draft);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    if (widget.beforeSave != null &&
        !await widget.beforeSave!(context, draft)) {
      return;
    }
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .setConfig(widget.configKey, deepCopy(draft) as Object);
      ref.invalidate(platformConfigAdminProvider);
      if (mounted) showSnack(context, l.adminSaved);
    } catch (e) {
      if (mounted) setState(() => _error = adminErrorText(context, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Form(
      key: _form,
      child: widget.builder(context, draft, changed),
    );
    return ConfigSection(
      title: widget.title,
      subtitle: widget.subtitle,
      saved: widget.saved,
      saving: _saving,
      error: _error,
      onSave: _saving ? null : save,
      child: body,
    );
  }
}
