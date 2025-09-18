import 'package:flutter/material.dart';
import 'package:pos_rp/screens/sales_report_screen.dart';
import 'package:pos_rp/screens/purchases_screen.dart';
import 'package:pos_rp/screens/cash_flow_report_screen.dart';
import 'package:pos_rp/screens/expenses_screen.dart';
import 'package:pos_rp/screens/pnl_report_screen.dart';

import 'inventory_report_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Bisnis')),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          _buildReportCategory(
            context,
            icon: Icons.point_of_sale,
            title: 'Laporan Penjualan',
            subtitle:
                'Analisis pendapatan, produk terlaris, dan performa kasir.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const SalesReportScreen()),
              );
            },
          ),
          _buildReportCategory(
            context,
            icon: Icons.trending_up,
            title: 'Laporan Laba & Rugi (P&L)',
            subtitle: 'Lihat profitabilitas bisnis Anda secara mendalam.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const PnlReportScreen()),
              );
            },
          ),
          _buildReportCategory(
            context,
            icon: Icons.inventory,
            title: 'Laporan Inventaris',
            subtitle: 'Pantau nilai stok, pergerakan barang, dan produk mati.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const InventoryReportScreen(),
                ),
              );
            },
          ),
          _buildReportCategory(
            context,
            icon: Icons.attach_money,
            title: 'Laporan Arus Kas',
            subtitle: 'Lacak semua aliran kas masuk dan keluar dari bisnis.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const CashFlowReportScreen(),
                ),
              );
            },
          ),
          _buildReportCategory(
            context,
            icon: Icons.shopping_cart_checkout,
            title: 'Laporan Pembelian',
            subtitle: 'Rekam semua pembelian barang dari supplier.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const PurchasesScreen()),
              );
            },
          ),
          const Divider(height: 20),
          _buildReportCategory(
            context,
            icon: Icons.receipt_long,
            title: 'Kelola Biaya Operasional',
            subtitle: 'Catat pengeluaran seperti sewa, gaji, dan lainnya.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const ExpensesScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportCategory(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor, size: 36),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ),
      ),
    );
  }
}
