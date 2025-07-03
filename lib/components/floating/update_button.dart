import 'package:flutter/material.dart';

class UpdateButton extends StatelessWidget {
  const UpdateButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 1,
      onPressed: null,
      tooltip: 'Update data',
      child: const Icon(Icons.update_rounded),
    );
  }
}
