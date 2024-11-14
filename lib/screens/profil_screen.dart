import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // Import pour détecter le web
import 'package:go_router/go_router.dart'; // Import de GoRouter
import 'package:nomadnotes/services/bottom_nav_bar.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  ProfilScreenState createState() => ProfilScreenState();
}

class ProfilScreenState extends State<ProfilScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  String? _imageUrl;
  String _name = '';
  String _bio = '';

  // Récupérer l'UID de l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Contrôleurs de texte pour la modification
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (currentUser != null) {
      DocumentSnapshot userProfile = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (userProfile.exists) {
        setState(() {
          _name = userProfile['name'] ?? '';
          _bio = userProfile['bio'] ?? '';
          _imageUrl = userProfile['profileImageUrl'] ?? '';
        });
        _nameController.text = _name;
        _bioController.text = _bio;
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        // Gestion des images pour le web
        final imageBytes = await pickedFile.readAsBytes();
        TaskSnapshot uploadTask = await _storage
            .ref('profile_images/${currentUser!.uid}.jpg')
            .putData(imageBytes);
        String downloadUrl = await uploadTask.ref.getDownloadURL();

        setState(() {
          _imageUrl = downloadUrl;
        });
      } else {
        // Gestion des images pour iOS et Android
        File imageFile = File(pickedFile.path);
        TaskSnapshot uploadTask = await _storage
            .ref('profile_images/${currentUser!.uid}.jpg')
            .putFile(imageFile);
        String downloadUrl = await uploadTask.ref.getDownloadURL();

        setState(() {
          _imageUrl = downloadUrl;
        });
      }

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update({'profileImageUrl': _imageUrl});
    }
  }

  Future<void> _updateUserProfile() async {
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser!.uid).set({
        'name': _nameController.text,
        'bio': _bioController.text,
        'profileImageUrl': _imageUrl,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès !')),
        );
      }
    }
  }

  // Fonction de déconnexion avec redirection
  Future<void> _logoutAndRedirect() async {
    await _auth.signOut();
    if (mounted) {
      GoRouter.of(context).go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Row(
          children: [
            Image.asset(
              'assets/logo_nomadnotes.png',
              width: screenWidth < 600 ? 30 : 40, // Adaptation taille logo
            ),
            const SizedBox(width: 8),
            const Spacer(),
            const Text(
              "NomadNotes - Profil",
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.black),
              onPressed: _logoutAndRedirect,
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF6EC6FF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: screenWidth < 600 ? 50 : 80, // Taille de l'image adaptative
                    backgroundImage: _imageUrl != null && _imageUrl!.isNotEmpty
                        ? NetworkImage(_imageUrl!)
                        : null,
                    child: _imageUrl == null ? const Icon(Icons.person, size: 50) : null,
                  ),
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: _uploadProfileImage,
                    tooltip: 'Changer l\'image de profil',
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                    ),
                  ),
                  SizedBox(
                    width: screenWidth < 600 ? double.infinity : 300, // Largeur adaptative
                    child: ElevatedButton(
                      onPressed: _updateUserProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text("Mettre à jour le profil"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}