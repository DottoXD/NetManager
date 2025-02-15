import 'package:flutter/material.dart';

class FloatingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: null,
      tooltip: 'Update data',
      child: const Icon(Icons.update),
    );
  }

}