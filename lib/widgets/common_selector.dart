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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasError ? Colors.red : Colors.grey[200]!,
            width: hasError ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: hasError ? Colors.red : Colors.grey),
            const SizedBox(width: 12),
            if (leadingEmoji != null) ...[
              Text(leadingEmoji!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                displayValue,
                style: TextStyle(
                  fontSize: 16,
                  color: isEmpty ? Colors.grey[600] : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// --- HELPER CLASS FOR THE BOTTOM SHEET ---
class SelectorSheet {
  static void show<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required void Function(T) onSelected,
    required Widget Function(T) itemBuilder, // Defines how each row looks
    bool isScrollControlled = false,
  }) {
    // 1. Close Keyboard
    FocusScope.of(context).unfocus();

    // 2. Show Sheet
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: isScrollControlled,
      builder: (context) {
        // Use Draggable if list is long (isScrollControlled), else standard
        if (isScrollControlled) {
          return DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.4,
            maxChildSize: 0.8,
            expand: false,
            builder: (_, controller) => _buildContent(controller, title, items, itemBuilder),
          );
        } else {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: _buildContent(null, title, items, itemBuilder),
          );
        }
      },
    );
  }

  static Widget _buildContent<T>(
    ScrollController? controller,
    String title,
    List<T> items,
    Widget Function(T) itemBuilder,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (controller != null) ...[
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
        ],
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            controller: controller,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, i) => itemBuilder(items[i]),
          ),
        ),
      ],
    );
  }
}