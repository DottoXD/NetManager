import 'package:material_ui/material_ui.dart';

class PageDots extends StatelessWidget {
  final int count;
  final int currentIndex;
  final ValueChanged<int>? onDotTap;

  const PageDots({
    super.key,
    required this.count,
    required this.currentIndex,
    this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final inactive = colors.onSurfaceVariant.withValues(alpha: 0.35);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onDotTap == null ? null : () => onDotTap!(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.fastOutSlowIn,
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? colors.primary : inactive,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }),
    );
  }
}
