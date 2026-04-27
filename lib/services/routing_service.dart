import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;

  RouteResult({
    required this.points,
    required this.distanceKm,
  });
}
class PlaceSearchResult {
  final String displayName;
  final double lat;
  final double lon;

  PlaceSearchResult({
    required this.displayName,
    required this.lat,
    required this.lon,
  });
}

class RoutingService {
  // Geocodificación inversa usando Nominatim (OpenStreetMap)
  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1');
      
      // Nominatim exige un User-Agent identificando la app
      final response = await http.get(url, headers: {
        'User-Agent': 'LineasUnidasApp/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['address'] != null) {
          final address = data['address'];
          final street = address['road'] ?? address['pedestrian'] ?? address['suburb'] ?? '';
          final city = address['city'] ?? address['town'] ?? address['village'] ?? address['county'] ?? '';
          
          if (street.isNotEmpty && city.isNotEmpty) {
            return '$street, $city';
          } else if (street.isNotEmpty) {
            return street;
          } else if (data['display_name'] != null) {
            // Fallback al nombre a mostrar completo (aunque puede ser muy largo)
            final parts = data['display_name'].toString().split(',');
            return parts.take(2).join(',').trim();
          }
        }
      }
      return 'Dirección desconocida';
    } catch (e) {
      return 'Ubicación actual';
    }
  }

  // Búsqueda de lugares (Autocompletado) usando Nominatim
  static Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    try {
      // Limitamos la búsqueda a Venezuela (countrycodes=ve) 
      // y forzamos que busque en Barinas agregándolo al query.
      final searchQuery = Uri.encodeComponent('$query, Barinas');
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$searchQuery&format=json&limit=5&countrycodes=ve');

      final response = await http.get(url, headers: {
        'User-Agent': 'LineasUnidasApp/1.0',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          return PlaceSearchResult(
            displayName: item['display_name'] ?? 'Desconocido',
            lat: double.parse(item['lat']),
            lon: double.parse(item['lon']),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error buscando lugares: $e');
      return [];
    }
  }

  // Obtener ruta entre dos puntos usando OSRM
  static Future<RouteResult?> getRoute(LatLng start, LatLng end) async {
    try {
      // OSRM usa el formato: lon,lat;lon,lat
      final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;
          
          // distance viene en metros
          final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;
          final distanceKm = distanceMeters / 1000.0;

          // Convertir el GeoJSON [lon, lat] a LatLng de latlong2
          final points = coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();

          return RouteResult(points: points, distanceKm: distanceKm);
        }
      }
      return null;
    } catch (e) {
      print('Error obteniendo ruta OSRM: $e');
      return null;
    }
  }
}
