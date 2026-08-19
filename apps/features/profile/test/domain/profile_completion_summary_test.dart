import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  group('ProfileCompletionSummary', () {
    test('only Mobile missing reports 83 percent', () {
      final summary = ProfileCompletionSummary.fromFields(
        name: 'Rahul Sharma',
        username: 'rahul_fit',
        email: 'rahul@example.com',
        mobile: null,
        hasGender: true,
        hasDateOfBirth: true,
      );

      expect(summary.percentage, 83);
      expect(summary.isComplete, isFalse);
      expect(summary.missingFields, {ProfileCompletionField.mobile});
      expect(summary.hasAccountOwnedMissingField, isTrue);
      expect(summary.hasProfileOwnedMissingField, isFalse);
    });

    test('counts each personal identity field independently', () {
      final summary = ProfileCompletionSummary.fromFields(
        name: '',
        username: null,
        email: 'rahul@example.com',
        mobile: '',
        hasGender: false,
        hasDateOfBirth: true,
      );

      expect(summary.completedFields, {
        ProfileCompletionField.email,
        ProfileCompletionField.dateOfBirth,
      });
      expect(summary.percentage, 33);
      expect(summary.hasAccountOwnedMissingField, isTrue);
      expect(summary.hasProfileOwnedMissingField, isTrue);
    });

    test('all six fields complete reports 100 percent', () {
      final summary = ProfileCompletionSummary.fromFields(
        name: 'Rahul Sharma',
        username: 'rahul_fit',
        email: 'rahul@example.com',
        mobile: '+91 9876543210',
        hasGender: true,
        hasDateOfBirth: true,
      );

      expect(summary.percentage, 100);
      expect(summary.isComplete, isTrue);
      expect(summary.missingFields, isEmpty);
    });
  });
}
