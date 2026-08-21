import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sasid_app/services/map_service.dart';

// Reproduce la lógica de parseo de MapService.loadZona sin depender del
// asset, validando Polygon/MultiPolygon y anillos de agujeros.
List<ZonaPolygon> parseGeoJson(String txt) {
  final data = jsonDecode(txt) as Map<String, dynamic>;
  final features = data['features'] as List<dynamic>;
  final out = <ZonaPolygon>[];
  for (final f in features) {
    final geom = f['geometry'] as Map<String, dynamic>;
    final List<dynamic> polygonsRaw;
    switch (geom['type'] as String) {
      case 'Polygon':
        polygonsRaw = [geom['coordinates'] as List<dynamic>];
        break;
      case 'MultiPolygon':
        polygonsRaw = geom['coordinates'] as List<dynamic>;
        break;
      default:
        continue;
    }
    for (final ringsRaw in polygonsRaw) {
      final rings = ringsRaw as List<dynamic>;
      if (rings.isEmpty) continue;
      final outer = (rings[0] as List<dynamic>)
          .map(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList();
      if (outer.length < 3) continue;
      final holes = <List<LatLng>>[];
      for (var i = 1; i < rings.length; i++) {
        final h = (rings[i] as List<dynamic>)
            .map(
              (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
            )
            .toList();
        if (h.length >= 3) holes.add(h);
      }
      out.add(ZonaPolygon(outer: outer, holes: holes));
    }
  }
  return out;
}

void main() {
  group('MapService parser GeoJSON por zona', () {
    test('Parsea Polygon simple sin agujeros', () {
      const txt =
          '{"type":"FeatureCollection","features":[{"type":"Feature",'
          '"properties":{"zona":"Zona I"},'
          '"geometry":{"type":"Polygon","coordinates":[['
          '[-99.30,19.15],[-98.85,19.15],[-98.85,19.60],[-99.30,19.60],'
          '[-99.30,19.15]]]}}]}';
      final polys = parseGeoJson(txt);
      expect(polys.length, 1);
      expect(polys.first.outer.length, 5);
      expect(polys.first.holes, isEmpty);
      expect(polys.first.outer.first.latitude, 19.15);
      expect(polys.first.outer.first.longitude, -99.30);
    });

    test('MultiPolygon genera varios ZonaPolygon', () {
      const txt =
          '{"type":"FeatureCollection","features":[{"type":"Feature",'
          '"properties":{"zona":"Zona II"},'
          '"geometry":{"type":"MultiPolygon","coordinates":['
          '[[[-99.20,19.40],[-99.10,19.40],[-99.10,19.45],[-99.20,19.45],'
          '[-99.20,19.40]]],'
          '[[[-99.15,19.50],[-99.05,19.50],[-99.05,19.55],[-99.15,19.55],'
          '[-99.15,19.50]]]'
          ']}}]}';
      final polys = parseGeoJson(txt);
      expect(polys.length, 2);
      expect(polys[1].outer.first.latitude, 19.50);
    });

    test('Primer anillo exterior, siguientes son agujeros', () {
      const txt =
          '{"type":"FeatureCollection","features":[{"type":"Feature",'
          '"properties":{"zona":"Zona III"},'
          '"geometry":{"type":"Polygon","coordinates":[['
          '[-99.2,19.2],[-98.9,19.2],[-98.9,19.6],[-99.2,19.6],[-99.2,19.2]],'
          '[[-99.09,19.43],[-99.08,19.43],[-99.08,19.44],[-99.09,19.44],'
          '[-99.09,19.43]]]'
          '}}]}';
      final polys = parseGeoJson(txt);
      expect(polys.length, 1);
      expect(polys.first.holes.length, 1);
      expect(polys.first.holes.first.first.latitude, 19.43);
    });

    test('Anillo exterior degenerado descarta el polígono', () {
      const txt =
          '{"type":"FeatureCollection","features":[{"type":"Feature",'
          '"properties":{"zona":"Zona I"},'
          '"geometry":{"type":"Polygon","coordinates":[[[-99.1,19.3]],['
          '[-99.1,19.3],[-99.0,19.3],[-99.0,19.35],[-99.1,19.3]]]}}]}';
      expect(parseGeoJson(txt), isEmpty);
    });
  });
}
