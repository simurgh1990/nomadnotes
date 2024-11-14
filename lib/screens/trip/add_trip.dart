import 'package:flutter/material.dart';
import 'package:nomadnotes/services/bottom_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CreateTravelJournalScreen extends StatefulWidget {
  const CreateTravelJournalScreen({super.key});

  @override
  CreateTravelJournalScreenState createState() => CreateTravelJournalScreenState();
}

class CreateTravelJournalScreenState extends State<CreateTravelJournalScreen> {
  bool isPinned = false; // État du bouton toggle
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _mainPhotoUrl; // URL de la photo principale

  Future<void> _saveTravelJournal() async {
    final travelData = {
      'titre': _titleController.text,
      'date': _dateController.text,
      'photo_principale': _mainPhotoUrl,
      'lieu': _locationController.text,
      'isPinned': isPinned,
      'createdAt': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance.collection('voyages').add(travelData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Carnet de voyage enregistré !'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de l\'enregistrement : $e'),
        ));
      }
    }
  }

  Future<void> _uploadMainPhoto() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      TaskSnapshot uploadTask;
      if (kIsWeb) {
        final imageBytes = await pickedFile.readAsBytes();
        uploadTask = await FirebaseStorage.instance
            .ref('voyage_images/${DateTime.now()}.jpg')
            .putData(imageBytes);
      } else {
        final imageFile = File(pickedFile.path);
        uploadTask = await FirebaseStorage.instance
            .ref('voyage_images/${DateTime.now()}.jpg')
            .putFile(imageFile);
      }
      String downloadUrl = await uploadTask.ref.getDownloadURL();
      setState(() {
        _mainPhotoUrl = downloadUrl;
      });
    }
  }

  Future<void> _selectLocationOnMap() async {
    final LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectLocationScreen(),
      ),
    );
    if (selectedLocation != null) {
      setState(() {
        _locationController.text = '${selectedLocation.latitude}, ${selectedLocation.longitude}';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Carnet de Voyage'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.71, -0.71),
            end: Alignment(-0.71, 0.71),
            colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Créer un Nouveau Carnet de Voyage',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 77, 55, 55),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Titre du Carnet',
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Date du Voyage (AAAA-MM)',
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      _mainPhotoUrl != null
                          ? Image.network(_mainPhotoUrl!)
                          : const Icon(Icons.image, size: 50, color: Colors.white),
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _uploadMainPhoto,
                        tooltip: 'Ajouter une photo principale',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            labelText: 'Lieu du Voyage',
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.map),
                        onPressed: _selectLocationOnMap,
                        tooltip: 'Sélectionner le lieu sur la carte',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Switch(
                        value: isPinned,
                        onChanged: (value) {
                          setState(() {
                            isPinned = value;
                          });
                        },
                        activeColor: Color(0xFF4CAF50),
                        inactiveThumbColor: Colors.grey,
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white,
                      ),
                      const Text(
                        'Placer mon voyage sur la carte',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveTravelJournal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: Size(200, 50),
                    ),
                    child: Text(
                      'Enregistrer',
                      style: TextStyle(color: Color(0xFF2196F3)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  SelectLocationScreenState createState() => SelectLocationScreenState();
}

class SelectLocationScreenState extends State<SelectLocationScreen> {
  LatLng? _selectedLocation;

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sélectionnez un lieu"),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              },
            )
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(48.8566, 2.3522),
          zoom: 10,
        ),
        onTap: _onMapTap,
        markers: _selectedLocation != null
            ? {Marker(markerId: MarkerId('selected'), position: _selectedLocation!)}
            : {},
      ),
    );
  }
}