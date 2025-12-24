import 'package:flutter/material.dart';
import 'package:foundation_app/core/app_theme.dart';
import 'package:foundation_app/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, "Data Management"),
          
          // 1. Categories
          _buildSettingsTile(
            context,
            icon: Icons.category_outlined,
            title: "Categories",
            subtitle: "Manage income and expense types",
            onTap: () => Navigator.pushNamed(context, '/categories'),
          ),

          // 2. Accounts
          _buildSettingsTile(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: "Accounts",
            subtitle: "Manage bank accounts and wallets",
            onTap: () => Navigator.pushNamed(context, '/accounts'),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, "App"),

          // 3. Logout (Moved here for convenience)
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: "Log Out",
            color: theme.colorScheme.error,
            onTap: () async {
              await AuthService().signOut();
              if (context.mounted) {
                 Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
          
          const SizedBox(height: 20),
          Center(
            child: Text(
              "Version 1.0.0",
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon, 
    required String title, 
    String? subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final finalColor = color ?? theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: finalColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: finalColor, size: 22),
        ),
        title: Text(
          title, 
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: finalColor,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
        onTap: onTap,
      ),
    );
  }
}