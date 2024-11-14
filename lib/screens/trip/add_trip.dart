import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nomadnotes/services/bottom_nav_bar.dart';
import 'package:go_router/go_router.dart';

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
    final user = FirebaseAuth.instance.currentUser;

    // Vérification de connexion utilisateur
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vous devez être connecté pour ajouter un voyage.")),
        );
      }
      return;
    }

    // Données à sauvegarder
    final travelData = {
      'titre': _titleController.text,
      'date': _dateController.text,
      'photo_principale': _mainPhotoUrl,
      'lieu': _locationController.text,
      'isPinned': isPinned,
      'createdAt': Timestamp.now(),
    };

    try {
      // Ajout des données à Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('Voyages')
          .add(travelData);

      // Message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Carnet de voyage enregistré !')),
        );

        // Utilisation de GoRouter pour revenir à la page précédente
        context.go('/');
      }
    } catch (e) {
      // Gestion des erreurs
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
        );
      }
    }
  }

  Future<void> _uploadMainPhoto() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
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
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        if (mounted) {
          setState(() {
            _mainPhotoUrl = downloadUrl;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'upload de la photo : $e')),
          );
        }
      }
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
        decoration: const BoxDecoration(
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
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 77, 55, 55),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre du Carnet',
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
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
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Lieu du Voyage',
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(),
                    ),
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
                        activeColor: const Color(0xFF4CAF50),
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
                      minimumSize: const Size(200, 50),
                    ),
                    child: const Text(
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