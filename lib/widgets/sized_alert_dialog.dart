import 'dart:math';

import 'package:flutter/material.dart';

class SizedAlertDialog extends StatelessWidget {
  final Widget child;

  const SizedAlertDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Define a standard width for dialogs, but ensure it doesn't exceed screen width.
    const double dialogWidth = 450.0;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 24.0,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: min(dialogWidth, screenWidth - 40),
        ), // -40 for padding
        child: child,
      ),
    );
  }
}
