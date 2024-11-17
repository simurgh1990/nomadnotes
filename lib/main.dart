import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Correct package
import 'package:permission_handler/permission_handler.dart'; // Ajout pour la gestion des permissions
import 'firebase_options.dart';

// Import des pages
import 'screens/home_screen.dart';
import 'screens/trip/trip_screen.dart';
import 'screens/trip/add_trip.dart';
import 'screens/checklist_screen.dart';
import 'screens/profil_screen.dart';
import 'screens/auth/login.dart';
import 'screens/auth/register.dart';
import 'screens/map_screen.dart';

final Logger logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 

  // Initialisation de Firebase
  await Firebase.initializeApp(
    options: kIsWeb
        ? const FirebaseOptions(
            apiKey: "AIzaSyDWBQ0DwZxpzeSR9ZwM-InNb6dhn3E4xNo",
            authDomain: "carnet-de-voyage-20c9a.firebaseapp.com",
            projectId: "carnet-de-voyage-20c9a",
            storageBucket: "carnet-de-voyage-20c9a.appspot.com",
            messagingSenderId: "156623633534",
            appId: "1:156623633534:web:2c41d045c952e12f062c2f",
          )
        : DefaultFirebaseOptions.currentPlatform,
  );

  // Activation de Firebase App Check
  if (kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('6Ldipn0qAAAAAIA64UGrh8U2WhT2VkNLGHrtkgkl'),
    );
  }

  // Demander les permissions pour la localisation avant de lancer l'application
  await _requestLocationPermission();

  runApp(const NomadNotes());
}

// Gestion des permissions pour la localisation
Future<void> _requestLocationPermission() async {
  var status = await Permission.location.request();
  if (status.isGranted) {
    logger.i("Permission accordée !");
  } else if (status.isDenied) {
    logger.i("Permission refusée.");
  } else if (status.isPermanentlyDenied) {
    logger.i("Permission refusée de manière permanente. Ouvrez les paramètres pour l'autoriser.");
    await openAppSettings(); // Ouvre les paramètres si l'utilisateur refuse en permanence
  }
}

class NomadNotes extends StatelessWidget {
  const NomadNotes({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Pendant la vérification de l'état de connexion, afficher un loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final bool isLoggedIn = snapshot.hasData;

        // Configuration de GoRouter
        final GoRouter router = GoRouter(
          // Définir la route initiale
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => isLoggedIn ? const HomeScreen() : const LoginScreen(),
            ),
            GoRoute(
              path: '/trip_screen/:tripId',
              builder: (context, state) {
                final tripId = state.pathParameters['tripId']!;
                return isLoggedIn ? TripDetailScreen(tripId: tripId) : const LoginScreen();
              },
            ),
            GoRoute(
              path: '/profil',
              builder: (context, state) => isLoggedIn ? const ProfilScreen() : const LoginScreen(),
            ),
            GoRoute(
              path: '/login',
              builder: (context, state) => const LoginScreen(),
            ),
            GoRoute(
              path: '/register',
              builder: (context, state) => const RegisterScreen(),
            ),
            GoRoute(
              path: '/map',
              builder: (context, state) => isLoggedIn ? MapScreen() : const LoginScreen(),
            ),
            GoRoute(
              path: '/cheklist',
              builder: (context, state) => isLoggedIn ? ChecklistScreen() : const LoginScreen(),
            ),
            GoRoute(
              path: '/add_trip',
              builder: (context, state) => isLoggedIn ? CreateTravelJournalScreen() : const LoginScreen(),
            ),
          ],

          redirect: (context, state) {
            final currentLocation = state.uri.toString();

            // Empêcher l'accès aux pages sans être connecté
            if (!isLoggedIn && currentLocation != '/login' && currentLocation != '/register') {
              return '/login';
            }

            // Redirection vers la page d'accueil pour les utilisateurs déjà connectés
            if (isLoggedIn && (currentLocation == '/login' || currentLocation == '/register')) {
              return '/';
            }

            return null; // Pas de redirection nécessaire
          },
          refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
        );

        // Retourne MaterialApp avec le router
        return MaterialApp.router(
          title: 'Carnet de Voyage',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          routerConfig: router,
        );
      },
    );
  }
}

// Classe pour rafraîchir GoRouter à chaque changement d'état d'authentification
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners(); // Notification initiale

    stream.listen((_) {
      notifyListeners(); // Notification à chaque changement d'état
    });
  }
}