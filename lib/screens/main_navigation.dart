import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'add_destination_screen.dart';
import 'map_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AddDestinationScreen(),
    const MapScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: _screens[_selectedIndex],

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              height: 60,
              elevation: 0,
              backgroundColor: Colors.white,
              indicatorColor: Theme.of(context).primaryColor.withOpacity(0.15),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined, color: Colors.grey[600]),
                  selectedIcon: Icon(Icons.home_rounded, color: Theme.of(context).primaryColor),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.add_circle_outline, color: Colors.grey[600]),
                  selectedIcon: Icon(Icons.add_circle_rounded, color: Theme.of(context).primaryColor),
                  label: 'Tambah',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined, color: Colors.grey[600]),
                  selectedIcon: Icon(Icons.map_rounded, color: Theme.of(context).primaryColor),
                  label: 'Peta',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}