import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sasid_app/services/map_service.dart';

void main() {
  // Reproduce la lógica de parseo de loadZonasGeotecnica sin depender del
  // asset, para validar Polygon y MultiPolygon.
  List<ZonaGeo> parseGeoJson(String txt) {
    final data = jsonDecode(txt) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>;
    final out = <ZonaGeo>[];
    for (final f in features) {
      final props = f['properties'] as Map<String, dynamic>;
      final geom = f['geometry'] as Map<String, dynamic>;
      final List<dynamic> ringsRaw;
      switch (geom['type'] as String) {
        case 'Polygon':
          ringsRaw = geom['coordinates'] as List<dynamic>;
          break;
        case 'MultiPolygon':
          ringsRaw = (geom['coordinates'] as List<dynamic>)
              .expand((p) => p as List<dynamic>)
              .toList();
          break;
        default:
          continue;
      }
      if (ringsRaw.isEmpty) continue;
      final rings = <List<LatLng>>[];
      for (final ring in ringsRaw) {
        final pts = (ring as List<dynamic>)
            .map(
              (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
            )
            .toList();
        if (pts.length >= 3) rings.add(pts);
      }
      if (rings.isEmpty) continue;
      out.add(
        ZonaGeo(
          zona: props['zona']?.toString() ?? '',
          nombre: props['nombre']?.toString() ?? '',
          rings: rings,
        ),
      );
    }
    return out;
  }

  group('MapService GeoJSON parser', () {
    test('Parsea Polygon con coordenadas [lon,lat]', () {
      const txt =
          '{"type":"FeatureCollection","features":[{"type":"Feature",'
          '"properties":{"zona":"Zona I","nombre":"Zona firme de lomas"},'
          '"geometry":{"type":"Polygon","coordinates":[['
          '[-99.30,19.15],[-98.85,19.15],[-98.85,19.60],[-99.30,19.60],'
          '[-99.30,19.15]]]}}]}';
      final zonas = parseGeoJson(txt);
      expect(zonas.length, 1);
      expect(zonas.first.zona, 'Zona I');
      expect(zonas.first.rings.length, 1);
      final ring = zonas.first.rings.first;
      expect(ring.length, 5);
      // GeoJSON es [lon,lat]; LatLng es (lat,lon)
      expect(ring.first.latitude, 19.15);
      expect(ring.first.longitude, -99.30);
    });

    test('Parsea MultiPolygon aplanando anillos', () {
      const txt =
          '{"type":"FeatureCollection","features":[{"type":"Feature",'
          '"properties":{"zona":"Zona II","nombre":"Zona de transición"},'
          '"geometry":{"type":"MultiPolygon","coordinates":['
          '[[[-99.20,19.40],[-99.10,19.40],[-99.10,19.45],[-99.20,19.45],'
          '[-99.20,19.40]]],'
          '[[[-99.15,19.50],[-99.05,19.50],[-99.05,19.55],[-99.15,19.55],'
          '[-99.15,19.50]]]'
          ']}}]}';
      final zonas = parseGeoJson(txt);
      expect(zonas.length, 1);
      expect(zonas.first.rings.length, 2);
      expect(zonas.first.rings[1].first.latitude, 19.50);
    });

    test('Ignora anillos degenerados (<3 puntos)', () {
      const txt =
          '{"type":"FeatureCollection","features":[{"type":"Feature",'
          '"properties":{"zona":"Zona III"},'
          '"geometry":{"type":"Polygon","coordinates":[[[-99.1,19.3]],['
          '[-99.1,19.3],[-99.0,19.3],[-99.0,19.35],[-99.1,19.3]]]}}]}';
      final zonas = parseGeoJson(txt);
      expect(zonas.length, 1);
      expect(zonas.first.rings.length, 1); // solo el anillo válido
    });
  });
}
