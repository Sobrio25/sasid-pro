import 'package:flutter_test/flutter_test.dart';
import 'package:sasid_app/models/seismic_models.dart';
import 'package:sasid_app/services/map_service.dart';
import 'package:sasid_app/services/seismic_engine.dart';

/// Barrido exhaustivo: para una malla densa de puntos sobre la CDMX,
/// la zona que reporta el motor debe coincidir con la del polígono.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Barrido ciudad completa: geometría == motor', () async {
    var evaluados = 0;
    final mismatches = <String>[];
    final porZona = <String, int>{};

    // Malla ~0.025° cubriendo toda la cobertura del ShapeFile.
    for (double lat = 19.14; lat <= 19.61; lat += 0.025) {
      for (double lon = -99.31; lon <= -98.84; lon += 0.025) {
        final zonaGeo = await MapService.zoneAtPoint(lat, lon);
        if (zonaGeo == null) continue; // fuera de cobertura oficial
        evaluados++;
        porZona[zonaGeo] = (porZona[zonaGeo] ?? 0) + 1;

        final site = await SeismicEngine.calculateSiteParametersWithGrid(
          lat,
          lon,
        );
        final ok = switch (zonaGeo) {
          'Zona I' => site.zone == GeotechnicalZone.zonaI,
          'Zona II' => site.zone == GeotechnicalZone.zonaII,
          _ => site.zone.name.startsWith('Zona III'),
        };
        if (!ok) {
          mismatches.add(
            '($lat,$lon) poligono=$zonaGeo motor=${site.zone.name} '
            'ts=${site.ts}',
          );
        }
      }
    }

    // ignore: avoid_print
    print('puntos evaluados: $evaluados');
    // ignore: avoid_print
    print('por zona: $porZona');
    // ignore: avoid_print
    print('discrepancias: ${mismatches.length}');
    for (final m in mismatches.take(10)) {
      // ignore: avoid_print
      print('  $m');
    }
    expect(evaluados, greaterThan(300), reason: 'malla insuficiente');
    expect(mismatches, isEmpty);
  });
}
