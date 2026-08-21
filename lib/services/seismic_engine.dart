import 'dart:math' as math;
import '../models/seismic_models.dart';

class SeismicEngine {
  /// Obtiene los parámetros del sitio (Ts, a0, c, Ta, Tb, k) interpolados
  /// a partir del modelo geotécnico continuo de la Cuenca de México.
  static SiteParameters calculateSiteParameters(double lat, double lon) {
    final clampedLat = lat.clamp(19.05, 19.65);
    final clampedLon = lon.clamp(-99.40, -98.85);

    // Eje este-oeste normalizado para la CDMX:
    // Poniente (Lon <= -99.19): Lomas firme
    // Franja de Transición: -99.19 < Lon <= -99.155 (Polanco, Mixcoac, Del Valle poniente)
    // Lago histórico: Lon > -99.155 (Centro Histórico, Roma, Cuauhtémoc, Oriente)
    double lakeIndex = ((clampedLon - (-99.20)) / 0.14).clamp(0.0, 1.0);
    
    // Ajuste por zona sur (Pedregal de San Ángel, CU, Tlalpan son lomas volcánicas)
    if (clampedLat < 19.34 && clampedLon < -99.14) {
      lakeIndex = math.max(0.0, lakeIndex - 0.45);
    }
    
    // Ajuste por Sierra de Guadalupe (norte de GAM es roca volcánica)
    if (clampedLat > 19.52 && clampedLon < -99.10) {
      lakeIndex = math.max(0.0, lakeIndex - 0.50);
    }

    // Periodo dominante del suelo Ts (s)
    double ts;
    if (lakeIndex <= 0.12) {
      // Zona de Lomas: Ts <= 0.50 s
      ts = 0.20 + (lakeIndex / 0.12) * 0.30;
    } else if (lakeIndex <= 0.28) {
      // Zona de Transición: 0.50 s < Ts <= 1.00 s
      final t = (lakeIndex - 0.12) / 0.16;
      ts = 0.50 + t * 0.50;
    } else if (lakeIndex <= 0.55) {
      // Zona de Lago IIIa / IIIb: 1.00 s < Ts <= 2.00 s
      final t = (lakeIndex - 0.28) / 0.27;
      ts = 1.00 + t * 1.00;
    } else if (lakeIndex <= 0.80) {
      // Zona de Lago IIIc: 2.00 s < Ts <= 3.00 s
      final t = (lakeIndex - 0.55) / 0.25;
      ts = 2.00 + t * 1.00;
    } else {
      // Zona de Lago IIId: Ts > 3.0 s
      final t = (lakeIndex - 0.80) / 0.20;
      ts = 3.00 + t * 1.00;
    }

    // Determinación de la Zona Geotécnica NTC
    GeotechnicalZone zone;
    if (ts <= 0.5001) {
      zone = GeotechnicalZone.zonaI;
    } else if (ts <= 1.0001) {
      zone = GeotechnicalZone.zonaII;
    } else if (ts <= 1.5001) {
      zone = GeotechnicalZone.zonaIIIa;
    } else if (ts <= 2.0001) {
      zone = GeotechnicalZone.zonaIIIb;
    } else if (ts <= 3.0001) {
      zone = GeotechnicalZone.zonaIIIc;
    } else {
      zone = GeotechnicalZone.zonaIIId;
    }

    // Parámetros sísmicos NTC CDMX (Apéndice A / NTC 2017 & 2023)
    double a0, c, ta, tb, k;

    if (ts <= 0.5) {
      a0 = 0.06;
      c = 0.18 + (ts / 0.5) * 0.04;
      ta = 0.15;
      tb = 0.60;
      k = 1.00;
    } else if (ts <= 1.0) {
      final factor = (ts - 0.5) / 0.5;
      a0 = 0.08 + factor * 0.03;
      c = 0.22 + factor * 0.23;
      ta = 0.30 + factor * 0.30;
      tb = 1.20 + factor * 0.30;
      k = 1.00 + factor * 0.35;
    } else if (ts <= 1.5) {
      final factor = (ts - 1.0) / 0.5;
      a0 = 0.11 + factor * 0.03;
      c = 0.45 + factor * 0.20;
      ta = 0.60 + factor * 0.40;
      tb = 1.50 + factor * 0.50;
      k = 1.35 + factor * 0.25;
    } else if (ts <= 2.0) {
      final factor = (ts - 1.5) / 0.5;
      a0 = 0.14 + factor * 0.02;
      c = 0.65 + factor * 0.20;
      ta = 1.00 + factor * 0.50;
      tb = 2.00 + factor * 0.50;
      k = 1.60 + factor * 0.30;
    } else if (ts <= 3.0) {
      final factor = (ts - 2.0) / 1.0;
      a0 = 0.16 + factor * 0.03;
      c = 0.85 + factor * 0.15;
      ta = 1.50 + factor * 0.70;
      tb = 2.50 + factor * 0.70;
      k = 1.90 + factor * 0.35;
    } else {
      final factor = ((ts - 3.0) / 1.0).clamp(0.0, 1.0);
      a0 = 0.19 + factor * 0.03;
      c = 1.00 + factor * 0.10;
      ta = 2.20 + factor * 0.40;
      tb = 3.20 + factor * 0.50;
      k = 2.25 + factor * 0.25;
    }

    return SiteParameters(
      latitude: lat,
      longitude: lon,
      ts: double.parse(ts.toStringAsFixed(3)),
      a0: double.parse(a0.toStringAsFixed(3)),
      c: double.parse(c.toStringAsFixed(3)),
      ta: double.parse(ta.toStringAsFixed(3)),
      tb: double.parse(tb.toStringAsFixed(3)),
      k: double.parse(k.toStringAsFixed(3)),
      zone: zone,
    );
  }

  /// Calcula el espectro completo (Elástico, Diseño, EPU y Comparativas)
  static SpectrumResult computeSpectrum({
    required SiteParameters site,
    required SeismicFactors factors,
  }) {
    double r0;
    if (factors.q >= 3.0) {
      r0 = 2.0 * factors.k1;
    } else if (factors.q >= 2.0) {
      r0 = 1.75 * factors.k1;
    } else if (factors.q >= 1.5) {
      r0 = 1.50 * factors.k1;
    } else {
      r0 = 1.00;
    }

    final double iFactor = factors.importanceGroup.factor;
    final double alpha = factors.irregularity.factor;
    final double qFactor = factors.q;

    final List<SpectrumPoint> elasticSpectrum = [];
    final List<SpectrumPoint> designSpectrum = [];
    final List<SpectrumPoint> epuSpectrum = [];

    const double maxT = 5.0;
    const double dt = 0.02;
    final int steps = (maxT / dt).round();

    double aMaxDesign = 0.0;

    for (int step = 0; step <= steps; step++) {
      final double t = double.parse((step * dt).toStringAsFixed(3));

      double ae;
      if (t < site.ta) {
        ae = site.a0 + (site.c - site.a0) * (t / site.ta);
      } else if (t <= site.tb) {
        ae = site.c;
      } else {
        ae = site.c * math.pow(site.tb / t, site.k);
      }
      elasticSpectrum.add(SpectrumPoint(period: t, acceleration: ae));

      double qPrime;
      double rPrime;

      if (t < site.ta) {
        qPrime = 1.0 + (qFactor - 1.0) * (t / site.ta);
        rPrime = 1.0 + (r0 - 1.0) * (t / site.ta);
      } else {
        qPrime = qFactor;
        rPrime = r0;
      }

      double ad = (iFactor * ae) / (qPrime * rPrime * alpha);
      final double aMin = (site.a0 * iFactor) / (2.0 * r0 * alpha);
      if (ad < aMin) ad = aMin;

      if (ad > aMaxDesign) aMaxDesign = ad;
      designSpectrum.add(SpectrumPoint(period: t, acceleration: ad));

      final double aEpu = iFactor * ae * 1.10;
      epuSpectrum.add(SpectrumPoint(period: t, acceleration: aEpu));
    }

    List<SpectrumPoint>? ntc2004Main;
    List<SpectrumPoint>? ntc2004ApA;
    Map<double, List<SpectrumPoint>>? qComparisons;

    if (factors.showComparison2004) {
      ntc2004Main = _computeNtc2004Main(site, factors);
      ntc2004ApA = _computeNtc2004ApendiceA(site, factors);

      qComparisons = {};
      for (final qVal in [1.5, 2.0, 3.0, 4.0]) {
        qComparisons[qVal] = _computeDesignForQ(site, factors, qVal);
      }
    }

    return SpectrumResult(
      site: site,
      factors: factors,
      r0: double.parse(r0.toStringAsFixed(3)),
      aMaxDesign: double.parse(aMaxDesign.toStringAsFixed(4)),
      elasticSpectrum: elasticSpectrum,
      designSpectrum: designSpectrum,
      epuSpectrum: epuSpectrum,
      ntc2004MainSpectrum: ntc2004Main,
      ntc2004ApendiceASpectrum: ntc2004ApA,
      qComparisons: qComparisons,
    );
  }

  static List<SpectrumPoint> _computeDesignForQ(SiteParameters site, SeismicFactors factors, double targetQ) {
    double r0;
    if (targetQ >= 3.0) {
      r0 = 2.0 * factors.k1;
    } else if (targetQ >= 2.0) {
      r0 = 1.75 * factors.k1;
    } else if (targetQ >= 1.5) {
      r0 = 1.50 * factors.k1;
    } else {
      r0 = 1.00;
    }

    final double iFactor = factors.importanceGroup.factor;
    final double alpha = factors.irregularity.factor;
    final List<SpectrumPoint> points = [];

    const double maxT = 5.0;
    const double dt = 0.02;
    final int steps = (maxT / dt).round();

    for (int step = 0; step <= steps; step++) {
      final double t = double.parse((step * dt).toStringAsFixed(3));
      double ae;
      if (t < site.ta) {
        ae = site.a0 + (site.c - site.a0) * (t / site.ta);
      } else if (t <= site.tb) {
        ae = site.c;
      } else {
        ae = site.c * math.pow(site.tb / t, site.k);
      }

      double qPrime = t < site.ta ? 1.0 + (targetQ - 1.0) * (t / site.ta) : targetQ;
      double rPrime = t < site.ta ? 1.0 + (r0 - 1.0) * (t / site.ta) : r0;

      double ad = (iFactor * ae) / (qPrime * rPrime * alpha);
      final double aMin = (site.a0 * iFactor) / (2.0 * r0 * alpha);
      if (ad < aMin) ad = aMin;

      points.add(SpectrumPoint(period: t, acceleration: ad));
    }
    return points;
  }

  static List<SpectrumPoint> _computeNtc2004Main(SiteParameters site, SeismicFactors factors) {
    double c04, a004, ta04, tb04, rExp;
    if (site.zone == GeotechnicalZone.zonaI) {
      c04 = 0.16;
      a004 = 0.04;
      ta04 = 0.20;
      tb04 = 0.60;
      rExp = 0.5;
    } else if (site.zone == GeotechnicalZone.zonaII) {
      c04 = 0.32;
      a004 = 0.08;
      ta04 = 0.30;
      tb04 = 1.50;
      rExp = 0.67;
    } else {
      c04 = 0.45;
      a004 = 0.10;
      ta04 = 0.60;
      tb04 = 2.50;
      rExp = 1.0;
    }

    final double qFactor = factors.q;
    final List<SpectrumPoint> points = [];

    const double maxT = 5.0;
    const double dt = 0.02;
    final int steps = (maxT / dt).round();

    for (int step = 0; step <= steps; step++) {
      final double t = double.parse((step * dt).toStringAsFixed(3));
      double a;
      if (t < ta04) {
        a = a004 + (c04 - a004) * (t / ta04);
      } else if (t <= tb04) {
        a = c04;
      } else {
        a = c04 * math.pow(tb04 / t, rExp);
      }

      double qPrime = t < ta04 ? 1.0 + (qFactor - 1.0) * (t / ta04) : qFactor;
      double ad = a / qPrime;
      points.add(SpectrumPoint(period: t, acceleration: ad));
    }
    return points;
  }

  static List<SpectrumPoint> _computeNtc2004ApendiceA(SiteParameters site, SeismicFactors factors) {
    final double ts = site.ts;
    final double ta = ts <= 0.5 ? 0.2 : ts * 0.3;
    final double tb = ts <= 0.5 ? 0.6 : ts * 1.2;
    final double c = ts <= 0.5 ? 0.18 : (0.2 + ts * 0.18).clamp(0.2, 0.65);
    final double a0 = c * 0.3;

    final double qFactor = factors.q;
    final List<SpectrumPoint> points = [];

    const double maxT = 5.0;
    const double dt = 0.02;
    final int steps = (maxT / dt).round();

    for (int step = 0; step <= steps; step++) {
      final double t = double.parse((step * dt).toStringAsFixed(3));
      double a;
      if (t < ta) {
        a = a0 + (c - a0) * (t / ta);
      } else if (t <= tb) {
        a = c;
      } else {
        a = c * math.pow(tb / t, 1.0);
      }

      double qPrime = t < ta ? 1.0 + (qFactor - 1.0) * (t / ta) : qFactor;
      double ad = a / qPrime;
      points.add(SpectrumPoint(period: t, acceleration: ad));
    }
    return points;
  }
}
