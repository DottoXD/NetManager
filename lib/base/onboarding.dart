import 'package:flutter/material.dart';
import 'package:netmanager/types/base/onboarding_item.dart';
import 'package:netmanager/utils/haptic_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _slides = [
    OnboardingItem(
      icon: Icons.settings_suggest_outlined,
      title: "Control app behaviour",
      description:
          "Fine-tune background services and optimise data update intervals exactly to your preference inside settings.",
    ),
    OnboardingItem(
      icon: Icons.palette_outlined,
      title: "Customise aesthetics",
      description:
          "Toggle Material 3 dynamic color matching, switch themes, and adjust tactile haptic feedback responses.",
    ),
    OnboardingItem(
      icon: Icons.fiber_smart_record_outlined,
      title: "Track & replay trips",
      description:
          "Record your signal strength and cellular technology live during trips on the map tab, then replay your routes later.",
    ),
    OnboardingItem(
      icon: Icons.storage_outlined,
      title: "Import cell databases",
      description:
          "Load an offline cell database to identify towers around you on the map and show extra data on your home dashboard.",
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: () async {
                    await HapticService().triggerHaptic(
                      HapticType.selection,
                      context,
                    );

                    widget.onFinished();
                  },
                  child: const Text("Skip"),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final item = _slides[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            size: 64,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          item.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      await HapticService().triggerHaptic(
                        HapticType.selection,
                        context,
                      );

                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        widget.onFinished();
                      }
                    },
                    icon: Icon(
                      _currentPage == _slides.length - 1
                          ? Icons.done_outlined
                          : Icons.arrow_forward_outlined,
                    ),
                    label: Text(
                      _currentPage == _slides.length - 1
                          ? "Get started"
                          : "Next",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
