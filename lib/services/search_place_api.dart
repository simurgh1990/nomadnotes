import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:developer' as developer;

const String googleApiKey = "AIzaSyAoENo1a6tHw4jGFe5YIkaxdUo6mSZJYDA";

Future<List<Map<String, dynamic>>> fetchPlaceSuggestions(String query) async {
  try {
    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$googleApiKey";
    developer.log("Appel API : $url");

    final response = await http.get(Uri.parse(url));
    developer.log("Code statut : ${response.statusCode}");
    developer.log("Réponse brute : ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final predictions = data['predictions'] as List;
      return predictions
          .map((prediction) => {
                'description': prediction['description'],
                'placeId': prediction['place_id'],
              })
          .toList();
    } else {
      throw Exception("Erreur lors de l'appel API : ${response.statusCode}");
    }
  } catch (e) {
    developer.log("Erreur dans fetchPlaceSuggestions : $e");
    rethrow;
  }
}

Future<LatLng?> fetchPlaceCoordinates(String placeId) async {
  final url =
      "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleApiKey";
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final location = data['result']['geometry']['location'];
    return LatLng(location['lat'], location['lng']);
  } else {
    throw Exception("Erreur lors de l'appel à l'API : ${response.statusCode}");
  }
}
