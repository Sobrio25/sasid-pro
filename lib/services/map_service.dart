import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class MapService {
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

  static Future<List<LatLng>> loadNtc04Zones() async {
    try {
      final txt = await rootBundle.loadString('assets/Mapa/NTC04-Zonas.txt');
      return _parseAreaTxt(txt).expand((e) => e).toList();
    } catch (_) {
      return [];
    }
  }
}
