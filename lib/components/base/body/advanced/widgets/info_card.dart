import 'package:material_ui/material_ui.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const InfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class DividedColumn extends StatelessWidget {
  final List<Widget> children;

  const DividedColumn({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 20,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant
          .withValues(alpha: 0.25),
    );

    return Column(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) divider,
          children[i],
        ],
      ],
    );
  }
}
