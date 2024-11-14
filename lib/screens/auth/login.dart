import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  bool rememberMe = false; // État pour le bouton "Se souvenir de moi"

  // Méthode pour envoyer le idToken au backend
  Future<void> _sendIdTokenToBackend(String idToken) async {
    final url = Uri.parse('http://localhost:5001/auth/login');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'idToken': idToken,
      }),
    );

    if (response.statusCode == 200) {
      _logger.i('Token envoyé au backend avec succès');
    } else {
      _logger.e('Erreur: ${response.body}');
    }
  }

  // Méthode pour la connexion via email
  Future<void> _signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = _auth.currentUser;
      if (user != null) {
        String idToken = await user.getIdToken() ?? ''; // Utilise une chaîne vide si le token est null
        _logger.i(idToken);  // Ce token devra être envoyé au backend
        await _sendIdTokenToBackend(idToken); // Envoyer le token au backend
      }

      if (!mounted) return;
      context.go('/');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.message ?? 'Erreur de connexion'}')),
      );
      _logger.e('FirebaseAuthException: ${e.code} - ${e.message}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur inconnue : $e')),
      );
      _logger.e('Erreur inconnue : $e');
    }
  }

  // Méthode pour gérer la connexion via Google
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      User? user = _auth.currentUser;
      if (user != null) {
        String idToken = await user.getIdToken() ?? ''; // Utilise une chaîne vide si le token est nul
        _logger.i(idToken);  // Ce token devra être envoyé au backend
        await _sendIdTokenToBackend(idToken); // Envoyer le token au backend
      }

      if (!mounted) return;
      context.go('/');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion avec Google : ${e.message}')),
      );
      _logger.e('FirebaseAuthException (Google): ${e.code} - ${e.message}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur inconnue avec Google : $e')),
      );
      _logger.e('Erreur inconnue avec Google : $e');
    }
  }

  // Méthode pour réinitialiser le mot de passe
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un e-mail valide.')),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail de réinitialisation envoyé.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi de l\'e-mail de réinitialisation : $e')),
      );
      _logger.e('Erreur lors de la réinitialisation du mot de passe : $e');
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Déterminer la largeur du formulaire en fonction de la taille de l'écran
            double formWidth = constraints.maxWidth < 600 ? constraints.maxWidth * 0.9 : 400;

            return Center(
              child: SingleChildScrollView(
                child: Container(
                  width: formWidth,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Image.asset(
                        'logo_nomadnotes.png',
                        width: 300,
                        height: 239,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),

                      // Titre "Connexion"
                      const Text(
                        'Connexion',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Champ Email
                      _buildTextField(
                        controller: _emailController,
                        label: 'Entrer votre email',
                        icon: Icons.email,
                      ),
                      const SizedBox(height: 20),

                      // Champ Mot de Passe
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Entrer votre mot de passe',
                        icon: Icons.lock,
                        obscureText: true,
                      ),
                      const SizedBox(height: 30),

                      // Switch "Se souvenir de moi"
                      Row(
                        children: [
                          Switch(
                            value: rememberMe,
                            onChanged: (value) {
                              setState(() {
                                rememberMe = value;
                              });
                            },
                            activeColor: const Color(0xFF4CAF50), // Le cercle devient vert quand activé
                            inactiveThumbColor: Colors.grey, // Couleur du cercle quand il est inactif
                            activeTrackColor: Colors.white, // La piste reste blanche
                            inactiveTrackColor: Colors.white, // La piste reste blanche quand il est inactif
                          ),
                          const Text('Se souvenir de moi', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Bouton de Connexion
                      ElevatedButton(
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          minimumSize: Size(formWidth, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bouton Connexion Google avec logo
                      ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: Image.asset(
                          'google_logo.png',
                          height: 24,
                        ),
                        label: const Text(
                          'Se connecter avec Google',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          minimumSize: Size(formWidth, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Texte pour mot de passe oublié
                      TextButton(
                        onPressed: _resetPassword,
                        child: const Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(color: Color(0xFF212121)),
                        ),
                      ),

                      // Redirection vers l'inscription
                      TextButton(
                        onPressed: () {
                          context.go('/register');
                        },
                        child: const Text(
                          "Pas encore de compte ? Inscrivez-vous",
                          style: TextStyle(color: Color(0xFF212121)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
        labelStyle: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
        prefixIcon: icon != null ? Icon(icon, color: Colors.black.withOpacity(0.5)) : null,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      ),
    );
  }
}