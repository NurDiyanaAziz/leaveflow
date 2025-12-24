import 'package:flutter/material.dart';

class Navigationbar extends StatefulWidget {
  const Navigationbar({super.key});

  @override
  State<Navigationbar> createState() => _NavigationbarState();
}

class _NavigationbarState extends State<Navigationbar> {
  int currentPageInd = 0; //starting page

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        //HomeScreen(),
      ][currentPageInd],
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageInd = index;
          });
        },
        indicatorColor: Colors.blue,
        selectedIndex: currentPageInd,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home, color: Colors.white),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.contacts, color: Colors.white),
            icon: Icon(Icons.contacts_outlined),
            label: 'Contacts',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.article, color: Colors.white),
            icon: Icon(Icons.article_outlined),
            label: 'Reports',
          ),
        ],
      ), //define bottom nav bar
    );
  }
}
