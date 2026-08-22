import 'package:material_ui/material_ui.dart';

class EmptyState extends StatelessWidget {
  final double minHeight;
  final IconData icon;
  final String message;

  const EmptyState({
    super.key,
    required this.minHeight,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 80,
              //color: Theme.of(context).colorScheme.primaryContainer,
            ),
            const SizedBox(height: 20),
            Text(message, style: const TextStyle(fontSize: 22)),
          ],
        ),
      ),
    );
  }
}
