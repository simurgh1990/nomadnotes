import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool _isMapReady = kIsWeb; // Si on est sur le web, la carte est prête par défaut

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _loadPinnedTrips(); // Charger directement les marqueurs pour le web
    } else {
      _checkPermissionsAndLoadMap(); // Vérifier les permissions avant d'initialiser la carte sur Android/iOS
    }
  }

  Future<void> _checkPermissionsAndLoadMap() async {
    // Demande de permission pour la localisation uniquement sur Android/iOS
    var status = await Permission.location.status;
    if (status.isGranted) {
      _logger.i("Permission de localisation déjà accordée.");
      _initializeMap();
    } else if (status.isDenied) {
      _logger.w("Permission de localisation refusée.");
      var result = await Permission.location.request();
      if (result.isGranted) {
        _logger.i("Permission de localisation accordée après la demande.");
        _initializeMap();
      } else {
        _logger.w("Permission toujours refusée.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "Permission de localisation requise pour afficher la carte."),
            ),
          );
        }
      }
    } else if (status.isPermanentlyDenied) {
      _logger.w("Permission refusée de manière permanente.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Veuillez activer la permission de localisation dans les paramètres."),
          ),
        );
        await openAppSettings(); // Ouvre les paramètres si refusée de manière permanente
      }
    }
  }

  void _initializeMap() {
    if (mounted) {
      setState(() {
        _isMapReady = true;
      });
      _loadPinnedTrips(); // Charger les marqueurs après avoir obtenu la permission
    }
  }

  Future<void> _loadPinnedTrips() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _logger.w("Aucun utilisateur connecté. Impossible de charger les voyages.");
        return;
      }

      // Chemin vers la sous-collection voyages de l'utilisateur connecté
      final userId = currentUser.uid;
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Voyages')
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
              _logger.w(
                  'Format du champ lieu invalide pour le document : ${doc.id}');
            }
          } else {
            _logger.w('Document sans coordonnées GPS : ${doc.id}');
          }
        }
      });
    } catch (e) {
      _logger.e('Erreur lors du chargement des voyages épinglés: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Erreur lors du chargement des données. Vérifiez votre connexion."),
          ),
        );
      }
    }
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
      body: _isMapReady
          ? GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 2.0,
              ),
              markers: _markers,
              zoomControlsEnabled: true,
              myLocationEnabled: true,
            )
          : const Center(
              child: CircularProgressIndicator(), // Loader pendant l'attente
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