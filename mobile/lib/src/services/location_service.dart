import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Récupère les coordonnées GPS et l'adresse actuelle (Ville, Quartier, Rue)
  static Future<Map<String, dynamic>?> getCurrentLocationData() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Les services de localisation sont désactivés.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Les permissions de localisation sont refusées.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Les permissions de localisation sont refusées de façon permanente.');
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String street = place.street ?? '';
        String neighborhood = place.subLocality ?? '';
        String city = place.locality ?? '';

        return {
          'latitude': double.parse(position.latitude.toStringAsFixed(6)),
          'longitude': double.parse(position.longitude.toStringAsFixed(6)),
          'city': city.isNotEmpty ? city : 'Inconnue',
          'street': street,
          'neighborhood': neighborhood,
          'formatted_address': "$street, $neighborhood, $city"
              .replaceAll(RegExp(r', ,'), ',')
              .trim(),
        };
      }
    } catch (e) {
      return {
        'latitude': double.parse(position.latitude.toStringAsFixed(6)),
        'longitude': double.parse(position.longitude.toStringAsFixed(6)),
        'city': 'Bobo-Dioulasso', // Ville par défaut si détection échoue
        'street': 'Position GPS',
        'neighborhood':
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        'formatted_address':
            "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}",
      };
    }

    return null;
  }
}
