import 'package:foundation_app/screens/pages/log_detail_screen.dart';
import 'package:foundation_app/widgets/dashboard_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/responsive_center.dart';
import '../../services/finance_service.dart';

class AllLogsScreen extends StatefulWidget {
  const AllLogsScreen({super.key});

  @override
  State<AllLogsScreen> createState() => _AllLogsScreenState();
}

class _AllLogsScreenState extends State<AllLogsScreen> {
  final FinanceService _financeService = FinanceService();
  
  bool _isLoading = true;
  String? _errorMessage; 
  
  // 1. MASTER LIST (Source of Truth)
  List<Map<String, dynamic>> _masterLogs = [];
  
  // 2. DISPLAY LIST (Filtered)
  List<Map<String, dynamic>> _displayLogs = [];
  
  // Date State
  DateTime _currentMonth = DateTime.now();

  // Filter State
  String? _filterType; 
  List<String> _filterCategoryIds = [];
  List<String> _filterAccountIds = [];
  
  final TextEditingController _tagController = TextEditingController();

  // Filter Data Sources
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadFilterData();
    _fetchLogsForMonth();
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterData() async {
    if (_categories.isNotEmpty && _accounts.isNotEmpty) return;
    try {
      final results = await Future.wait([
        _financeService.getCategories(),
        _financeService.getAccounts(),
      ]);
      if (mounted) {
        setState(() {
          _categories = results[0];
          _accounts = results[1];
        });
      }
    } catch (e) {
      debugPrint("Error loading filters: $e");
    }
  }

  Future<void> _fetchLogsForMonth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final logs = await _financeService.getLogsByMonth(_currentMonth);
      if (mounted) {
        setState(() {
          _masterLogs = logs;
          _isLoading = false;
        });
        _applyLocalFilters(); 
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _applyLocalFilters() {
    List<Map<String, dynamic>> temp = List.from(_masterLogs);

    if (_filterType != null) {
      temp = temp.where((log) => log['type'] == _filterType).toList();
    }

    if (_filterCategoryIds.isNotEmpty) {
      temp = temp.where((log) => _filterCategoryIds.contains(log['category_id'])).toList();
    }

    if (_filterAccountIds.isNotEmpty) {
      temp = temp.where((log) => _filterAccountIds.contains(log['account_id'])).toList();
    }

    final query = _tagController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      temp = temp.where((log) {
        final itemName = (log['item_name'] ?? '').toString().toLowerCase();
        final notes = (log['original_text'] ?? '').toString().toLowerCase();
        bool tagMatch = false;
        if (log['tags'] != null && log['tags'] is List) {
           final tags = (log['tags'] as List).map((e) => e.toString().toLowerCase()).toList();
           tagMatch = tags.any((t) => t.contains(query));
        }
        return itemName.contains(query) || notes.contains(query) || tagMatch;
      }).toList();
    }

    setState(() {
      _displayLogs = temp;
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    });
    _fetchLogsForMonth();
  }

  void _onLogTap(Map<String, dynamic> log) async {
    final bool? shouldRefresh = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (context) => LogDetailSheet(log: log),
    );

    if (shouldRefresh == true) {
      _fetchLogsForMonth();
    }
  }

  // --- FILTER UI ---

  void _showFilterModal() {
    if (_categories.isEmpty || _accounts.isEmpty) _loadFilterData();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface, // ✅ Adaptive Background
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.all(24),
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Filter Transactions", style: theme.textTheme.titleLarge),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _filterType = null;
                                _filterCategoryIds.clear();
                                _filterAccountIds.clear();
                                _tagController.clear();
                              });
                            },
                            child: const Text("Reset"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // 1. Transaction Type
                      Text("Type", style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildTypeChoiceChip("All", null, setModalState),
                          const SizedBox(width: 8),
                          _buildTypeChoiceChip("Expense", "expense", setModalState),
                          const SizedBox(width: 8),
                          _buildTypeChoiceChip("Income", "income", setModalState),
                        ],
                      ),
                      const SizedBox(height: 20),
            
                      // 2. Tag / Search
                      TextFormField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          labelText: "Search Tag / Item",
                          hintText: "e.g. #vacation or 'Coffee'",
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          prefixIcon: const Icon(Icons.tag, size: 20),
                        ),
                      ),
                      const SizedBox(height: 20),
            
                      // 3. Category (Multi-Select)
                      Text("Categories", style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((c) {
                          final isSelected = _filterCategoryIds.contains(c['id']);
                          return FilterChip(
                            label: Text("${c['icon_emoji'] ?? ''} ${c['name']}"),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  _filterCategoryIds.add(c['id']);
                                } else {
                                  _filterCategoryIds.remove(c['id']);
                                }
                              });
                            },
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            selectedColor: theme.colorScheme.primaryContainer,
                            checkmarkColor: theme.colorScheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
            
                      // 4. Accounts (Multi-Select)
                      Text("Accounts", style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _accounts.map((a) {
                          final isSelected = _filterAccountIds.contains(a['id']);
                          return FilterChip(
                            label: Text(a['name']),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  _filterAccountIds.add(a['id']);
                                } else {
                                  _filterAccountIds.remove(a['id']);
                                }
                              });
                            },
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            selectedColor: theme.colorScheme.secondaryContainer,
                            checkmarkColor: theme.colorScheme.secondary,
                            labelStyle: TextStyle(
                              color: isSelected ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurface
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
            
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _applyLocalFilters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("Apply Filters", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20), 
                    ],
                  ),
                ),
              );
            }
          ),
        );
      },
    );
  }

  Widget _buildTypeChoiceChip(String label, String? value, StateSetter setModalState) {
    final theme = Theme.of(context);
    final isSelected = _filterType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setModalState(() {
          _filterType = selected ? value : null;
        });
      },
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      labelStyle: TextStyle(color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.transparent : theme.colorScheme.outlineVariant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasActiveFilter = _filterType != null || 
                                 _filterCategoryIds.isNotEmpty || 
                                 _filterAccountIds.isNotEmpty || 
                                 _tagController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // ✅ Adaptive Background
      appBar: AppBar(
        title: Text("Transactions", style: theme.textTheme.titleLarge),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(hasActiveFilter ? Icons.filter_alt : Icons.filter_alt_outlined),
            color: hasActiveFilter ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            // MONTH NAVIGATOR
            Container(
              color: theme.colorScheme.surface, // ✅ Adaptive Surface
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_currentMonth),
                        style: theme.textTheme.titleMedium,
                      ),
                      IconButton(
                        onPressed: () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  if (hasActiveFilter) 
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_filterType != null) 
                            _activeFilterChip(_filterType!.toUpperCase(), () { setState(()=>_filterType=null); _applyLocalFilters(); }),
                          
                          if (_tagController.text.isNotEmpty)
                            _activeFilterChip(
                              "Tag: ${_tagController.text}", 
                              () { setState(()=>_tagController.clear()); _applyLocalFilters(); }
                            ),

                          // Render Category Chips
                          ..._filterCategoryIds.map((id) {
                            final cat = _categories.firstWhere((c) => c['id'] == id, orElse: () => {'name': 'Unknown'});
                            return _activeFilterChip(
                              cat['name'], 
                              () { setState(()=>_filterCategoryIds.remove(id)); _applyLocalFilters(); }
                            );
                          }),

                          // Render Account Chips
                          ..._filterAccountIds.map((id) {
                            final acc = _accounts.firstWhere((a) => a['id'] == id, orElse: () => {'name': 'Unknown'});
                            return _activeFilterChip(
                              acc['name'], 
                              () { setState(()=>_filterAccountIds.remove(id)); _applyLocalFilters(); }
                            );
                          }),
                            
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _filterType = null;
                                _filterCategoryIds.clear();
                                _filterAccountIds.clear();
                                _tagController.clear();
                              });
                              _applyLocalFilters();
                            }, 
                            child: const Text("Clear All", style: TextStyle(fontSize: 12))
                          )
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // LIST
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                  ? Center(child: Text("Error: $_errorMessage"))
                  : _displayLogs.isEmpty 
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: theme.colorScheme.primary,
                        onRefresh: _fetchLogsForMonth,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 40),
                          itemCount: _displayLogs.length,
                          itemBuilder: (context, index) {
                            return RecentTransactionTile(
                              log: _displayLogs[index],
                              onTap: () => _onLogTap(_displayLogs[index]),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeFilterChip(String label, VoidCallback onRemove) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        deleteIcon: Icon(Icons.close, size: 14, color: theme.colorScheme.onSecondaryContainer),
        onDeleted: onRemove,
        backgroundColor: theme.colorScheme.secondaryContainer, // ✅ Adaptive Chip Color
        labelStyle: TextStyle(color: theme.colorScheme.onSecondaryContainer),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 64, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            "No matching transactions",
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _filterType = null;
                _filterCategoryIds.clear();
                _filterAccountIds.clear();
                _tagController.clear();
              });
              _applyLocalFilters();
            },
            child: const Text("Clear Filters"),
          )
        ],
      ),
    );
  }
}