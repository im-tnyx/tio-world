/// Display label for a catalog taxonomy token such as `upper_arms`.
///
/// Tokens are snake_case catalog values; labels are sentence case
/// (`Upper arms`). [_overrides] holds the tokens whose natural spelling a
/// mechanical conversion gets wrong.
String exerciseTaxonomyLabel(String token) {
  final override = _overrides[token];
  if (override != null) return override;

  final words =
      token.split('_').where((word) => word.isNotEmpty).join(' ').toLowerCase();
  if (words.isEmpty) return token;
  return '${words[0].toUpperCase()}${words.substring(1)}';
}

const _overrides = <String, String>{
  'ez_bar': 'EZ bar',
};
