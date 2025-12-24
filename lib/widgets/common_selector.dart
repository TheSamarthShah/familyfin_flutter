import 'package:flutter/material.dart';

class SelectorButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String displayValue;
  final VoidCallback onTap;
  final String? leadingEmoji;
  final bool hasError;
  final bool isEmpty;

  const SelectorButton({
    super.key,
    required this.label,
    required this.icon,
    required this.displayValue,
    required this.onTap,
    this.leadingEmoji,
    this.hasError = false,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Get Theme Data
    final theme = Theme.of(context);
    
    // Determine colors based on state
    final borderColor = hasError 
        ? theme.colorScheme.error 
        : theme.colorScheme.outline.withOpacity(0.2); // Adaptive border
    
    final iconColor = hasError 
        ? theme.colorScheme.error 
        : theme.colorScheme.onSurfaceVariant; // Adaptive icon grey

    final textColor = isEmpty 
        ? theme.colorScheme.onSurface.withOpacity(0.4) // Placeholder grey
        : theme.colorScheme.onSurface; // Main text color

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface, // ✅ Adaptive Background (White/Dark Grey)
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: hasError ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            if (leadingEmoji != null) ...[
              Text(leadingEmoji!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                displayValue,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

// --- HELPER CLASS FOR THE BOTTOM SHEET ---
class SelectorSheet {
// ... inside SelectorSheet class ...

  static void show<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required void Function(T) onSelected,
    required Widget Function(T) itemBuilder, 
    bool isScrollControlled = false,
    VoidCallback? onManage, // <--- NEW PARAMETER
  }) {
    FocusScope.of(context).unfocus();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: isScrollControlled,
      builder: (ctx) {
        if (isScrollControlled) {
          return DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.4,
            maxChildSize: 0.8,
            expand: false,
            // Pass onManage here
            builder: (_, controller) => _buildContent(ctx, controller, title, items, itemBuilder, onManage),
          );
        } else {
          // Pass onManage here
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: _buildContent(ctx, null, title, items, itemBuilder, onManage),
          );
        }
      },
    );
  }

  static Widget _buildContent<T>(
    BuildContext context,
    ScrollController? controller,
    String title,
    List<T> items,
    Widget Function(T) itemBuilder,
    VoidCallback? onManage, // <--- NEW PARAMETER
  ) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (controller != null) ...[
          const SizedBox(height: 10),
          Container(
            width: 40, height: 4, 
            decoration: BoxDecoration(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.2), borderRadius: BorderRadius.circular(2))
          ),
          const SizedBox(height: 10), // Reduced spacing
        ],
        
        // --- NEW HEADER WITH ACTION ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              if (onManage != null)
                TextButton.icon(
                  onPressed: onManage,
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text("Manage"),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        
        Expanded(
          child: items.isEmpty 
          ? Center(child: Text("No items found", style: TextStyle(color: theme.colorScheme.onSurfaceVariant)))
          : ListView.separated(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.5), height: 1),
              itemBuilder: (ctx, i) => itemBuilder(items[i]),
            ),
        ),
      ],
    );
  }
}