import 'tio_font_family.dart';

/// Runtime-selectable font-family choices exposed by the core theme.
///
/// The stable [id] is intended for app-level persistence. Display labels stay
/// feature/localization owned. Add a new option only after its family is
/// available on every supported platform, either through the platform or an
/// explicitly bundled font asset.
enum TioFontFamilyOption {
  system,
  roboto,
}

extension TioFontFamilyOptionContract on TioFontFamilyOption {
  String get id => switch (this) {
        TioFontFamilyOption.system => 'system',
        TioFontFamilyOption.roboto => 'roboto',
      };

  String? get family => switch (this) {
        TioFontFamilyOption.system => TioFontFamily.system,
        TioFontFamilyOption.roboto => TioFontFamily.roboto,
      };
}
