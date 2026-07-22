import 'package:flutter/material.dart';

class MapOverlay extends StatelessWidget {
  final ValueNotifier<List<String>> titlesNotifier;
  final ValueNotifier<List<String>> valuesNotifier;

  const MapOverlay({
    super.key,
    required this.titlesNotifier,
    required this.valuesNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: valuesNotifier,
      builder: (context, values, _) {
        final theme = Theme.of(context);

        return Card(
          margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
          elevation: 1,
          //color: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 36.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(titlesNotifier.value.length, (index) {
                final isLast = index == titlesNotifier.value.length - 1;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          titlesNotifier.value[index],
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          values[index],
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (!isLast) const SizedBox(width: 24),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
