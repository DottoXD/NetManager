import 'package:flutter/material.dart';

class FloatingButton extends StatelessWidget {
  const FloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 3,
      onPressed: null,
      tooltip: 'Update data',
      child: const Icon(Icons.update_rounded),
    );
  }
}
