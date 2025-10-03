import 'package:flutter/material.dart';

class UpdateButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const UpdateButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 1,
      onPressed: onPressed,
      tooltip: 'Update data',
      child: const Icon(Icons.update_rounded),
    );
  }
}
