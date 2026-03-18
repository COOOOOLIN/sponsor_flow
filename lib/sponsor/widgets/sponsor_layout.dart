import 'package:flutter/material.dart';

class SponsorLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const SponsorLayout({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  static const double _maxWidth = 1100;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}