import 'package:flutter_test/flutter_test.dart';
import 'package:sasid_app/models/seismic_models.dart';
import 'package:sasid_app/services/map_service.dart';
import 'package:sasid_app/services/seismic_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Zonificación geotécnica oficial (GeoJSON NTC-2017)', () {
    test('zoneAtPoint clasifica puntos conocidos de CDMX', () async {
      // Peñón de los Baños: isla rocosa dentro del lago (encclave Zona I).
      expect(await MapService.zoneAtPoint(19.440027, -99.08309), 'Zona I');
      // Santa Fe: lomas poniente.
      expect(await MapService.zoneAtPoint(19.36, -99.26), 'Zona I');
      // Zócalo: lago profundo.
      expect(await MapService.zoneAtPoint(19.432608, -99.133208), 'Zona III');
      // Del Valle: transición.
      expect(await MapService.zoneAtPoint(19.387, -99.162), 'Zona II');
    });

    test('Peñón de los Baños: geometría manda sobre el grid ERN', () async {
      // El grid ES_DF da Ts~3.7s (lago) en el Peñón, pero la zonificación
      // oficial es Zona I: deben usarse parámetros de tabla firme.
      final site = await SeismicEngine.calculateSiteParametersWithGrid(
        19.440027,
        -99.08309,
      );
      expect(site.zone, GeotechnicalZone.zonaI);
      expect(site.ts, lessThanOrEqualTo(0.5));
      expect(site.a0, 0.06);
      expect(site.c, inInclusiveRange(0.18, 0.22));
      expect(site.ta, 0.20);
      expect(site.tb, 0.60);
    });

    test('Zócalo: calibración SASID intacta (Ts=1.335 → IIIa)', () async {
      final site = await SeismicEngine.calculateSiteParametersWithGrid(
        19.391944,
        -99.158257,
      );
      expect(site.zone, GeotechnicalZone.zonaIIIa);
      expect(site.ts, closeTo(1.335, 0.002));
      expect(site.c, closeTo(0.947, 0.001));
    });

    test('Del Valle (transición): parámetros acotados a rango II', () async {
      final site = await SeismicEngine.calculateSiteParametersWithGrid(
        19.387,
        -99.162,
      );
      expect(site.zone, GeotechnicalZone.zonaII);
      expect(site.ts, lessThanOrEqualTo(1.0));
      expect(site.a0, inInclusiveRange(0.08, 0.12));
      expect(site.c, inInclusiveRange(0.22, 0.45));
    });

    test('Aeropuerto (lago oriente): modelo continuo sin cambios', () async {
      final site = await SeismicEngine.calculateSiteParametersWithGrid(
        19.436,
        -99.072,
      );
      // Lago profundo: cualquier subzona III*, parámetros del grid ERN.
      expect(site.zone.name, startsWith('Zona III'));
      expect(site.ts, greaterThan(2.5));
    });

    test('Tláhuac: polígono dice lago aunque el grid dé Ts<1.0', () async {
      // El grid ERN da Ts=0.485s ahí (artefacto junto a Sierra Santa
      // Catarina); la geometría oficial es Zona III -> se acota al piso
      // del lago y la subzona mínima es IIIa.
      final site = await SeismicEngine.calculateSiteParametersWithGrid(
        19.275426,
        -99.018161,
      );
      expect(site.zone.name, startsWith('Zona III'));
      expect(site.ts, inInclusiveRange(1.0, 1.5));
      expect(site.a0, greaterThan(0.10));
    });
  });
}
