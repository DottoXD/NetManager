import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:netmanager/components/base/body/advanced/widgets/advanced_subpage.dart';
import 'package:netmanager/components/base/body/advanced/widgets/carrier_config_page.dart';
import 'package:netmanager/components/base/body/advanced/widgets/diag_hub.dart';
import 'package:netmanager/components/base/body/advanced/widgets/diag_page.dart';
import 'package:netmanager/components/base/body/advanced/widgets/ims_logs_page.dart';
import 'package:netmanager/components/base/body/advanced/widgets/ims_status_page.dart';
import 'package:netmanager/components/base/body/advanced/widgets/lte_serving_cell_page.dart';
import 'package:netmanager/components/base/body/advanced/widgets/page_dots.dart';
import 'package:netmanager/l10n/app_localizations.dart';

enum _PageType { carrier, imsStatus, imsLogs, lteServing, diagUtils }

enum _ViewState { loading, error, empty, content }

enum _ErrorType { noResponse, platform, other }

class _FetchError {
  final _ErrorType type;
  final String? message;

  const _FetchError(this.type, [this.message]);

  String text(AppLocalizations appLocalizations) {
    switch (type) {
      case _ErrorType.noResponse:
        return appLocalizations.advancedErrorShizuku;
      case _ErrorType.platform:
        return message ?? appLocalizations.advancedErrorPlatform;
      case _ErrorType.other:
        return message ?? appLocalizations.advancedErrorUnknown;
    }
  }
}

Map<String, dynamic> _decodeJson(String raw) {
  return jsonDecode(raw) as Map<String, dynamic>;
}

class AdvancedModeBody extends StatefulWidget {
  final MethodChannel mainPlatform;
  final ValueNotifier<int> currentSimSlotNotifier;
  final ValueNotifier<int> updateIntervalNotifier;
  final ValueSetter<VoidCallback>? onUpdateButtonPressed;

  const AdvancedModeBody({
    super.key,
    required this.mainPlatform,
    required this.currentSimSlotNotifier,
    required this.updateIntervalNotifier,
    this.onUpdateButtonPressed,
  });

  @override
  State<AdvancedModeBody> createState() => _AdvancedModeBodyState();
}

class _AdvancedModeBodyState extends State<AdvancedModeBody>
    with WidgetsBindingObserver {
  static const MethodChannel _advancedChn = MethodChannel(
    'pw.dotto.netmanager/advanced',
  );
  static const int _isolateThreshold = 16384;

  final PageController _pageController = PageController();
  Timer? _timer;

  bool _fetching = false;
  bool _checking = false;
  bool _refetch = false;
  bool _loading = true;
  _FetchError? _error;
  String? _lastRaw;
  Map<String, dynamic> _data = const {};
  bool _shizukuOk = false;
  bool _diagOk = false;
  bool _holdsDiagHub = false;

  String _carrierSig = "";
  String _imsSig = "";
  String _logsSig = "";

  final ValueNotifier<_ViewState> _viewStateNotifier = ValueNotifier(
    _ViewState.loading,
  );
  final ValueNotifier<_FetchError?> _errorInfoNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _refreshingNotifier = ValueNotifier(false);
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier(0);
  final ValueNotifier<List<_PageType>> _pagesNotifier = ValueNotifier(const []);
  final ValueNotifier<Map<String, dynamic>> _carrierNotifier = ValueNotifier(
    const {},
  );
  final ValueNotifier<Map<String, dynamic>> _imsNotifier = ValueNotifier(
    const {},
  );
  final ValueNotifier<List<dynamic>> _logsNotifier = ValueNotifier(const []);

  late final Map<_PageType, AdvancedSubpage> _descriptors = {
    _PageType.carrier: AdvancedSubpage(
      title: (appLocalizations) => appLocalizations.advancedModeCarrierConfig,
      icon: Icons.tune_outlined,
      builder: (_) => CarrierConfigPage(data: _carrierNotifier),
    ),
    _PageType.imsStatus: AdvancedSubpage(
      title: (appLocalizations) => appLocalizations.advancedModeImsStatus,
      icon: Icons.cell_tower_outlined,
      builder: (_) => ImsStatusPage(ims: _imsNotifier),
    ),
    _PageType.imsLogs: AdvancedSubpage(
      title: (appLocalizations) => appLocalizations.advancedModeImsLogs,
      icon: Icons.list_alt_outlined,
      builder: (_) => ImsLogsPage(logs: _logsNotifier),
    ),
    _PageType.lteServing: AdvancedSubpage(
      title: (appLocalizations) => appLocalizations.advancedModeLteServingCell,
      icon: Icons.cell_tower_outlined,
      builder: (_) =>
          LteServingCellPage(simSlotNotifier: widget.currentSimSlotNotifier),
    ),
    _PageType.diagUtils: AdvancedSubpage(
      title: (appLocalizations) => appLocalizations.advancedModeDiagUtils,
      icon: Icons.biotech_outlined,
      builder: (_) =>
          DiagUtilsPage(simSlotNotifier: widget.currentSimSlotNotifier),
    ),
  };

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    widget.currentSimSlotNotifier.addListener(_fetchData);
    widget.updateIntervalNotifier.addListener(_restartTimer);
    widget.onUpdateButtonPressed?.call(_fetchData);

    _checkAvailability();
  }

  Future<int> _status(String method) async {
    try {
      return await widget.mainPlatform.invokeMethod<int>(method) ?? 3;
    } catch (_) {
      return 3;
    }
  }

  Future<void> _checkAvailability({bool shizukuOnly = false}) async {
    if (_checking) return;
    _checking = true;

    final int shizukuStatus;
    final int diagStatus;

    try {
      if (shizukuOnly) {
        shizukuStatus = await _status("checkShizuku");
        diagStatus = _diagOk ? 0 : 3;
      } else {
        final results = await Future.wait([
          _status("checkShizuku"),
          _status("checkDiag"),
        ]);

        shizukuStatus = results[0];
        diagStatus = results[1];
      }
    } finally {
      _checking = false;
    }
    if (!mounted) return;

    final shizukuNow = shizukuStatus == 0;
    final diagNow = diagStatus == 0;
    final shizukuChanged = shizukuNow != _shizukuOk;
    final diagChanged = diagNow != _diagOk;

    _shizukuOk = shizukuNow;
    _diagOk = diagNow;

    if (diagChanged) {
      if (diagNow && !_holdsDiagHub) {
        _holdsDiagHub = true;
        DiagHub.instance.acquire();
      } else if (!diagNow && _holdsDiagHub) {
        _holdsDiagHub = false;
        DiagHub.instance.release();
      }
    }

    if (shizukuChanged) {
      if (shizukuNow) {
        _startTimer();
        return;
      }
      _timer?.cancel();
      _timer = null;
      _clearShizukuData();
    }

    _loading = false;
    _refreshState();
  }

  void _clearShizukuData() {
    _data = const {};
    _lastRaw = null;
    _error = null;
    _carrierSig = "";
    _imsSig = "";
    _logsSig = "";
    _carrierNotifier.value = const {};
    _imsNotifier.value = const {};
    _logsNotifier.value = const [];
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAvailability();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_holdsDiagHub) {
      _holdsDiagHub = false;
      DiagHub.instance.release();
    }

    _timer?.cancel();
    widget.currentSimSlotNotifier.removeListener(_fetchData);
    widget.updateIntervalNotifier.removeListener(_restartTimer);
    widget.onUpdateButtonPressed?.call(() {});
    _pageController.dispose();
    _viewStateNotifier.dispose();
    _errorInfoNotifier.dispose();
    _refreshingNotifier.dispose();
    _currentPageNotifier.dispose();
    _pagesNotifier.dispose();
    _carrierNotifier.dispose();
    _imsNotifier.dispose();
    _logsNotifier.dispose();

    super.dispose();
  }

  void _startTimer() {
    _fetchData();
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(seconds: widget.updateIntervalNotifier.value),
      (_) => _fetchData(),
    );
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_shizukuOk) _startTimer();
  }

  Future<Map<String, dynamic>> _decode(String raw) async {
    if (raw.length < _isolateThreshold) return _decodeJson(raw);
    return Isolate.run(() => _decodeJson(raw));
  }

  void _updateSlice<T>(
    ValueNotifier<T> notifier,
    T value,
    String oldSig,
    void Function(String sig) saveSig,
  ) {
    final sig = jsonEncode(value);
    if (sig == oldSig) return;
    saveSig(sig);
    notifier.value = value;
  }

  void _applyData(Map<String, dynamic> parsed) {
    _data = parsed;

    final carrier = <String, dynamic>{
      for (final k in CarrierConfigPage.dataKeys)
        if (parsed.containsKey(k)) k: parsed[k],
    };

    final ims = (parsed["ims"] as Map?)?.cast<String, dynamic>() ?? const {};
    final logs = (parsed["imsLogs"] as List?) ?? const [];

    _updateSlice(
      _carrierNotifier,
      carrier,
      _carrierSig,
      (s) => _carrierSig = s,
    );
    _updateSlice(_imsNotifier, ims, _imsSig, (s) => _imsSig = s);
    _updateSlice<List<dynamic>>(
      _logsNotifier,
      logs,
      _logsSig,
      (s) => _logsSig = s,
    );
  }

  Future<void> _fetchData() async {
    if (!mounted || !_shizukuOk) return;
    if (_fetching) {
      _refetch = true;
      return;
    }
    _fetching = true;

    if (_data.isEmpty) {
      _loading = true;
      _error = null;
      _refreshState();
    } else {
      _refreshingNotifier.value = true;
    }

    try {
      final String? raw = await _advancedChn.invokeMethod<String>(
        "getAdvancedModeData",
      );
      if (!mounted || !_shizukuOk) return;

      if (raw != null) {
        if (raw != _lastRaw) {
          final parsed = await _decode(raw);
          if (!mounted || !_shizukuOk) return;
          _lastRaw = raw;
          _applyData(parsed);
        }
        _error = null;
      } else {
        _error = const _FetchError(_ErrorType.noResponse);
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      _error = _FetchError(_ErrorType.platform, e.message);
    } catch (e) {
      if (!mounted) return;
      _error = _FetchError(_ErrorType.other, e.toString());
    } finally {
      _fetching = false;

      if (mounted) {
        _loading = false;
        _refreshingNotifier.value = false;
        _refreshState();
        if (_error != null) _checkAvailability(shizukuOnly: true);
        if (_refetch) {
          _refetch = false;
          _fetchData();
        }
      }
    }
  }

  List<_PageType> _computePages() {
    final pageTypes = <_PageType>[];

    if (_shizukuOk) {
      if (CarrierConfigPage.hasKeys(_carrierNotifier.value)) {
        pageTypes.add(_PageType.carrier);
      }
      if (_imsNotifier.value.isNotEmpty) pageTypes.add(_PageType.imsStatus);
      if (_logsNotifier.value.isNotEmpty) pageTypes.add(_PageType.imsLogs);
    }

    if (_diagOk) {
      pageTypes.add(_PageType.lteServing);
      pageTypes.add(_PageType.diagUtils);
    }

    return pageTypes;
  }

  void _refreshState() {
    final pageTypes = _computePages();

    if (!listEquals(pageTypes, _pagesNotifier.value)) {
      _pagesNotifier.value = pageTypes;

      final maxIndex = pageTypes.isEmpty ? 0 : pageTypes.length - 1;
      if (_currentPageNotifier.value > maxIndex) {
        _currentPageNotifier.value = maxIndex;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_pageController.hasClients) return;
          if ((_pageController.page?.round() ?? 0) != maxIndex) {
            _pageController.jumpToPage(maxIndex);
          }
        });
      }
    }

    final _ViewState state;
    if (_data.isEmpty && _loading) {
      state = _ViewState.loading;
    } else if (_data.isEmpty && _error != null) {
      state = _ViewState.error;
    } else if (pageTypes.isEmpty) {
      state = _ViewState.empty;
    } else {
      state = _ViewState.content;
    }

    _errorInfoNotifier.value = _error;
    _viewStateNotifier.value = state;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: ValueListenableBuilder(
          valueListenable: _viewStateNotifier,
          builder: (context, state, _) {
            switch (state) {
              case _ViewState.loading:
                return const Center(child: CircularProgressIndicator());
              case _ViewState.error:
                return _ErrorView(
                  error: _errorInfoNotifier,
                  onRetry: _fetchData,
                );
              case _ViewState.empty:
                return const _EmptyView();
              case _ViewState.content:
                return ValueListenableBuilder(
                  valueListenable: _pagesNotifier,
                  builder: (context, pages, _) => _buildPager(pages),
                );
            }
          },
        ),
      ),
    );
  }

  Widget _buildPager(List<_PageType> pages) {
    if (pages.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          height: 3,
          child: ValueListenableBuilder(
            valueListenable: _refreshingNotifier,
            builder: (context, refreshing, _) => refreshing
                ? const LinearProgressIndicator()
                : const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _TitleCard(
            pages: pages,
            descriptors: _descriptors,
            currentPage: _currentPageNotifier,
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (i) => _currentPageNotifier.value = i,
                findChildIndexCallback: (key) {
                  if (key is ValueKey<_PageType>) {
                    final i = pages.indexOf(key.value);
                    return i < 0 ? null : i;
                  }

                  return null;
                },
                itemBuilder: (context, i) => KeyedSubtree(
                  key: ValueKey<_PageType>(pages[i]),
                  child: _descriptors[pages[i]]!.builder(context),
                ),
              ),
              if (pages.length > 1)
                Positioned(
                  bottom: 20,
                  child: RepaintBoundary(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.from(
                              alpha: 0.1,
                              red: 0,
                              green: 0,
                              blue: 0,
                            ),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ValueListenableBuilder(
                        valueListenable: _currentPageNotifier,
                        builder: (context, index, _) => PageDots(
                          count: pages.length,
                          currentIndex: index.clamp(0, pages.length - 1),
                          onDotTap: (page) {
                            if (!_pageController.hasClients) return;

                            _pageController.animateToPage(
                              page,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TitleCard extends StatelessWidget {
  final List<_PageType> pages;
  final Map<_PageType, AdvancedSubpage> descriptors;
  final ValueListenable<int> currentPage;

  const _TitleCard({
    required this.pages,
    required this.descriptors,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ValueListenableBuilder(
        valueListenable: currentPage,
        builder: (context, index, _) {
          final current = descriptors[pages[index.clamp(0, pages.length - 1)]]!;
          final title = current.title(appLocalizations);

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  current.icon,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    title,
                    key: ValueKey(title),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final ValueListenable<_FetchError?> error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_outlined,
                color: theme.colorScheme.onErrorContainer,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              appLocalizations.advancedErrorTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder(
              valueListenable: error,
              builder: (context, e, _) => Text(
                e?.text(appLocalizations) ??
                    appLocalizations.advancedErrorUnknown,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_outlined),
              label: Text(appLocalizations.advancedModeRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outlined,
                color: theme.colorScheme.onSurfaceVariant,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              appLocalizations.advancedModeNoData,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
