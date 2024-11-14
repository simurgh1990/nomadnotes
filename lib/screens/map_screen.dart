import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:go_router/go_router.dart';
import 'package:nomadnotes/services/bottom_nav_bar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  final Logger _logger = Logger();

  final LatLng _initialPosition = const LatLng(48.8566, 2.3522);

  @override
  void initState() {
    super.initState();
    _loadPinnedTrips();
  }

  Future<void> _loadPinnedTrips() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('voyages')
        .where('isPinned', isEqualTo: true)
        .get();

    setState(() {
      _markers.clear();
      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        _logger.d('Document récupéré : ${doc.id}, data: $data');

        if (data.containsKey('lieu') && data['lieu'] is String) {
          final locationString = data['lieu'] as String;
          final coordinates = locationString.split(', ');
          if (coordinates.length == 2) {
            try {
              final latitude = double.parse(coordinates[0]);
              final longitude = double.parse(coordinates[1]);
              final LatLng position = LatLng(latitude, longitude);

              _logger.d('Ajout du marqueur avec position: $position');

              _markers.add(
                Marker(
                  markerId: MarkerId(doc.id),
                  position: position,
                  infoWindow: InfoWindow(
                    title: data['titre'] ?? 'Voyage sans titre',
                    snippet: 'Cliquez pour voir les détails',
                    onTap: () => _showTripDialog(doc.id, data),
                  ),
                ),
              );
            } catch (e) {
              _logger.e('Erreur lors de la conversion des coordonnées: $e');
            }
          } else {
            _logger.w('Format du champ lieu invalide pour le document : ${doc.id}');
          }
        } else {
          _logger.w('Document sans coordonnées GPS : ${doc.id}');
        }
      }
    });
  }

  void _showTripDialog(String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(data['titre'] ?? 'Détails du voyage'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data['photo_principale'] != null)
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Image.network(
                      data['photo_principale'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 50);
                      },
                    ),
                  ),
                const SizedBox(height: 10),
                Text(data['date'] ?? 'Date inconnue'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                GoRouter.of(context).go('/trip_screen/$docId');
              },
              child: const Text('Voir Détails'),
            ),
          ],
        );
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NomadNotes - Carte'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 2.0,
        ),
        markers: _markers,
        zoomControlsEnabled: true,
        myLocationEnabled: true,
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}