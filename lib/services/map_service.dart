import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

/// Polígono de zonificación geotécnica oficial con sus anillos exteriores.
class ZonaGeo {
  final String zona; // 'Zona I' | 'Zona II' | 'Zona III'
  final String nombre;
  final List<List<LatLng>> rings;

  const ZonaGeo({
    required this.zona,
    required this.nombre,
    required this.rings,
  });
}

class MapService {
  /// Zonificación geotécnica oficial NTC-2017 desde GeoJSON (WGS84).
  static Future<List<ZonaGeo>> loadZonasGeotecnica() async {
    try {
      final txt = await rootBundle.loadString(
        'assets/geojson/zonificacion_geotecnica_2017.geojson',
      );
      final data = jsonDecode(txt) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>;
      final List<ZonaGeo> out = [];
      for (final f in features) {
        final props = f['properties'] as Map<String, dynamic>;
        final geom = f['geometry'] as Map<String, dynamic>;

        // Polygon: coordinates es [[anillo],[agujero]...]
        // MultiPolygon: coordinates es [[[anillo]...],[...]...]
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
                (c) =>
                    LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
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
    } catch (_) {
      return [];
    }
  }

  static Future<List<List<LatLng>>> loadAreaPolygons() async {
    final List<List<LatLng>> all = [];
    for (int i = 2; i <= 17; i++) {
      final path = 'assets/Mapa/Area${i.toString().padLeft(2, '0')}.txt';
      try {
        final txt = await rootBundle.loadString(path);
        final polys = _parseAreaTxt(txt);
        all.addAll(polys);
      } catch (_) {}
    }
    return all;
  }

  static List<List<LatLng>> _parseAreaTxt(String txt) {
    final lines = txt
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final List<List<LatLng>> polygons = [];
    List<LatLng> current = [];
    for (final line in lines) {
      if (line.contains('\t') || line.contains(' ')) {
        final parts = line.split(RegExp(r'[\s\t]+'));
        if (parts.length >= 2) {
          final lon = double.tryParse(parts[0]);
          final lat = double.tryParse(parts[1]);
          if (lon != null &&
              lat != null &&
              lon.abs() <= 180 &&
              lat.abs() <= 90) {
            current.add(LatLng(lat, lon));
            continue;
          }
        }
      }
      if (current.length > 2) polygons.add(List.from(current));
      current = [];
    }
    if (current.length > 2) polygons.add(current);
    return polygons;
  }
}
