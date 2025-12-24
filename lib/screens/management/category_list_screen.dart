import 'package:flutter/material.dart';
import 'package:foundation_app/services/finance_service.dart';
import 'package:foundation_app/services/master_data_service.dart';
import 'package:foundation_app/services/user_service.dart';
import 'package:provider/provider.dart';
import 'add_edit_category_sheet.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  // ✅ 1. Default Icon Constant
  static const String _defaultIcon = '🏷️';

  String _selectedFilter = 'all'; // 'all', 'income', 'expense'

  @override
  Widget build(BuildContext context) {
    // Hook into your custom AppTheme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final provider = context.watch<MasterDataProvider>();
    final allCategories = provider.categories;
    final userId = UserService().id;

    // Filter Logic
    final filteredList = allCategories.where((c) {
      if (_selectedFilter == 'all') return true;
      return c['type'] == _selectedFilter;
    }).toList();

    // Split Logic
    final customCats = filteredList.where((c) => c['user_id'] == userId).toList();
    final systemCats = filteredList.where((c) => c['user_id'] != userId).toList();

    return Scaffold(
      // ✅ Removed explicit backgroundColor. 
      // It now uses your AppTheme's scaffoldBackgroundColor (0xFF121212 in Dark Mode)
      
      appBar: AppBar(
        title: const Text("Manage Categories"),
        centerTitle: true,
        backgroundColor: Colors.transparent, // Blends with your background
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () => _openSheet(context, null),
            icon: Icon(Icons.add_circle_outline, color: colorScheme.primary),
            tooltip: "Add New",
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Filter Segment ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text("All")),
                  ButtonSegment(value: 'income', label: Text("Income"), icon: Icon(Icons.arrow_downward)),
                  ButtonSegment(value: 'expense', label: Text("Expense"), icon: Icon(Icons.arrow_upward)),
                ],
                selected: {_selectedFilter},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _selectedFilter = newSelection.first);
                },
                // Uses your theme's outline color
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: WidgetStateProperty.all(BorderSide(color: colorScheme.outlineVariant)),
                ),
              ),
            ),
          ),

          // --- List Content ---
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category_outlined, size: 48, color: colorScheme.outline.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          "No ${_selectedFilter == 'all' ? '' : _selectedFilter} categories",
                          style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (customCats.isNotEmpty) ...[
                        _buildSectionHeader(context, "My Categories"),
                        ...customCats.map((c) => _buildTile(context, c, isCustom: true)),
                        const SizedBox(height: 24),
                      ],

                      if (systemCats.isNotEmpty) ...[
                        _buildSectionHeader(context, "System Defaults"),
                        ...systemCats.map((c) => _buildTile(context, c, isCustom: false)),
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary, // Uses your Brand Color (Purple/Blue)
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, Map<String, dynamic> cat, {required bool isCustom}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isExpense = cat['type'] == 'expense';
    // Use your theme's semantic colors (or fallback to standard red/green)
    final typeColor = isExpense ? Colors.pink : Colors.green; 
    
    final String displayIcon = (cat['icon_emoji'] != null && cat['icon_emoji'].toString().isNotEmpty)
        ? cat['icon_emoji']
        : _defaultIcon;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        // ✅ Matches your AppTheme "Cards (Floating Islands)" style
        color: theme.cardTheme.color, // Uses surfaceDark (0xFF1E1E1E) or surfaceLight
        borderRadius: BorderRadius.circular(16), // Consistent with your inputs
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.3), // Subtle border
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        // Icon Container
        leading: Container(
          width: 44, height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            displayIcon, 
            style: const TextStyle(fontSize: 20),
          ),
        ),
        // Text
        title: Text(
          cat['name'],
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          isExpense ? "Expense" : "Income",
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        // Actions
        trailing: isCustom
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 20, color: colorScheme.onSurfaceVariant),
                    onPressed: () => _openSheet(context, cat),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                    onPressed: () => _deleteCategory(context, cat['id']),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              )
            : Tooltip(
                message: "Default Category",
                child: Icon(Icons.lock_outline, size: 18, color: colorScheme.outline),
              ),
      ),
    );
  }

  void _openSheet(BuildContext context, Map<String, dynamic>? cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color, // Matches your card color
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AddEditCategorySheet(category: cat),
    );
  }

  Future<void> _deleteCategory(BuildContext context, String id) async {
    final theme = Theme.of(context);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        title: const Text("Delete Category?"),
        content: Text(
          "This will NOT delete your logs, but they will become 'Uncategorized'.",
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: TextStyle(color: theme.colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Delete", style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FinanceService().deleteCategory(id);
      if (context.mounted) {
        context.read<MasterDataProvider>().refreshCategories();
      }
    }
  }
}