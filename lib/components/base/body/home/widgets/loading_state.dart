import 'package:flutter/material.dart';

class LoadingState extends StatelessWidget {
  final double minHeight;

  const LoadingState({super.key, required this.minHeight});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
