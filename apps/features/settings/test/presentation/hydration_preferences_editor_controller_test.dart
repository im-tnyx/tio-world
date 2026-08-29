import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_feature_settings/src/presentation/hydration_preferences_editor_controller.dart';

void main() {
  HydrationPreferences p(int ml) =>
      HydrationPreferences(defaultGlassSizeMl: ml);
  HydrationPreferencesEditorController create(int ml) {
    final editor = HydrationPreferencesEditorController(p(ml));
    addTearDown(editor.dispose);
    return editor;
  }

  test('pristine refresh, dirty preservation and canonical convergence', () {
    final editor = create(250);
    expect(editor.canSave, isFalse);
    editor.refresh(p(300));
    expect(editor.draftMl, 300);
    editor.selectPreset(350);
    editor.refresh(p(500));
    expect(editor.draftMl, 350);
    expect(editor.canSave, isTrue);
    editor.refresh(p(350));
    expect(editor.isDirty, isFalse);
  });

  test('reset to default is a 250 ml draft and saves normally', () async {
    final editor = create(300)..resetToDefault();
    final writes = <HydrationPreferences>[];

    expect(editor.draftMl, 250);
    expect(await editor.save((value) async => writes.add(value)), p(250));
    expect(writes, [p(250)]);
  });

  test('invalid custom draft is preserved across refresh and cannot save',
      () async {
    final editor = create(250)..selectCustom();
    var writes = 0;
    for (final text in ['', '55', '255', '2001', 'abc', '250.0', '+250']) {
      editor.setCustomText(text);
      editor.refresh(p(300));
      expect(editor.customText, text);
      expect(editor.canSave, isFalse);
      expect(editor.validationError, isNotNull);
      await editor.save((_) async => writes++);
    }
    expect(writes, 0);
  });

  test('exact custom value saves without rounding', () async {
    final editor = create(250)..setCustomText('760');
    final writes = <HydrationPreferences>[];

    expect(await editor.save((value) async => writes.add(value)), p(760));
    expect(writes, [p(760)]);
  });

  test('awaited save prevents double submit and editing while pending',
      () async {
    final editor = create(250)..selectPreset(300);
    final gate = Completer<void>();
    var calls = 0;
    Future<void> persist(HydrationPreferences value) {
      calls++;
      return gate.future;
    }

    final first = editor.save(persist);
    expect(editor.isSaving, isTrue);
    expect(await editor.save(persist), isNull);
    editor.resetToDefault();
    editor.setCustomText('750');
    editor.selectPreset(500);
    expect(editor.draftMl, 300);
    expect(calls, 1);
    gate.complete();
    expect(await first, p(300));
  });

  test('failure preserves draft and retry succeeds without detail leakage',
      () async {
    final editor = create(250)..selectPreset(300);
    expect(
      await editor
          .save((_) async => throw StateError('private transport detail')),
      isNull,
    );
    expect(editor.draftMl, 300);
    expect(editor.canSave, isTrue);
    expect(editor.saveError, 'Could not save Glass Size. Please try again.');
    expect(await editor.save((_) async {}), p(300));
    expect(editor.saveError, isNull);
  });
}
