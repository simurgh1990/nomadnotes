import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nomadnotes/services/bottom_nav_bar.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
        child: StreamBuilder<QuerySnapshot>(
          stream: _getUserTripsStream(), // Récupère les voyages de l'utilisateur connecté
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(context);
            }

            final trips = snapshot.data!.docs;

            return ListView.builder(
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return _buildTripCard(context, trip);
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  // Fonction pour récupérer les voyages de l'utilisateur
  Stream<QuerySnapshot> _getUserTripsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('Voyages')
        .snapshots();
  }

  // Widget à afficher si aucun voyage n'existe
  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
              context.go('/add_trip'); // Navigue vers l'ajout de voyage
            },
            child: const Text("Créer un nouveau voyage"),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher une cartouche de voyage
  Widget _buildTripCard(BuildContext context, QueryDocumentSnapshot trip) {
    final tripData = trip.data() as Map<String, dynamic>;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // Navigue vers la page des détails du voyage
          context.go('/trip_screen/${trip.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affichage de l'image principale
            tripData['photo_principale'] != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: Image.network(
                      tripData['photo_principale'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 150, // Hauteur fixe pour l'image
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          height: 150,
                          child: const Icon(Icons.broken_image, size: 50),
                        );
                      },
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    height: 150,
                    child: const Icon(Icons.image, size: 50),
                  ),
            // Affichage des informations du voyage
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tripData['titre'] ?? 'Titre non disponible',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Date: ${tripData['date'] ?? 'Date inconnue'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}