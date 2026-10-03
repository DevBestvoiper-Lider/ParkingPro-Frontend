import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Barra inferior del mockup: Inicio, Reservas, Mapa, Mis Plazas y Perfil.
class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.navegacion});

  final StatefulNavigationShell navegacion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navegacion,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navegacion.currentIndex,
        height: 68,
        onDestinationSelected: (i) => navegacion.goBranch(
          i,
          initialLocation: i == navegacion.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Reservas',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Mis Plazas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
