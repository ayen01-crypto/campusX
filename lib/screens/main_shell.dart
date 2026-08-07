import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'sell_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  static const pages = <Widget>[
    HomeScreen(),
    ExploreScreen(),
    SellScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  static const titles = ['Home', 'Explore', 'Sell', 'Messages', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final destinations = const <NavigationDestination>[
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded), label: 'Explore'),
      NavigationDestination(icon: Icon(Icons.add_box_outlined), selectedIcon: Icon(Icons.add_box_rounded), label: 'Sell'),
      NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: 'Messages'),
      NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: CampusColors.primary, borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.school_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(index == 0 ? 'CampusX' : titles[index], style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          IconButton(onPressed: () => context.push('/saved'), icon: const Icon(Icons.bookmark_border_rounded), tooltip: 'Saved'),
          IconButton(onPressed: () => context.push('/notifications'), icon: const Icon(Icons.notifications_none_rounded), tooltip: 'Notifications'),
          const SizedBox(width: 6),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (value) => setState(() => index = value),
                  labelType: NavigationRailLabelType.all,
                  groupAlignment: -.6,
                  destinations: [
                    for (final item in destinations)
                      NavigationRailDestination(icon: item.icon, selectedIcon: item.selectedIcon, label: Text(item.label)),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: IndexedStack(index: index, children: pages)),
              ],
            )
          : IndexedStack(index: index, children: pages),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              destinations: destinations,
            ),
    );
  }
}
