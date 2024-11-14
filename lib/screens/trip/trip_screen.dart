import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:nomadnotes/services/bottom_nav_bar.dart';
import 'step_trip_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadTripDetails();
  }

  Future<void> _loadTripDetails() async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('voyages')
        .doc(widget.tripId)
        .get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data()!;
      setState(() {
        _titleController.text = data['titre'] ?? '';
        _dateController.text = data['date'] ?? '';
        _locationController.text = data['lieu'] ?? '';
        _mainPhotoUrl = data['photo_principale'];
        isPinned = data['isPinned'] ?? false;
      });
    }
  }

  Future<void> _saveTripDetails() async {
    final tripData = {
      'titre': _titleController.text,
      'date': _dateController.text,
      'lieu': _locationController.text,
      'photo_principale': _mainPhotoUrl,
      'isPinned': isPinned,
    };

    await FirebaseFirestore.instance
        .collection('voyages')
        .doc(widget.tripId)
        .update(tripData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voyage mis à jour avec succès')),
      );
    }
  }

  Future<String> _uploadMainPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
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
      return await uploadTask.ref.getDownloadURL();
    }
    return '';
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
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Titre du voyage',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Entrez le titre du voyage',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Date du voyage',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                hintText: 'Entrez la date (AAAA-MM)',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Lieu du voyage',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'Entrez le lieu',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Photo principale',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_mainPhotoUrl != null)
              Image.network(
                _mainPhotoUrl!,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 50);
                },
              ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () async {
                final photoUrl = await _uploadMainPhoto();
                if (photoUrl.isNotEmpty && mounted) {
                  setState(() {
                    _mainPhotoUrl = photoUrl;
                  });
                }
              },
              tooltip: 'Changer la photo principale',
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
                ),
                const Text('Épingler ce voyage sur la carte'),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveTripDetails,
              child: const Text('Enregistrer les modifications'),
            ),
            const SizedBox(height: 20),
            StepTripScreen(tripId: widget.tripId), // Intègre l'écran des étapes
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}