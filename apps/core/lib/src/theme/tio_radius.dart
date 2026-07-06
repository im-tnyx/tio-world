class TioRadius {
  const TioRadius(this.small, this.medium, this.large, this.extraLarge);

  final double small;
  final double medium;
  final double large;
  final double extraLarge;

  static const standard = TioRadius(8, 12, 16, 24);
}
