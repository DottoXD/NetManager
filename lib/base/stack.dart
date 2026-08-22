import 'package:material_ui/material_ui.dart';

class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final Set<int> _builtPages = {widget.index};

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_builtPages.contains(widget.index)) {
      setState(() => _builtPages.add(widget.index));
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: widget.children.asMap().entries.map((entry) {
        final idx = entry.key;
        final child = entry.value;
        return _builtPages.contains(idx) ? child : const SizedBox.shrink();
      }).toList(),
    );
  }
}
