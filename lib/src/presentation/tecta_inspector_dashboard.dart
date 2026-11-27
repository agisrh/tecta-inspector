import 'package:flutter/material.dart';
import '../inspector_controller.dart';
import 'inspector_colors.dart';
import '../models/log_entry.dart';
import '../tecta_inspector_facade.dart';
import 'widgets/errors_chip.dart';
import 'widgets/log_item_widget.dart';

class TcInspectorDashboard extends StatefulWidget {
  const TcInspectorDashboard({super.key});

  @override
  State<TcInspectorDashboard> createState() => _TcInspectorDashboardState();
}

class _TcInspectorDashboardState extends State<TcInspectorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _errorsOnly = false;

  /// The theme chosen last time. Kept while the app runs, so reopening the
  /// dashboard does not reset it.
  static bool _rememberedDarkMode = true;
  bool _isDarkMode = _rememberedDarkMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TcInspector.isDashboardOpen.value = true;
    });
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TcInspector.isDashboardOpen.value = false;
    });
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<LogEntry> _filterLogs(List<LogEntry> logs) {
    LogType? filterType;
    switch (_tabController.index) {
      case 1:
        filterType = LogType.print;
        break;
      case 2:
        filterType = LogType.network;
        break;
      case 3:
        filterType = LogType.database;
        break;
      case 4:
        filterType = LogType.navigator;
        break;
    }

    return logs.where((log) {
      final matchesType = filterType == null || log.type == filterType;
      final matchesError = !_errorsOnly || log.isFailure;
      return matchesType && matchesError && log.matches(_searchQuery);
    }).toList();
  }

  /// A tab title, followed by how many entries it holds in a small rounded badge.
  Widget _tabTitle(String name, int count, {required bool selected, required Color activeColor}) {
    final badgeColor = selected ? activeColor : InspectorColors.secondaryText(_isDarkMode);
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badgeColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _count(List<LogEntry> logs, LogType? type) =>
      type == null ? logs.length : logs.where((log) => log.type == type).length;

  @override
  Widget build(BuildContext context) {
    final activeTheme = _isDarkMode ? ThemeData.dark() : ThemeData.light();
    final scaffoldBg = _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final appBarBg = _isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final titleTextColor = _isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    final searchFillColor = _isDarkMode ? const Color(0xFF252528) : const Color(0xFFECEFF1);
    final searchTextColor = _isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    final activeTabColor = _isDarkMode ? Colors.tealAccent : const Color(0xFF00796B);

    return Theme(
      data: activeTheme,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: appBarBg,
          elevation: 0,
          // Material 3 tints the bar once the list scrolls under it, which made
          // the search field blend into the bar. Keep the bar one flat colour.
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Inspector',
            style: TextStyle(fontWeight: FontWeight.bold, color: titleTextColor),
          ),
          actions: [
            if (TcInspector.allowUnmasking)
              ValueListenableBuilder<bool>(
                valueListenable: TcInspector.maskingEnabledNotifier,
                builder: (context, masking, _) => IconButton(
                  icon: Icon(
                    masking ? Icons.visibility_off_outlined : Icons.visibility,
                    color: masking ? titleTextColor : Colors.redAccent,
                  ),
                  tooltip: masking ? 'Show real values' : 'Mask sensitive values',
                  onPressed: () => masking ? _confirmUnmask() : TcInspector.setMaskingEnabled(true),
                ),
              ),
            IconButton(
              icon: Icon(
                _isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: titleTextColor,
              ),
              tooltip: _isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                  _rememberedDarkMode = _isDarkMode;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              tooltip: 'Clear All Logs',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Logs'),
                    content: const Text('Are you sure you want to clear all logs?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          TcInspector.clearLogs();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(112),
            child: ValueListenableBuilder<List<LogEntry>>(
              valueListenable: InspectorController.instance.logsNotifier,
              builder: (context, allLogs, _) {
                final failures = allLogs.where((log) => log.isFailure).length;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: searchFillColor,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(color: searchTextColor, fontSize: 14),
                                cursorColor: activeTabColor,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  hintText: 'Search logs...',
                                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                  prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                                  prefixIconConstraints:
                                      const BoxConstraints(minWidth: 40, minHeight: 44),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          onPressed: _searchController.clear,
                                          tooltip: 'Clear search',
                                          padding: EdgeInsets.zero,
                                          constraints:
                                              const BoxConstraints(minWidth: 44, minHeight: 44),
                                          icon: const Icon(Icons.cancel, size: 18, color: Colors.grey),
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ErrorsChip(
                            count: failures,
                            selected: _errorsOnly,
                            isDarkMode: _isDarkMode,
                            onChanged: (value) => setState(() => _errorsOnly = value),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                      indicatorColor: activeTabColor,
                      labelColor: activeTabColor,
                      unselectedLabelColor: InspectorColors.secondaryText(_isDarkMode),
                      tabs: [
                        for (final (index, entry) in <(String, LogType?)>[
                          ('All', null),
                          ('Print', LogType.print),
                          ('Network', LogType.network),
                          ('Database', LogType.database),
                          ('Navigator', LogType.navigator),
                        ].indexed)
                          _tabTitle(
                            entry.$1,
                            _count(allLogs, entry.$2),
                            selected: _tabController.index == index,
                            activeColor: activeTabColor,
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        body: Column(
          children: [
            const _UnmaskedBanner(),
            Expanded(child: _buildLogs()),
          ],
        ),
      ),
    );
  }

  Widget _buildLogs() {
    return ValueListenableBuilder<List<LogEntry>>(
      valueListenable: InspectorController.instance.logsNotifier,
      builder: (context, allLogs, _) {
        final filteredLogs = _filterLogs(allLogs);

        if (filteredLogs.isEmpty) return _buildEmpty(allLogs.isEmpty);

        return ListView.builder(
          itemCount: filteredLogs.length,
          itemBuilder: (context, index) {
            final log = filteredLogs[index];
            return LogItemWidget(
              log: log,
              isDarkMode: _isDarkMode,
              index: index,
              highlight: _searchQuery,
            );
          },
        );
      },
    );
  }

  /// Switching masking off shows passwords and tokens, so it asks first.
  Future<void> _confirmUnmask() async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Show real values?'),
        content: const Text(
          'Passwords, tokens and other sensitive values will be visible in the '
          'logs recorded from now on. Logs already recorded stay masked. '
          'Masking is on again the next time the app starts.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Show real values', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (agreed ?? false) TcInspector.setMaskingEnabled(false);
  }

  Widget _buildEmpty(bool noLogsAtAll) {
    final String message;
    if (noLogsAtAll) {
      message = 'No logs yet';
    } else if (_searchQuery.isNotEmpty) {
      message = 'No logs match "${_searchController.text}"';
    } else if (_errorsOnly) {
      message = 'No errors here';
    } else {
      message = 'Nothing in this tab yet';
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: _searchController.clear, child: const Text('Clear search')),
          ],
        ],
      ),
    );
  }
}

/// A red strip while masking is off, so nobody forgets that real values show.
class _UnmaskedBanner extends StatelessWidget {
  const _UnmaskedBanner();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TcInspector.maskingEnabledNotifier,
      builder: (context, masking, _) {
        if (masking) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: Colors.redAccent.withValues(alpha: 0.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: Colors.redAccent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Masking is off: passwords and tokens show in new logs',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.redAccent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
