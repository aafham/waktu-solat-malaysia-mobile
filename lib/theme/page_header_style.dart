import 'package:flutter/material.dart';

TextStyle pageTitleStyle(BuildContext context) {
  return Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 36,
            height: 1.0,
            letterSpacing: -0.2,
          ) ??
      const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 36,
        height: 1.0,
        letterSpacing: -0.2,
      );
}
