import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final tripData = {
      'titre': _titleController.text,
      'date': _dateController.text,
      'lieu': _locationController.text,
      'photo_principale': _mainPhotoUrl,
      'isPinned': isPinned,
    };

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('Voyages')
        .doc(widget.tripId)
        .update(tripData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voyage mis à jour avec succès')),
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
            tooltip: 'Sauvegarder',
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
            TextField(controller: _locationController),
            const SizedBox(height: 20),
            if (_mainPhotoUrl != null) Image.network(_mainPhotoUrl!),
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
    );
  }
}