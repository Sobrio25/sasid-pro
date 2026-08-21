import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cdmx_preset.dart';

class GeocodingSearchResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String source;

  const GeocodingSearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.source,
  });
}

class GeocodingService {
  /// Busca ubicaciones en la CDMX mediante OpenStreetMap Nominatim o catálogo local
  static Future<List<GeocodingSearchResult>> searchAddress(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final List<GeocodingSearchResult> results = [];

    // 1. Búsqueda primero en catálogo local CDMX de alta velocidad
    for (final landmark in CdmxPresets.landmarks) {
      if (landmark.name.toLowerCase().contains(cleanQuery) ||
          landmark.subtitle.toLowerCase().contains(cleanQuery)) {
        results.add(GeocodingSearchResult(
          displayName: '${landmark.name} (${landmark.subtitle})',
          latitude: landmark.latitude,
          longitude: landmark.longitude,
          source: 'Punto de interés CDMX',
        ));
      }
    }

    for (final alc in CdmxPresets.alcaldias) {
      if (alc.name.toLowerCase().contains(cleanQuery)) {
        results.add(GeocodingSearchResult(
          displayName: 'Alcaldía ${alc.name} (Centro)',
          latitude: alc.latitude,
          longitude: alc.longitude,
          source: 'Alcaldía CDMX',
        ));
      }
    }

    // 2. Búsqueda remota mediante OpenStreetMap Nominatim restringido a CDMX
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'q=${Uri.encodeComponent('$query, Ciudad de Mexico, Mexico')}'
        '&format=json'
        '&addressdetails=1'
        '&limit=5'
        '&viewbox=-99.38,19.05,-98.88,19.60'
        '&bounded=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'SASID_Flutter_App/1.0 (ingenieria_sismica_cdmx)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        for (final item in data) {
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          final name = item['display_name'] as String? ?? 'Ubicación';

          if (lat != null && lon != null) {
            // Evitar duplicados exactos
            if (!results.any((r) => (r.latitude - lat).abs() < 0.001 && (r.longitude - lon).abs() < 0.001)) {
              results.add(GeocodingSearchResult(
                displayName: name,
                latitude: lat,
                longitude: lon,
                source: 'OpenStreetMap Geocoder',
              ));
            }
          }
        }
      }
    } catch (_) {
      // Modo offline transparente si no hay conexión a internet
    }

    return results;
  }
}
