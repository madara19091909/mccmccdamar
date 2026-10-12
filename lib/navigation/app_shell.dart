import 'package:echo/features/explore/explore_page.dart';
import 'package:echo/features/home/home_page.dart';
import 'package:echo/features/settings/settings_page.dart';
import 'package:echo/features/stats/stats_page.dart';
import 'package:echo/navigation/app_routes.dart';
import 'package:echo/widgets/cosmic_background.dart';
import 'package:flutter/material.dart';

/// Main screen: bottom navigation + the four primary tabs.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  Widget _page() {
    switch (_index) {
      case 0:
        return const HomePage();
      case 1:
        return const ExplorePage();
      case 2:
        return const StatsPage();
      default:
        return const SettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: KeyedSubtree(key: ValueKey<int>(_index), child: _page()),
          ),
        ),
        floatingActionButton: _index <= 1
            ? FloatingActionButton.extended(
                key: const Key('add_memory_fab'),
                onPressed: () => AppRoutes.openMemoryForm(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('ذكرى جديدة'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.public_outlined),
              selectedIcon: Icon(Icons.public),
              label: 'العالم',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'استكشاف',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'إحصائيات',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}
