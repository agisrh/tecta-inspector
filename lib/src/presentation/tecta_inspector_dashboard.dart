import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../inspector_controller.dart';
import '../models/log_entry.dart';
import '../tecta_inspector_facade.dart';
import 'widgets/log_item_widget.dart';

class TectaInspectorDashboard extends StatefulWidget {
  const TectaInspectorDashboard({super.key});

  @override
  State<TectaInspectorDashboard> createState() => _TectaInspectorDashboardState();
}

class _TectaInspectorDashboardState extends State<TectaInspectorDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TectaInspector.isDashboardOpen.value = true;
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
      TectaInspector.isDashboardOpen.value = false;
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
      final matchesSearch = log.title.toLowerCase().contains(_searchQuery) ||
          log.content.toLowerCase().contains(_searchQuery);
      return matchesType && matchesSearch;
    }).toList();
  }

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
          title: Text(
            'Tecta Inspector',
            style: TextStyle(fontWeight: FontWeight.bold, color: titleTextColor),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: titleTextColor,
              ),
              tooltip: _isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
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
                          TectaInspector.clearLogs();
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
            preferredSize: const Size.fromHeight(104),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    height: 36,
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        hintText: 'Search logs...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () => _searchController.clear(),
                                child: const Icon(Icons.cancel, size: 18, color: Colors.grey),
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                  indicatorColor: activeTabColor,
                  labelColor: activeTabColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Print'),
                    Tab(text: 'Network'),
                    Tab(text: 'Database'),
                    Tab(text: 'Navigator'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: ValueListenableBuilder<List<LogEntry>>(
          valueListenable: InspectorController.instance.logsNotifier,
          builder: (context, allLogs, _) {
            final filteredLogs = _filterLogs(allLogs);

            if (filteredLogs.isEmpty) {
              return const Center(
                child: Text(
                  'No logs found',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              itemCount: filteredLogs.length,
              itemBuilder: (context, index) {
                final log = filteredLogs[index];
                return LogItemWidget(log: log, isDarkMode: _isDarkMode, index: index);
              },
            );
          },
        ),
      ),
    );
  }
}
