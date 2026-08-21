import 'package:flutter_test/flutter_test.dart';
import 'package:sasid_app/models/seismic_models.dart';
import 'package:sasid_app/services/seismic_engine.dart';
import 'package:sasid_app/services/export_service.dart';

void main() {
  group('SeismicEngine Unit Tests', () {
    test('Calculate Lomas Zone (Santa Fe / CU)', () {
      final site = SeismicEngine.calculateSiteParameters(19.332822, -99.186638);
      expect(site.zone, equals(GeotechnicalZone.zonaI));
      expect(site.ts, lessThanOrEqualTo(0.5));
      expect(site.a0, greaterThan(0.0));
      expect(site.c, greaterThan(site.a0));
      expect(site.ta, lessThan(site.tb));
    });

    test('Calculate Lake Zone (Zócalo)', () {
      final site = SeismicEngine.calculateSiteParameters(19.432608, -99.133208);
      expect(site.ts, greaterThan(1.0));
      expect(site.c, greaterThan(0.40));
    });

    test('Compute Spectrum curves and inelastic reduction', () {
      final site = SeismicEngine.calculateSiteParameters(19.432608, -99.133208);
      const factors = SeismicFactors(
        importanceGroup: ImportanceGroup.grupoB,
        q: 2.0,
        irregularity: IrregularityFactor.regular,
        k1: 1.0,
        showEpu: true,
        showComparison2004: true,
      );

      final result = SeismicEngine.computeSpectrum(site: site, factors: factors);

      expect(result.elasticSpectrum.isNotEmpty, isTrue);
      expect(result.designSpectrum.isNotEmpty, isTrue);
      expect(result.epuSpectrum.isNotEmpty, isTrue);
      expect(result.ntc2004MainSpectrum, isNotNull);
      expect(result.qComparisons, isNotNull);

      // El espectro elástico debe ser mayor o igual al de diseño (reducido por Q y R)
      for (int i = 0; i < result.designSpectrum.length; i++) {
        expect(result.elasticSpectrum[i].acceleration, greaterThanOrEqualTo(result.designSpectrum[i].acceleration));
      }

      // Verificación de aceleración máxima
      expect(result.aMaxDesign, greaterThan(0.0));
    });

    test('Export Service generates valid SAP2000 and CSV strings', () {
      final site = SeismicEngine.calculateSiteParameters(19.432608, -99.133208);
      const factors = SeismicFactors();
      final result = SeismicEngine.computeSpectrum(site: site, factors: factors);

      final sapTxt = ExportService.generateSap2000Txt(result, projectName: 'Test Project');
      expect(sapTxt.contains(r'$ ESPECTRO DE DISEÑO SÍSMICO'), isTrue);
      expect(sapTxt.contains('Test Project'), isTrue);
      expect(sapTxt.contains('\t'), isTrue);

      final csv = ExportService.generateCsv(result, projectName: 'Test Project');
      expect(csv.contains('"Periodo T (s)"'), isTrue);
      expect(csv.contains('"Zona Geotécnica"'), isTrue);
    });
  });
}
