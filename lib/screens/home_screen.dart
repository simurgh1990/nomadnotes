import 'package:flutter/material.dart';
import 'package:nomadnotes/services/bottom_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Liste des voyages (vide pour l'instant)
  static const List<Map<String, String>> _trips = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // Fond blanc pour l'en-tête
        elevation: 2, // Légère ombre pour l'en-tête
        title: Row(
          children: [
            // Logo à gauche
            Image.asset(
              'assets/logo_nomadnotes.png',
              width: 40, // Taille du logo
            ),
            const SizedBox(width: 8), // Espacement entre le logo et le titre
            const Spacer(), // Espace flexible pour centrer le titre
            const Text(
              "NomadNotes - Accueil",
              style: TextStyle(color: Colors.black, fontSize: 18), // Titre en noir
            ),
            const Spacer(), // Espace flexible pour équilibrer à droite
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF6EC6FF)], // Couleurs de dégradé
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _trips.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Aucun voyage n'a été créé.",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue, // Bouton bleu
                              foregroundColor: Colors.white, // Texte en blanc
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/add_trip'); // Navigue vers l'ajout de voyage
                            },
                            child: const Text("Créer un nouveau voyage"),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _trips.length,
                      itemBuilder: (context, index) {
                        final trip = _trips[index];
                        return _buildTripCard(trip);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildTripCard(Map<String, String> trip) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.asset(
                trip['image']!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image); // Placeholder si image manquante
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip['title']!,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Date: ${trip['date']}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Logique pour la navigation vers les détails du voyage
                  },
                  child: const Text('Voir Détails'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}