import 'package:flutter/material.dart';
import 'package:pos_rp/providers/auth_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pos_rp/screens/printer_settings_screen.dart';
import 'package:pos_rp/providers/settings_provider.dart';
import 'package:pos_rp/themes/app_palettes.dart';
import 'package:pos_rp/screens/transaction_history_screen.dart';
import 'package:pos_rp/screens/reports_screen.dart';
import 'package:pos_rp/screens/shop_profile_screen.dart';
import 'package:pos_rp/screens/profile_screen.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showThemePicker(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Warna Tema'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  appPalettes.map((palette) {
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: palette.seedColor),
                      title: Text(palette.name),
                      onTap: () {
                        settingsProvider.setThemePalette(palette);
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  void _showThemeModePicker(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Use a Consumer to get the latest themeMode for the groupValue
        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return SimpleDialog(
              title: const Text('Pilih Mode Tampilan'),
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Mengikuti Sistem'),
                  value: ThemeMode.system,
                  groupValue: settings.themeMode,
                  onChanged: (value) {
                    if (value != null) settingsProvider.setThemeMode(value);
                    Navigator.of(context).pop();
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Terang'),
                  value: ThemeMode.light,
                  groupValue: settings.themeMode,
                  onChanged: (value) {
                    if (value != null) settingsProvider.setThemeMode(value);
                    Navigator.of(context).pop();
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Gelap'),
                  value: ThemeMode.dark,
                  groupValue: settings.themeMode,
                  onChanged: (value) {
                    if (value != null) settingsProvider.setThemeMode(value);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAboutAppDialog(BuildContext context) async {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final packageInfo = await PackageInfo.fromPlatform();

    if (!context.mounted) return;

    showAboutDialog(
      context: context,
      applicationName: settingsProvider.name ?? 'Kasir Robin Puspa',
      applicationVersion:
          'v${packageInfo.version} (build ${packageInfo.buildNumber})',
      applicationIcon: Image.asset(
        'assets/images/icon.png',
        width: 48,
        height: 48,
      ),
      applicationLegalese: '© ${DateTime.now().year} Robin Puspa',
      children: <Widget>[
        const SizedBox(height: 24),
        const Text(
          'Aplikasi Point of Sale sederhana untuk membantu mengelola bisnis Anda.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          const _SettingsGroupLabel(label: 'Akun & Profil'),
          _SettingsCard(
            icon: Icons.account_circle,
            title: 'User Profile',
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const ProfileScreen()),
                ),
          ),
          _SettingsCard(
            icon: Icons.store,
            title: 'Shop Profile',
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const ShopProfileScreen(),
                  ),
                ),
          ),
          const _SettingsGroupLabel(label: 'Perangkat & Tampilan'),
          _SettingsCard(
            icon: Icons.color_lens,
            title: 'Theme',
            onTap: () => _showThemePicker(context),
          ),
          _SettingsCard(
            icon: Icons.brightness_6_outlined,
            title: 'Mode Tampilan',
            onTap: () => _showThemeModePicker(context),
          ),
          _SettingsCard(
            icon: Icons.print,
            title: 'Printer',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => const PrinterSettingsScreen(),
              ),
            ),
          ),
          const _SettingsGroupLabel(label: 'Bisnis'),
          _SettingsCard(
            icon: Icons.history,
            title: 'Riwayat Transaksi',
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const TransactionHistoryScreen(),
                  ),
                ),
          ),
          _SettingsCard(
            icon: Icons.assessment,
            title: 'Laporan',
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const ReportsScreen()),
                ),
          ),
          const _SettingsGroupLabel(label: 'Tentang'),
          _SettingsCard(
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            onTap: () => _showAboutAppDialog(context),
          ),
          const SizedBox(height: 8),
          const _SettingsGroupLabel(label: 'Sesi'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Colors.red, width: 5.0)),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  if (!context.mounted) return;
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroupLabel extends StatelessWidget {
  const _SettingsGroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 24.0,
        right: 16.0,
        top: 16.0,
        bottom: 8.0,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.colorScheme.primary, width: 5.0),
          ),
        ),
        child: ListTile(leading: Icon(icon), title: Text(title), onTap: onTap),
      ),
    );
  }
}
