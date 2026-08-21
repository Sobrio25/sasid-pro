import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sasid_app/models/seismic_models.dart';
import 'package:sasid_app/models/epoch.dart';
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
        norm: NormVersion.ntc2017,
      );

      final result = SeismicEngine.computeSpectrum(
        site: site,
        factors: factors,
      );

      expect(result.elasticSpectrum.isNotEmpty, isTrue);
      expect(result.designSpectrum.isNotEmpty, isTrue);
      expect(result.epuSpectrum.isNotEmpty, isTrue);
      expect(result.ntc2004MainSpectrum, isNotNull);
      expect(result.qComparisons, isNotNull);

      // El espectro elástico debe ser mayor o igual al de diseño (reducido por Q y R)
      for (int i = 0; i < result.designSpectrum.length; i++) {
        expect(
          result.elasticSpectrum[i].acceleration,
          greaterThanOrEqualTo(result.designSpectrum[i].acceleration),
        );
      }

      // Verificación de aceleración máxima
      expect(result.aMaxDesign, greaterThan(0.0));
    });

    test('Export Service generates valid SAP2000 and CSV strings', () {
      final site = SeismicEngine.calculateSiteParameters(19.432608, -99.133208);
      const factors = SeismicFactors();
      final result = SeismicEngine.computeSpectrum(
        site: site,
        factors: factors,
      );

      final sapTxt = ExportService.generateSap2000Txt(
        result,
        projectName: 'Test Project',
      );
      expect(sapTxt.contains(r'$ ESPECTRO DE DISEÑO SÍSMICO'), isTrue);
      expect(sapTxt.contains('Test Project'), isTrue);
      expect(sapTxt.contains('\t'), isTrue);

      final csv = ExportService.generateCsv(
        result,
        projectName: 'Test Project',
      );
      expect(csv.contains('"Periodo T (s)"'), isTrue);
      expect(csv.contains('"Zona Geotécnica"'), isTrue);
    });

    test('Modelo 2016 replica tabla exacta de SASID A v3.3', () {
      // Caso calibrado: Ts=1.335 -> a0=0.301, c=0.947, Ta=1.080, Tb=1.719, k=0.560
      final p = SeismicEngine.params2016ForTs(1.335);
      expect(p.a0, closeTo(0.301, 0.001));
      expect(p.c, closeTo(0.947, 0.001));
      expect(p.ta, closeTo(1.080, 0.002));
      expect(p.tb, closeTo(1.719, 0.002));
      expect(p.k, closeTo(0.560, 0.001));

      // Segundo punto calibrado: Ts=2.288 -> a0=0.330, c=0.952, Ta=1.806, Tb=2.650
      final p2 = SeismicEngine.params2016ForTs(2.288);
      expect(p2.a0, closeTo(0.330, 0.001));
      expect(p2.c, closeTo(0.952, 0.001));
      expect(p2.ta, closeTo(1.806, 0.002));
      expect(p2.tb, closeTo(2.650, 0.005));

      // Espectro de diseño 2016 con Q=1, I=B, α=1:
      // ad(T) = ae(T) / X(T), X(T)=R0+0.5·(1−√(T/Ta)), R0=1.75
      const factors = SeismicFactors(
        importanceGroup: ImportanceGroup.grupoB,
        q: 1.0,
        norm: NormVersion.ntc2016,
      );
      final result = SeismicEngine.computeSpectrum(site: p, factors: factors);

      double designAt(double t) {
        final idx = (t / 0.02).round();
        return result.designSpectrum[idx].acceleration;
      }

      expect(designAt(0.0), closeTo(0.134, 0.002));
      expect(designAt(0.1), closeTo(0.172, 0.002));
      expect(designAt(0.2), closeTo(0.207, 0.002));
      expect(designAt(0.3), closeTo(0.242, 0.002));
      expect(designAt(0.5), closeTo(0.314, 0.002));
      expect(designAt(1.0), closeTo(0.509, 0.003));
      // Meseta: amax = c/R0
      expect(result.aMaxDesign, closeTo(0.541, 0.003));
      expect(result.r0, equals(1.75));
    });

    test('NTC 2023: exponente p(T) es continuo y p(Tb)=k (ec. 3.1.2b)', () {
      const k = 0.56;
      const tb = 1.719;
      // En T = Tb, p debe ser exactamente k.
      expect(SeismicEngine.pExponent2023(k, tb, tb), closeTo(k, 1e-12));
      // Justo antes de Tb también es k (rama de meseta).
      expect(SeismicEngine.pExponent2023(k, tb, tb - 0.01), k);
      // Después de Tb, p decrece monótonamente desde 1 hacia k (si k<1).
      double prev = SeismicEngine.pExponent2023(k, tb, tb + 0.01);
      expect(prev, lessThanOrEqualTo(1.0));
      for (double t = tb + 0.11; t <= 5.0; t += 0.1) {
        final curr = SeismicEngine.pExponent2023(k, tb, t);
        expect(curr, lessThan(prev));
        expect(curr, greaterThanOrEqualTo(k));
        prev = curr;
      }
    });

    test('NTC 2023: Q\'(T) con fórmulas raíz del numeral 3.2.1', () {
      const q = 2.0;
      const k = 0.56;
      const ta = 1.08;
      const tb = 1.719;
      // En T=0: Q' = 1
      expect(
        SeismicEngine.qPrime2023(q: q, k: k, ta_: ta, tb_: tb, t: 0.0),
        1.0,
      );
      // En T = Ta: Q' = 1 + (Q−1)·√(1/k)
      final qpTa = SeismicEngine.qPrime2023(
        q: q,
        k: k,
        ta_: ta,
        tb_: tb,
        t: ta,
      );
      expect(qpTa, closeTo(1 + (q - 1) * math.sqrt(1 / k), 1e-9));
      // En meseta se mantiene constante
      final qpMeseta = SeismicEngine.qPrime2023(
        q: q,
        k: k,
        ta_: ta,
        tb_: tb,
        t: (ta + tb) / 2,
      );
      expect(qpMeseta, closeTo(qpTa, 1e-9));
      // Q=1 => Q'=1 en todo T
      expect(
        SeismicEngine.qPrime2023(q: 1.0, k: k, ta_: ta, tb_: tb, t: 3.0),
        1.0,
      );
    });

    test('NTC 2023: R = k1·R0 + k2 con k2=0 para T ≥ Ta (ec. 3.3.1)', () {
      // Q >= 3 -> R0 = 2.0; si no 1.75
      expect(
        SeismicEngine.rTotal2023(q: 4.0, k1: 1.25, ta_: 1.08, t: 1.08),
        closeTo(2.5, 1e-9),
      );
      expect(
        SeismicEngine.rTotal2023(q: 2.0, k1: 1.0, ta_: 1.08, t: 1.08),
        closeTo(1.75, 1e-9),
      );
      // k2 > 0 solo para T < Ta: en T=0, k2=0.5
      expect(
        SeismicEngine.rTotal2023(q: 2.0, k1: 1.0, ta_: 1.08, t: 0.0),
        closeTo(1.75 + 0.5, 1e-9),
      );
      // En T ≥ Ta, k2 = 0
      expect(
        SeismicEngine.rTotal2023(q: 2.0, k1: 1.0, ta_: 1.08, t: 2.0),
        closeTo(1.75, 1e-9),
      );
    });

    test('NTC 2023: espectro completo Q=2, I=B, Seguridad de Vida', () {
      final site = SeismicEngine.params2016ForTs(1.335);
      const factors = SeismicFactors(
        importanceGroup: ImportanceGroup.grupoB,
        q: 2.0,
        norm: NormVersion.ntc2023,
        performanceLevel: PerformanceLevel.seguridadVida,
      );
      final result = SeismicEngine.computeSpectrum(
        site: site,
        factors: factors,
      );

      // Verificación manual en T = Tb (meseta): ae=c, p=k, Q'=1+(Q-1)/√k,
      // R = k1·R0 + k2 = 1·1.75 + 0 (k2=0 pues T≥Ta)
      final c = site.c; // 0.947
      final qpMeseta = 1 + math.sqrt(1 / site.k);
      final adEsperada = c / (qpMeseta * factors.k1 * 1.75);
      double designAt(double t) =>
          result.designSpectrum[(t / 0.02).round()].acceleration;
      double elasticAt(double t) =>
          result.elasticSpectrum[(t / 0.02).round()].acceleration;

      expect(designAt(site.tb), closeTo(adEsperada, 0.005));
      // Elástico usa p=k exacto en Tb: ae(Tb) = c·(Tb/Tb)^k = c
      expect(elasticAt(site.tb), closeTo(c, 0.001));
      // Elástico descendente con p variable: ae(T>Tb) > c·(Tb/T)^k cuando k<1
      final tFar = 4.0;
      final pFar = SeismicEngine.pExponent2023(site.k, site.tb, tFar);
      expect(pFar, greaterThan(site.k)); // k=0.56 < 1 → p>k
      // Ocupación Inmediata fuerza Q=1 y R'=0.75R → diseño mayor que SV
      const factorsOI = SeismicFactors(
        importanceGroup: ImportanceGroup.grupoB,
        q: 2.0,
        norm: NormVersion.ntc2023,
        performanceLevel: PerformanceLevel.ocupacionInmediata,
      );
      final resultOI = SeismicEngine.computeSpectrum(
        site: site,
        factors: factorsOI,
      );
      expect(
        resultOI.designSpectrum[50].acceleration,
        greaterThan(result.designSpectrum[50].acceleration),
      );
    });
  });
}
