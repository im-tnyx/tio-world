import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

Map<String, Color> _colorFields(TioColors colors) => {
      'primary': colors.primary,
      'onPrimary': colors.onPrimary,
      'background': colors.background,
      'surface': colors.surface,
      'surfaceRaised': colors.surfaceRaised,
      'surfaceVariant': colors.surfaceVariant,
      'outlineStrong': colors.outlineStrong,
      'textPrimary': colors.textPrimary,
      'textSecondary': colors.textSecondary,
      'textMuted': colors.textMuted,
      'mediaBackground': colors.mediaBackground,
      'onMediaPrimary': colors.onMediaPrimary,
      'onMediaSecondary': colors.onMediaSecondary,
      'success': colors.success,
      'warning': colors.warning,
      'danger': colors.danger,
      'info': colors.info,
      'workout': colors.workout,
      'nutrition': colors.nutrition,
      'progress': colors.progress,
      'coach': colors.coach,
    };

void main() {
  group('TioColors.lerp', () {
    test('preserves exact source and destination colors at endpoints', () {
      const source = TioColors.light;
      const destination = TioColors.dark;

      final atStart = source.lerp(destination, 0);
      final atEnd = source.lerp(destination, 1);
      final sourceFields = _colorFields(source);
      final destinationFields = _colorFields(destination);

      for (final entry in sourceFields.entries) {
        expect(
          _colorFields(atStart)[entry.key],
          entry.value,
          reason: '${entry.key} must preserve the source value at t=0',
        );
      }
      for (final entry in destinationFields.entries) {
        expect(
          _colorFields(atEnd)[entry.key],
          entry.value,
          reason: '${entry.key} must preserve the destination value at t=1',
        );
      }
    });

    test('interpolates every semantic color through Color.lerp', () {
      const source = TioColors.light;
      const destination = TioColors.oled;
      const t = 0.35;

      final actual = source.lerp(destination, t);
      final sourceFields = _colorFields(source);
      final destinationFields = _colorFields(destination);
      final actualFields = _colorFields(actual);

      expect(actualFields.keys, sourceFields.keys);
      expect(destinationFields.keys, sourceFields.keys);

      for (final entry in sourceFields.entries) {
        expect(
          actualFields[entry.key],
          Color.lerp(entry.value, destinationFields[entry.key], t),
          reason: '${entry.key} must use Color.lerp at intermediate t',
        );
      }
    });

    test('switches the discrete darkness flag at the midpoint', () {
      expect(TioColors.light.lerp(TioColors.dark, 0).isDark, isFalse);
      expect(TioColors.light.lerp(TioColors.dark, 0.499).isDark, isFalse);
      expect(TioColors.light.lerp(TioColors.dark, 0.5).isDark, isTrue);
      expect(TioColors.light.lerp(TioColors.dark, 1).isDark, isTrue);

      expect(TioColors.dark.lerp(TioColors.light, 0.499).isDark, isTrue);
      expect(TioColors.dark.lerp(TioColors.light, 0.5).isDark, isFalse);
    });

    test('returns the current extension when the destination is missing', () {
      const source = TioColors.light;

      expect(identical(source.lerp(null, 0.5), source), isTrue);
    });
  });
}
