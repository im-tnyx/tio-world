import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_feature_settings/src/presentation/hydration_preferences_editor_controller.dart';

void main() {
  HydrationPreferences p(int? ml) =>
      HydrationPreferences(defaultGlassSizeMl: ml);
  HydrationPreferencesEditorController create(int? ml) {
    final editor = HydrationPreferencesEditorController(p(ml));
    addTearDown(editor.dispose);
    return editor;
  }

  test('pristine hydration, dirty preservation and canonical convergence', () {
    final editor = create(null);
    expect(editor.canSave, isFalse);
    editor.refresh(p(250));
    expect(editor.draftMl, 250);
    expect(editor.canSave, isFalse);
    editor.selectPreset(300);
    editor.refresh(p(350));
    expect(editor.draftMl, 300);
    expect(editor.canSave, isTrue);
    editor.refresh(p(300));
    expect(editor.isDirty, isFalse);
    editor.refresh(p(500));
    expect(editor.draftMl, 500);
  });

  test('dirty clear converges with both null object and absent canonical row',
      () {
    final editor = create(250)..clear();
    expect(editor.canSave, isTrue);
    editor.refresh(null);
    expect(editor.isDirty, isFalse);
    editor.refresh(p(300));
    expect(editor.draftMl, 300);
  });

  test('invalid/empty custom draft is not replaced by refresh and cannot save',
      () async {
    final editor = create(null)..selectCustom();
    var writes = 0;
    for (final text in ['', '55', '255', '2001', 'abc', '250.0', '+250']) {
      editor.setCustomText(text);
      editor.refresh(p(300));
      expect(editor.customText, text);
      expect(editor.canSave, isFalse);
      expect(editor.validationError, isNotNull);
      await editor.save((_) async {
        writes++;
      });
    }
    expect(writes, 0);
  });

  test('exact custom value saves, and Clear saves an explicit null', () async {
    final editor = create(250)..setCustomText('260');
    final writes = <HydrationPreferences>[];
    expect(await editor.save((p) async => writes.add(p)), p(260));
    expect(editor.canSave, isFalse);
    editor.clear();
    expect(await editor.save((p) async => writes.add(p)), p(null));
    expect(writes, [p(260), p(null)]);
  });

  test('awaited save prevents duplicate submits and editing while pending',
      () async {
    final editor = create(250)..selectPreset(300);
    final gate = Completer<void>();
    var calls = 0;
    Future<void> persist(HydrationPreferences p) {
      calls++;
      return gate.future;
    }

    final first = editor.save(persist);
    expect(editor.isSaving, isTrue);
    expect(await editor.save(persist), isNull);
    editor.clear();
    editor.setCustomText('750');
    editor.selectPreset(500);
    expect(editor.draftMl, 300);
    expect(calls, 1);
    gate.complete();
    expect(await first, p(300));
  });

  test(
      'failure preserves draft and retry succeeds without leaking error details',
      () async {
    final editor = create(250)..selectPreset(300);
    expect(
        await editor
            .save((_) async => throw StateError('private transport detail')),
        isNull);
    expect(editor.draftMl, 300);
    expect(editor.canSave, isTrue);
    expect(editor.saveError, 'Could not save Glass Size. Please try again.');
    expect(await editor.save((_) async {}), p(300));
    expect(editor.saveError, isNull);
  });
}
