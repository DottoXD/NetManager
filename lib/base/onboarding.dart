import 'package:material_ui/material_ui.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/types/base/onboarding_item.dart';
import 'package:netmanager/utils/haptic_service.dart';

class OnboardingScreen extends StatefulWidget {
  final AppLocalizations appLocalizations;
  final VoidCallback onFinished;

  const OnboardingScreen({
    super.key,
    required this.appLocalizations,
    required this.onFinished,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  late AppLocalizations appLocalizations;
  late List<OnboardingItem> _slides;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    appLocalizations = widget.appLocalizations;

    _slides = [
      OnboardingItem(
        icon: Icons.settings_suggest_outlined,
        title: appLocalizations.appBehaviourTitle,
        description: appLocalizations.appBehaviourDescription,
      ),
      OnboardingItem(
        icon: Icons.palette_outlined,
        title: appLocalizations.customiseAestheticsTitle,
        description: appLocalizations.customiseAestheticsDescription,
      ),
      OnboardingItem(
        icon: Icons.fiber_smart_record_outlined,
        title: appLocalizations.trackReplayTitle,
        description: appLocalizations.trackReplayDescription,
      ),
      OnboardingItem(
        icon: Icons.storage_outlined,
        title: appLocalizations.importCellDatabasesTitle,
        description: appLocalizations.importCellDatabasesDescription,
      ),
    ];
  }

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
                  child: Text(appLocalizations.skip),
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
                          ? appLocalizations.getStarted
                          : appLocalizations.next,
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
