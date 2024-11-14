import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex}); 

  void _onItemTapped(BuildContext context, int index) {
    // Gère la navigation ici en fonction de l'index
    switch (index) {
      case 0:
        context.go('/'); // Route vers la page d'accueil
        break;
      case 1:
        context.go('/map'); // Route vers la carte
        break;
      case 2:
        context.go('/cheklist'); // Route vers la checklist
        break;
      case 3:
        context.go('/profil'); // Route vers le profil
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_filled),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          label: 'Carte',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_box),
          label: 'Checklist',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle_outlined),
          label: 'Profil',
        ),
      ],
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFF2196F3),
      unselectedItemColor: Colors.grey,
      onTap: (index) => _onItemTapped(context, index), // Appelle la fonction de navigation
    );
  }
}