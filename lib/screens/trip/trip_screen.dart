import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nomadnotes/services/search_place_api.dart';
import 'package:nomadnotes/services/bottom_nav_bar.dart';
import 'step_trip_screen.dart';


const String googleApiKey = "AIzaSyAoENo1a6tHw4jGFe5YIkaxdUo6mSZJYDA";

class TripDetailScreen extends StatefulWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  TripDetailScreenState createState() => TripDetailScreenState();
}

class TripDetailScreenState extends State<TripDetailScreen> {
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  String? _mainPhotoUrl;
  bool isPinned = false;

  LatLng? _selectedLocation; // Coordonnées pour la carte
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadTripDetails(); // Charger les détails du voyage
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Charger les détails du voyage à partir de Firestore
  Future<void> _loadTripDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('Voyages')
        .doc(widget.tripId)
        .get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data()!;
      if (!mounted) return; // Vérification si le widget est toujours monté
      setState(() {
        _titleController.text = data['titre'] ?? '';
        _dateController.text = data['date'] ?? '';
        _locationController.text = data['lieu'] ?? '';
        _mainPhotoUrl = data['photo_principale'];
        isPinned = data['isPinned'] ?? false;

        // Charger les coordonnées de la carte
        if (data['position'] != null) {
          _selectedLocation = LatLng(
            data['position']['latitude'],
            data['position']['longitude'],
          );
        }
      });
    }
  }

  // Sauvegarder les détails du voyage
  Future<void> _saveTripDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final tripData = {
      'titre': _titleController.text,
      'date': _dateController.text,
      'lieu': _locationController.text,
      'photo_principale': _mainPhotoUrl,
      'isPinned': isPinned,
      'position': _selectedLocation != null
          ? {
              'latitude': _selectedLocation!.latitude,
              'longitude': _selectedLocation!.longitude,
            }
          : null,
    };

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('Voyages')
        .doc(widget.tripId)
        .update(tripData);

    if (!mounted) return; // Vérification si le widget est toujours monté
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voyage mis à jour avec succès')),
    );
  }

  // Recherche un lieu et met à jour les coordonnées
  Future<void> _searchPlace() async {
    final query = _locationController.text;
    if (query.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un lieu à rechercher.')),
      );
      return;
    }

    try {
      final suggestions = await fetchPlaceSuggestions(query);

      if (suggestions.isNotEmpty) {
        final selectedPlace = suggestions.first;
        final coordinates = await fetchPlaceCoordinates(selectedPlace['placeId']);

        if (coordinates != null) {
          if (!mounted) return;
          setState(() {
            _selectedLocation = coordinates;
            _locationController.text = selectedPlace['description'];
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(coordinates, 14),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de récupérer les coordonnées du lieu.')),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun lieu trouvé.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la recherche : $e')),
      );
    }
  }

  // Fonction pour recadrer l'image principale
  Future<void> _cropImage() async {
    if (_mainPhotoUrl == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _mainPhotoUrl!,
      aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recadrer l\'image',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
        ),
        IOSUiSettings(title: 'Recadrer l\'image'),
      ],
    );

    if (croppedFile != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uploadTask = await FirebaseStorage.instance
          .ref('cropped_cartouche_images/${widget.tripId}.jpg')
          .putFile(File(croppedFile.path));
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('Voyages')
          .doc(widget.tripId)
          .update({'cartouche_photo': downloadUrl});

      if (!mounted) return; // Vérification si le widget est toujours monté
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image recadrée mise à jour !')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du voyage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTripDetails,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Titre du voyage', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _titleController),
            const SizedBox(height: 20),
            const Text('Date du voyage', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _dateController),
            const SizedBox(height: 20),
            const Text('Lieu du voyage', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(hintText: 'Saisissez ou recherchez un lieu'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchPlace,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_selectedLocation != null)
              SizedBox(
                height: 300,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation!,
                    zoom: 12,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: _selectedLocation!,
                    ),
                  },
                  onMapCreated: (controller) => _mapController = controller,
                ),
              ),
            const SizedBox(height: 20),
            if (_mainPhotoUrl != null) Image.network(_mainPhotoUrl!),
            ElevatedButton(
              onPressed: _cropImage,
              child: const Text('Recadrer pour la cartouche'),
            ),
            Row(
              children: [
                Switch(
                  value: isPinned,
                  onChanged: (value) {
                    setState(() {
                      isPinned = value;
                    });
                  },
                ),
                const Text('Épingler ce voyage sur la carte'),
              ],
            ),
            const SizedBox(height: 20),
            StepTripScreen(tripId: widget.tripId),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}