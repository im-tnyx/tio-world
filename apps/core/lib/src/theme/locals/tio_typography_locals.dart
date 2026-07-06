import 'package:flutter/material.dart';

class TioTypographyLocals {
  const TioTypographyLocals._();

  static TextTheme of(BuildContext context) {
    return Theme.of(context).textTheme;
  }
}
