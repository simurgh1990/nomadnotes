import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/firestore_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _register() async {
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }

    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestoreService.addUserData(firstName, lastName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscription réussie')),
      );

      context.go('/');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Cet e-mail est déjà utilisé. Veuillez en choisir un autre.';
          break;
        case 'invalid-email':
          errorMessage = 'L\'adresse e-mail n\'est pas valide. Veuillez entrer un e-mail valide.';
          break;
        case 'weak-password':
          errorMessage = 'Le mot de passe est trop faible. Il doit contenir au moins 6 caractères.';
          break;
        default:
          errorMessage = e.message ?? 'Une erreur inconnue est survenue.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur inconnue : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.71, -0.71),
            end: Alignment(-0.71, 0.71),
            colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                // Logo de l'application
                Image.asset(
                  'assets/logo_nomadnotes.png',
                  width: 300,
                  height: 239,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Inscription',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 20),
                // Formulaire d'inscription
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400), // Largeur max pour champs de texte
                    child: Column(
                      children: [
                        // Prénom
                        _buildTextField(controller: _firstNameController, label: 'Prénom'),
                        const SizedBox(height: 16),

                        // Nom
                        _buildTextField(controller: _lastNameController, label: 'Nom'),
                        const SizedBox(height: 16),

                        // Email
                        _buildTextField(controller: _emailController, label: 'Email', icon: Icons.email),
                        const SizedBox(height: 16),

                        // Mot de passe
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Mot de passe',
                          icon: Icons.lock,
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),

                        // Confirmer le mot de passe
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirmez le mot de passe',
                          icon: Icons.lock,
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),

                        // Bouton S'inscrire
                        ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            minimumSize: const Size(300, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text(
                            'S\'inscrire',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Texte et bouton pour redirection vers la connexion
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text(
                            'Déjà inscrit ? Connectez-vous',
                            style: TextStyle(color: Color(0xFF212121)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.black.withOpacity(0.5),
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        prefixIcon: icon != null ? Icon(icon, color: Colors.black.withOpacity(0.5)) : null,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      ),
    );
  }
}