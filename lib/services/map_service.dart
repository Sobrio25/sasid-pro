import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

/// Un polígono con anillo exterior y agujeros (islotes recortados).
class ZonaPolygon {
  final List<LatLng> outer;
  final List<List<LatLng>> holes;

  const ZonaPolygon({required this.outer, required this.holes});
}

/// Capa de zonificación geotécnica oficial NTC-2017.
///
/// Cada zona vive en su propio GeoJSON (`assets/geojson/zona_{i,ii,iii}.geojson`)
/// convertido del ShapeFile oficial (Mexico ITRF2008 / UTM 14N -> WGS84).
/// Según la especificación ESRI los anillos CW son exteriores y los CCW
/// agujeros; el GeoJSON conserva esa estructura como [exterior, agujero...].
class MapService {
  static const List<String> zonas = ['I', 'II', 'III'];

  static final Map<String, List<ZonaPolygon>> _cache = {};

  /// Carga la capa de una zona ('I' | 'II' | 'III') con cache.
  static Future<List<ZonaPolygon>> loadZona(String zona) async {
    if (_cache.containsKey(zona)) return _cache[zona]!;
    try {
      final txt = await rootBundle.loadString(
        'assets/geojson/zona_${zona.toLowerCase()}.geojson',
      );
      final data = jsonDecode(txt) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>;
      final List<ZonaPolygon> out = [];
      for (final f in features) {
        final geom = f['geometry'] as Map<String, dynamic>;
        // Polygon: [exterior, agujero...] | MultiPolygon: [[ext, huecos]...]
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
          final outer = _toLatLng(rings[0]);
          if (outer.length < 3) continue;
          final holes = <List<LatLng>>[];
          for (var i = 1; i < rings.length; i++) {
            final h = _toLatLng(rings[i]);
            if (h.length >= 3) holes.add(h);
          }
          out.add(ZonaPolygon(outer: outer, holes: holes));
        }
      }
      _cache[zona] = out;
      return out;
    } catch (_) {
      _cache[zona] ??= const [];
      return _cache[zona]!;
    }
  }

  /// Zona geotécnica oficial en el punto dado: 'Zona I' | 'Zona II' |
  /// 'Zona III' | null (fuera de cobertura).
  ///
  /// Prioridad I > II > III: las zonas específicas tienen precedencia sobre
  /// la envolvente del lago. Un punto cuenta dentro solo si cae en el anillo
  /// exterior y NO en ninguno de sus agujeros.
  static Future<String?> zoneAtPoint(double lat, double lon) async {
    for (final z in zonas) {
      final polys = await loadZona(z);
      for (final poly in polys) {
        if (_pointInRing(lat, lon, poly.outer) &&
            !poly.holes.any((h) => _pointInRing(lat, lon, h))) {
          return 'Zona $z';
        }
      }
    }
    return null;
  }

  static List<LatLng> _toLatLng(List<dynamic> ring) => ring
      .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
      .toList();

  /// Ray-casting estándar punto-en-polígono.
  static bool _pointInRing(double lat, double lon, List<LatLng> ring) {
    var inside = false;
    var j = ring.length - 1;
    for (var i = 0; i < ring.length; i++) {
      final yi = ring[i].latitude;
      final xi = ring[i].longitude;
      final yj = ring[j].latitude;
      final xj = ring[j].longitude;
      if (((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
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
