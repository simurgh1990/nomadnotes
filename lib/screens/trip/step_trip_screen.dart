import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';

class StepTripScreen extends StatefulWidget {
  final String tripId;

  const StepTripScreen({super.key, required this.tripId});

  @override
  StepTripScreenState createState() => StepTripScreenState();
}

class StepTripScreenState extends State<StepTripScreen> {
  List<Map<String, dynamic>> _steps = [];

  @override
  void initState() {
    super.initState();
    _loadSteps();
  }

  Future<void> _loadSteps() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('Voyages')
        .doc(widget.tripId)
        .collection('Etapes')
        .get();

    setState(() {
      _steps = querySnapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<String> _uploadStepPhoto(XFile file) async {
    TaskSnapshot uploadTask;
    if (kIsWeb) {
      final imageBytes = await file.readAsBytes();
      uploadTask = await FirebaseStorage.instance
          .ref('step_images/${DateTime.now()}.jpg')
          .putData(imageBytes);
    } else {
      final imageFile = File(file.path);
      uploadTask = await FirebaseStorage.instance
          .ref('step_images/${DateTime.now()}.jpg')
          .putFile(imageFile);
    }
    return await uploadTask.ref.getDownloadURL();
  }

  void _showAddStepDialog() {
    final stepNameController = TextEditingController();
    final stepDateController = TextEditingController();
    final locationController = TextEditingController();
    final noteController = TextEditingController();
    XFile? selectedImage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter une étape'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: stepNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'étape',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: stepDateController,
                  decoration: const InputDecoration(
                    labelText: 'Date de l\'étape (AAAA-MM-JJ)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Lieu (coordonnées GPS ou nom de lieu)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Bloc-notes',
                  ),
                ),
                const SizedBox(height: 10),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () async {
                    final picker = ImagePicker();
                    selectedImage = await picker.pickImage(source: ImageSource.gallery);
                  },
                  tooltip: 'Ajouter une photo',
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();

                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    final stepData = {
                      'nom_etape': stepNameController.text,
                      'date_etape': stepDateController.text,
                      'lieu': locationController.text,
                      'bloc_note': noteController.text,
                      'photos': [],
                    };

                    final stepDoc = await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(user.uid)
                        .collection('Voyages')
                        .doc(widget.tripId)
                        .collection('Etapes')
                        .add(stepData);

                    if (selectedImage != null) {
                      final String photoUrl = await _uploadStepPhoto(selectedImage!);
                      if (photoUrl.isNotEmpty) {
                        await stepDoc.update({
                          'photos': FieldValue.arrayUnion([photoUrl]),
                        });
                      }
                    }

                    _loadSteps();
                  },
                  child: const Text('Ajouter'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Étapes du voyage',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        for (var step in _steps)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['nom_etape'] ?? 'Nom inconnu',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Date: ${step['date_etape'] ?? 'Date inconnue'}'),
                  if (step['photos'] != null && (step['photos'] as List).isNotEmpty)
                    Column(
                      children: [
                        for (var photoUrl in step['photos'])
                          Image.network(photoUrl, height: 100, fit: BoxFit.cover),
                      ],
                    ),
                  Text('Notes: ${step['bloc_note'] ?? ''}'),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _showAddStepDialog,
          child: const Text('Ajouter une étape'),
        ),
      ],
    );
  }
}