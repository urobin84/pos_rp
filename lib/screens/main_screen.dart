import 'package:flutter/material.dart';
import 'package:pos_rp/screens/cashier_screen.dart';
import 'package:pos_rp/screens/customer_screen.dart';
import 'package:pos_rp/screens/home_screen.dart';
import 'package:pos_rp/screens/product_screen.dart';
import 'package:pos_rp/screens/settings_screen.dart';

/// This is the main screen of the app which contains the navigation logic.
/// It displays a BottomNavigationBar for narrow screens and a NavigationRail
/// for wider screens.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

enum _NavigationRailState { hidden, collapsed, expanded }

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  _NavigationRailState _railState = _NavigationRailState.expanded;

  // List of pages to be displayed in the BottomNavigationBar.
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ProductScreen(),
    CashierScreen(),
    CustomerScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _cycleRailState() {
    setState(() {
      switch (_railState) {
        case _NavigationRailState.hidden:
          _railState = _NavigationRailState.expanded;
          break;
        case _NavigationRailState.expanded:
          _railState = _NavigationRailState.collapsed;
          break;
        case _NavigationRailState.collapsed:
          _railState = _NavigationRailState.hidden;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 720;

    if (isWideScreen) {
      return _buildWideLayout();
    } else {
      return _buildNarrowLayout();
    }
  }

  Widget _buildWideLayout() {
    return Scaffold(
      body: Row(
        children: [
          if (_railState != _NavigationRailState.hidden)
            NavigationRail(
              extended: _railState == _NavigationRailState.expanded,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              leading: IconButton(
                icon: Icon(
                  _railState == _NavigationRailState.expanded
                      ? Icons.menu_open
                      : Icons.menu,
                ),
                onPressed: _cycleRailState,
              ),
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: Text('Product'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale),
                  label: Text('Cashier'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outlined),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Customer'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
          if (_railState != _NavigationRailState.hidden)
            const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Stack(
              children: [
                _widgetOptions[_selectedIndex],
                if (_railState == _NavigationRailState.hidden)
                  Positioned(
                    top: 8.0,
                    left: 8.0,
                    child: SafeArea(
                      child: Material(
                        elevation: 4.0,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        color: Theme.of(context).colorScheme.surface,
                        child: IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: _cycleRailState,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    final theme = Theme.of(context);
    return Scaffold(
      body: _widgetOptions[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(2),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 2.0,
        shape: const CircleBorder(),
        child: const Icon(Icons.point_of_sale),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: theme.colorScheme.surfaceContainer,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          children: <Widget>[
            _buildNavItem(icon: Icons.home, label: 'Home', index: 0),
            _buildNavItem(icon: Icons.inventory_2, label: 'Product', index: 1),
            const Spacer(),
            _buildNavItem(icon: Icons.people, label: 'Customer', index: 3),
            _buildNavItem(icon: Icons.settings, label: 'Settings', index: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final theme = Theme.of(context);
    final color =
        _selectedIndex == index
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
