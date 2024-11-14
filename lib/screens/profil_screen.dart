import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:nomadnotes/services/bottom_nav_bar.dart';
import 'dart:developer' as developer;

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
  String? _error; // Variable pour gérer les messages d'erreur

  // Contrôleurs de texte pour la modification
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  User? get currentUser => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      if (currentUser == null) {
        setState(() {
          _error = "Utilisateur non connecté. Veuillez vous connecter.";
        });
        return;
      }

      DocumentSnapshot userProfile = await _firestore
          .collection('Users') // Assure-toi que cela correspond à ton Firestore
          .doc(currentUser!.uid)
          .get();

      if (userProfile.exists) {
        if (mounted) {
          setState(() {
            _name = userProfile['name'] ?? '';
            _bio = userProfile['bio'] ?? '';
            _imageUrl = userProfile['profileImageUrl'] ?? '';
            _error = null; // Pas d'erreur si tout s'est bien passé
          });
          _nameController.text = _name;
          _bioController.text = _bio;
        }
      } else {
        if (mounted) {
          setState(() {
            _error = "Aucun profil trouvé pour cet utilisateur.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Erreur lors du chargement du profil : $e";
        });
      }
      developer.log("Erreur lors du chargement du profil : $e");
    }
  }

  Future<void> _uploadProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        String downloadUrl;
        if (kIsWeb) {
          final imageBytes = await pickedFile.readAsBytes();
          TaskSnapshot uploadTask = await _storage
              .ref('profile_images/${currentUser!.uid}.jpg')
              .putData(imageBytes);
          downloadUrl = await uploadTask.ref.getDownloadURL();
        } else {
          File imageFile = File(pickedFile.path);
          TaskSnapshot uploadTask = await _storage
              .ref('profile_images/${currentUser!.uid}.jpg')
              .putFile(imageFile);
          downloadUrl = await uploadTask.ref.getDownloadURL();
        }

        if (mounted) {
          setState(() {
            _imageUrl = downloadUrl;
          });
        }

        // Met à jour l'image de profil dans Firestore
        await _firestore
            .collection('Users')
            .doc(currentUser!.uid)
            .update({'profileImageUrl': _imageUrl});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Erreur lors de l'upload de l'image : $e";
        });
      }
      developer.log("Erreur lors de l'upload de l'image : $e");
    }
  }

  Future<void> _updateUserProfile() async {
    try {
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _error = "Utilisateur non connecté. Impossible de mettre à jour le profil.";
          });
        }
        return;
      }

      await _firestore.collection('Users').doc(currentUser!.uid).set({
        'name': _nameController.text.isNotEmpty ? _nameController.text : _name,
        'bio': _bioController.text.isNotEmpty ? _bioController.text : _bio,
        'profileImageUrl': _imageUrl ?? '',
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _error = null; // Pas d'erreur si tout s'est bien passé
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès !')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Erreur lors de la mise à jour du profil : $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour : $e')),
        );
      }
      developer.log("Erreur lors de la mise à jour du profil : $e");
    }
  }

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
              width: screenWidth < 600 ? 30 : 40,
            ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF6EC6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
                const SizedBox(height: 10),
              ],
              CircleAvatar(
                radius: screenWidth < 600 ? 50 : 80,
                backgroundImage: _imageUrl != null && _imageUrl!.isNotEmpty
                    ? NetworkImage(_imageUrl!)
                    : null,
                child: _imageUrl == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
              const SizedBox(height: 20),
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: _uploadProfileImage,
                tooltip: 'Changer l\'image de profil',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateUserProfile,
                child: const Text("Mettre à jour le profil"),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}