import 'package:familyfin/screens/pages/log_detail_screen.dart';
import 'package:familyfin/widgets/dashboard_widgets.dart';
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
  
  // ✅ 1. MASTER LIST (Source of Truth for the selected Month)
  List<Map<String, dynamic>> _masterLogs = [];
  
  // ✅ 2. DISPLAY LIST (Filtered subset shown in UI)
  List<Map<String, dynamic>> _displayLogs = [];
  
  // Date State
  DateTime _currentMonth = DateTime.now();

  // Filter State (Updated to Lists for Multi-Select)
  String? _filterType; 
  List<String> _filterCategoryIds = []; // ✅ Multi-select
  List<String> _filterAccountIds = [];  // ✅ Multi-select
  
  final TextEditingController _tagController = TextEditingController();

  // Filter Data Sources
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadFilterData();
    _fetchLogsForMonth(); // Initial Fetch
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

  // ✅ FETCH FROM API (Only runs when Month changes or Refresh)
  Future<void> _fetchLogsForMonth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final logs = await _financeService.getLogsByMonth(_currentMonth);
      
      if (mounted) {
        setState(() {
          _masterLogs = logs; // Save to Master
          _isLoading = false;
        });
        _applyLocalFilters(); // Run filter logic immediately
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

  // ✅ FILTER LOGIC (Runs in memory - FAST)
  void _applyLocalFilters() {
    List<Map<String, dynamic>> temp = List.from(_masterLogs);

    // 1. Filter Type
    if (_filterType != null) {
      temp = temp.where((log) => log['type'] == _filterType).toList();
    }

    // 2. Filter Category (Multi-select)
    if (_filterCategoryIds.isNotEmpty) {
      temp = temp.where((log) => _filterCategoryIds.contains(log['category_id'])).toList();
    }

    // 3. Filter Account (Multi-select)
    if (_filterAccountIds.isNotEmpty) {
      temp = temp.where((log) => _filterAccountIds.contains(log['account_id'])).toList();
    }

    // 4. Filter Tags / Text Search
    final query = _tagController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      temp = temp.where((log) {
        final itemName = (log['item_name'] ?? '').toString().toLowerCase();
        final notes = (log['original_text'] ?? '').toString().toLowerCase();
        // Check Tags Array (if dynamic list)
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
    _fetchLogsForMonth(); // Month changed? Fetch new data from DB.
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

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.all(24),
                // Limit height to 85% of screen so users can reach top buttons
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Filter Transactions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      const Text("Type", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
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
                        decoration: const InputDecoration(
                          labelText: "Search Tag / Item",
                          hintText: "e.g. #vacation or 'Coffee'",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          prefixIcon: Icon(Icons.tag, size: 20),
                        ),
                      ),
                      const SizedBox(height: 20),
            
                      // 3. Category (Multi-Select)
                      const Text("Categories", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
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
                            backgroundColor: Colors.white,
                            selectedColor: Colors.blue[100],
                            checkmarkColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
            
                      // 4. Accounts (Multi-Select)
                      const Text("Accounts", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
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
                            backgroundColor: Colors.white,
                            selectedColor: Colors.purple[100],
                            checkmarkColor: Colors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!),
                            ),
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
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("Apply Filters", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final isSelected = _filterType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setModalState(() {
          _filterType = selected ? value : null;
        });
      },
      selectedColor: Colors.black,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilter = _filterType != null || 
                                 _filterCategoryIds.isNotEmpty || 
                                 _filterAccountIds.isNotEmpty || 
                                 _tagController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Transactions", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(hasActiveFilter ? Icons.filter_alt : Icons.filter_alt_outlined),
            color: hasActiveFilter ? Colors.blue : Colors.black,
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            // MONTH NAVIGATOR
            Container(
              color: Colors.white,
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
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onRemove,
        backgroundColor: Colors.blue[50],
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No matching transactions",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
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