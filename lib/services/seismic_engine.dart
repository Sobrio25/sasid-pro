import 'dart:math' as math;
import '../models/epoch.dart';
import '../models/seismic_models.dart';
import 'grd_service.dart';

/// Motor de cálculo de espectros NTC-CDMX.
///
/// Modo 2016 (SASID A v3.3): parámetros del sitio interpolados desde las
/// mallas `ES_DF{época}.grd` (Ts) y tablas continuas del lago; el espectro de
/// diseño reduce el elástico con X(T) = R0 + 0.5·(1 − √(T/Ta)), R0 = 1.75.
///
/// Modo 2017/2023: tablas normativas por zona y reducción Q'(T)·R(T)·α.
class SeismicEngine {
  /// Puntos de calibración del modelo continuo 2016 (lago profundo),
  /// extraídos de SASID A v3.3: (Ts, a0, c, Ta/Ts, Tb/Ts, k).
  static const List<List<double>> _calib2016 = [
    // [Ts, a0, c, taRatio, tbRatio, k]
    [1.335, 0.301, 0.947, 0.809, 1.288, 0.560],
    [2.288, 0.330, 0.952, 0.789, 1.158, 0.560],
  ];

  /// Parámetros del sitio modo 2016, interpolando la tabla continua del lago.
  static SiteParameters params2016ForTs(
    double ts, {
    Epoch epoch = Epoch.y2010,
  }) {
    final lo = _calib2016.first;
    final hi = _calib2016.last;
    final t = ((ts - lo[0]) / (hi[0] - lo[0])).clamp(0.0, 1.0);
    double a0 = lo[1] + t * (hi[1] - lo[1]);
    double c = lo[2] + t * (hi[2] - lo[2]);
    double taRatio = lo[3] + t * (hi[3] - lo[3]);
    double tbRatio = lo[4] + t * (hi[4] - lo[4]);
    double k = lo[5] + t * (hi[5] - lo[5]);
    double ta = taRatio * ts;
    double tb = tbRatio * ts;

    if (ts <= 1.0) {
      // Zona II / transición temprana: proporciones NTC clásicas
      final f = ((ts - 0.5) / 0.5).clamp(0.0, 1.0);
      a0 = 0.08 + f * 0.04;
      c = 0.22 + f * 0.23;
      taRatio = 0.20 + f * 0.40;
      tbRatio = 0.60 + f * 0.69;
      ta = taRatio * ts;
      tb = tbRatio * ts;
      k = 1.00 - f * 0.44;
    }

    return SiteParameters(
      latitude: 0,
      longitude: 0,
      ts: double.parse(ts.toStringAsFixed(3)),
      a0: double.parse(a0.toStringAsFixed(3)),
      c: double.parse(c.toStringAsFixed(3)),
      ta: double.parse(ta.toStringAsFixed(3)),
      tb: double.parse(tb.toStringAsFixed(3)),
      k: double.parse(k.toStringAsFixed(3)),
      zone: _zoneForTs(ts),
    );
  }

  static GeotechnicalZone _zoneForTs(double ts) {
    if (ts <= 0.5001) return GeotechnicalZone.zonaI;
    if (ts <= 1.0001) return GeotechnicalZone.zonaII;
    if (ts <= 1.5001) return GeotechnicalZone.zonaIIIa;
    if (ts <= 2.0001) return GeotechnicalZone.zonaIIIb;
    if (ts <= 3.0001) return GeotechnicalZone.zonaIIIc;
    return GeotechnicalZone.zonaIIId;
  }

  /// Cálculo con mallas reales: Ts desde ES_DF{época}.grd (DSAA ASCII).
  static Future<SiteParameters> calculateSiteParametersWithGrid(
    double lat,
    double lon, {
    Epoch epoch = Epoch.y2010,
    NormVersion norm = NormVersion.ntc2016,
  }) async {
    final tsGrid = await GrdService.interpolateTs(lat, lon, epoch.assetPath);
    if (norm == NormVersion.ntc2016 || norm == NormVersion.ntc2023) {
      // Ambas normas usan parámetros continuos provistos por SASID
      // interpolados de la malla ES_DF{época} (numeral 3.1.2 NTC-2023).
      final ts = tsGrid ?? _fallbackTs(lat, lon);
      final p = params2016ForTs(ts, epoch: epoch);
      return SiteParameters(
        latitude: lat,
        longitude: lon,
        ts: p.ts,
        a0: p.a0,
        c: p.c,
        ta: p.ta,
        tb: p.tb,
        k: p.k,
        zone: p.zone,
        epoch: epoch,
        activeMallaHex: epoch.hexCode,
      );
    }
    final base = calculateSiteParameters(lat, lon, epoch: epoch);
    return base;
  }

  /// Fallback sin grid: aproximación este-oeste (offline).
  static double _fallbackTs(double lat, double lon) {
    double lakeIndex = ((lon + 99.205) / 0.11).clamp(0.0, 1.0);
    if (lakeIndex <= 0.12) return 0.20 + (lakeIndex / 0.12) * 0.30;
    if (lakeIndex <= 0.28) return 0.50 + ((lakeIndex - 0.12) / 0.16) * 0.50;
    if (lakeIndex <= 0.55) return 1.00 + ((lakeIndex - 0.28) / 0.27) * 1.00;
    if (lakeIndex <= 0.80) return 2.00 + ((lakeIndex - 0.55) / 0.25) * 1.00;
    return 3.00 + ((lakeIndex - 0.80) / 0.20).clamp(0.0, 1.0);
  }

  /// Cálculo sincrónico legacy (tablas 2017/2023 por zona).
  static SiteParameters calculateSiteParameters(
    double lat,
    double lon, {
    Epoch epoch = Epoch.y2010,
  }) {
    final clampedLat = lat.clamp(19.05, 19.65);
    final clampedLon = lon.clamp(-99.40, -98.85);

    double lakeIndex = ((clampedLon - (-99.205)) / 0.11).clamp(0.0, 1.0);

    if (clampedLat < 19.34 && clampedLon < -99.14) {
      lakeIndex = math.max(0.0, lakeIndex - 0.45);
    }
    if (clampedLat > 19.52 && clampedLon < -99.10) {
      lakeIndex = math.max(0.0, lakeIndex - 0.50);
    }

    double ts;
    if (lakeIndex <= 0.12) {
      ts = 0.20 + (lakeIndex / 0.12) * 0.30;
    } else if (lakeIndex <= 0.28) {
      final t = (lakeIndex - 0.12) / 0.16;
      ts = 0.50 + t * 0.50;
    } else if (lakeIndex <= 0.55) {
      final t = (lakeIndex - 0.28) / 0.27;
      ts = 1.00 + t * 1.00;
    } else if (lakeIndex <= 0.80) {
      final t = (lakeIndex - 0.55) / 0.25;
      ts = 2.00 + t * 1.00;
    } else {
      final t = (lakeIndex - 0.80) / 0.20;
      ts = 3.00 + t * 1.00;
    }
    ts = ts.clamp(0.2, 4.0);

    final zone = _zoneForTs(ts);

    double a0, c, ta, tb, k;
    if (ts <= 0.5) {
      a0 = 0.06;
      c = 0.18 + (ts / 0.5) * 0.04;
      ta = 0.20;
      tb = 0.60;
      k = 1.00;
    } else if (ts <= 1.0) {
      final factor = (ts - 0.5) / 0.5;
      a0 = 0.08 + factor * 0.04;
      c = 0.22 + factor * 0.23;
      ta = 0.20 + factor * 0.40;
      tb = 0.60 + factor * 0.90;
      k = 1.00 - factor * 0.20;
    } else if (ts <= 1.5) {
      final factor = (ts - 1.0) / 0.5;
      a0 = 0.12 + factor * 0.06;
      c = 0.45 + factor * 0.18;
      ta = 0.60 + factor * 0.35;
      tb = 1.50 + factor * 0.30;
      k = 0.80 - factor * 0.15;
    } else if (ts <= 2.0) {
      final factor = (ts - 1.5) / 0.5;
      a0 = 0.18 + factor * 0.08;
      c = 0.63 + factor * 0.17;
      ta = 0.95 + factor * 0.35;
      tb = 1.80 + factor * 0.40;
      k = 0.65 - factor * 0.05;
    } else if (ts <= 3.0) {
      final factor = (ts - 2.0) / 1.0;
      a0 = 0.26 + factor * 0.08;
      c = 0.80 + factor * 0.20;
      ta = 1.30 + factor * 0.80;
      tb = 2.20 + factor * 0.70;
      k = 0.60 - factor * 0.05;
    } else {
      final factor = ((ts - 3.0) / 1.0).clamp(0.0, 1.0);
      a0 = 0.34 + factor * 0.04;
      c = 1.00 + factor * 0.12;
      ta = 2.10 + factor * 0.50;
      tb = 2.90 + factor * 0.60;
      k = 0.55 + factor * 0.10;
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
      epoch: epoch,
      activeMallaHex: epoch.hexCode,
    );
  }

  /// Calcula el espectro completo (Elástico, Diseño, EPU y Comparativas).
  static SpectrumResult computeSpectrum({
    required SiteParameters site,
    required SeismicFactors factors,
  }) {
    switch (factors.norm) {
      case NormVersion.ntc2016:
        return _computeSpectrum2016(site: site, factors: factors);
      case NormVersion.ntc2017:
        return _computeSpectrum2017(site: site, factors: factors);
      case NormVersion.ntc2023:
        return _computeSpectrum2023(site: site, factors: factors);
    }
  }

  // ------------------------------------------------------------------
  // MODO 2023 (NTC-Sismo 2023, numerales 3.1.2, 3.2 y 3.3)
  // ------------------------------------------------------------------

  /// Exponente variable de la rama descendente (ecuación 3.1.2b):
  /// p = k + (1 − k)·(Tb/T). En T = Tb devuelve exactamente k.
  static double pExponentNorm(double k, double tb, double t) {
    if (t <= tb || t <= 0) return k;
    return k + (1 - k) * (tb / t);
  }

  /// Factor de comportamiento sísmico reducido Q'(T), ecuación 3.2.1:
  /// T ≤ Ta:   Q' = 1 + (Q−1)·√((T/Ta)/k)
  /// Ta<T≤Tb:  Q' = 1 + (Q−1)·√(1/k)
  /// T > Tb:   Q' = 1 + (Q−1)·√(p/k)
  static double qPrimeNorm({
    required double q,
    required double k,
    required double ta_,
    required double tb_,
    required double t,
  }) {
    if (q <= 1.0) return 1.0;
    if (k <= 0) return q;
    if (t <= ta_) {
      return 1.0 + (q - 1.0) * math.sqrt((t / ta_) / k);
    }
    double p = 1.0;
    if (t > tb_) {
      p = pExponentNorm(k, tb_, t);
    }
    final ratio = t <= tb_ ? 1.0 / k : p / k;
    return 1.0 + (q - 1.0) * math.sqrt(ratio);
  }

  /// Sobrerresistencia total R(T) = k1·R0 + k2 (ecuación 3.3.1a),
  /// con k2 = 0.5·[1 − T/Ta] > 0 (ecuación 3.3.1b).
  /// R0 = 2.0 para Q ≥ 3; 1.75 en otro caso.
  static double rTotalNorm({
    required double q,
    required double k1,
    required double ta_,
    required double t,
  }) {
    final r0base = q >= 3.0 ? 2.0 : 1.75;
    double k2 = 0.5 * (1 - t / ta_);
    if (k2 < 0) k2 = 0;
    return k1 * r0base + k2;
  }

  static SpectrumResult _computeSpectrum2023({
    required SiteParameters site,
    required SeismicFactors factors,
  }) {
    final iFactor = factors.importanceGroup.factor;

    // NTC 2023, numeral 3.2: para Ocupación Inmediata se considera Q = 1.
    final qNorm =
        factors.performanceLevel == PerformanceLevel.ocupacionInmediata
        ? 1.0
        : factors.q;

    const double maxT = 5.0;
    const double dt = 0.02;
    final int steps = (maxT / dt).round();

    final elastic = <SpectrumPoint>[];
    final design = <SpectrumPoint>[];
    final epu = <SpectrumPoint>[];
    double aMaxDesign = 0.0;

    for (int step = 0; step <= steps; step++) {
      final t = double.parse((step * dt).toStringAsFixed(3));

      // Espectro elástico (ecuación 3.1.2a) con exponente variable p (3.1.2b).
      double ae;
      if (t < site.ta) {
        ae = site.a0 + (site.c - site.a0) * (t / site.ta);
      } else if (t <= site.tb) {
        ae = site.c;
      } else {
        final p = pExponentNorm(site.k, site.tb, t);
        ae = site.c * math.pow(site.tb / t, p);
      }
      elastic.add(SpectrumPoint(period: t, acceleration: ae));

      // Reducción: ad = I · ae / (Q' · R') — sin factor α en 2023.
      final qp = qPrimeNorm(
        q: qNorm,
        k: site.k,
        ta_: site.ta,
        tb_: site.tb,
        t: t,
      );
      final rTotal = rTotalNorm(q: qNorm, k1: factors.k1, ta_: site.ta, t: t);
      final rPrime = rTotal * factors.performanceLevel.rFactor;

      double ad = (iFactor * ae) / (qp * rPrime);
      final double aMin =
          (site.a0 * iFactor) /
          (2.0 *
              rTotalNorm(q: qNorm, k1: factors.k1, ta_: site.ta, t: site.ta));
      if (ad < aMin) ad = aMin;

      if (ad > aMaxDesign) aMaxDesign = ad;
      design.add(SpectrumPoint(period: t, acceleration: ad));

      final trF = _trFactor(factors.returnPeriod);
      epu.add(
        SpectrumPoint(period: t, acceleration: iFactor * ae * 1.10 * trF),
      );
    }

    return SpectrumResult(
      site: site,
      factors: factors,
      r0: double.parse(
        (factors.k1 * (qNorm >= 3.0 ? 2.0 : 1.75)).toStringAsFixed(3),
      ),
      aMaxDesign: double.parse(aMaxDesign.toStringAsFixed(4)),
      elasticSpectrum: elastic,
      designSpectrum: design,
      epuSpectrum: epu,
    );
  }

  // ------------------------------------------------------------------
  // MODO 2016 (SASID A v3.3)
  // ------------------------------------------------------------------
  static SpectrumResult _computeSpectrum2016({
    required SiteParameters site,
    required SeismicFactors factors,
  }) {
    const double r0 = 1.75; // sobrerresistencia fija 2016
    final iFactor = factors.importanceGroup.factor;

    const double maxT = 5.0;
    const double dt = 0.02;
    final int steps = (maxT / dt).round();

    final elastic = <SpectrumPoint>[];
    final design = <SpectrumPoint>[];
    final epu = <SpectrumPoint>[];
    double aMaxDesign = 0.0;

    for (int step = 0; step <= steps; step++) {
      final t = double.parse((step * dt).toStringAsFixed(3));

      double ae;
      if (t < site.ta) {
        ae = site.a0 + (site.c - site.a0) * (t / site.ta);
      } else if (t <= site.tb) {
        ae = site.c;
      } else {
        ae = site.c * math.pow(site.tb / t, site.k);
      }
      elastic.add(SpectrumPoint(period: t, acceleration: ae));

      // Reducción 2016: X(T) = R0 + 0.5·(1 − √(T/Ta)) en rama ascendente,
      // R0 puro en meseta y descendente.
      double xFactor = r0;
      if (t < site.ta && site.ta > 0) {
        xFactor = r0 + 0.5 * (1 - math.sqrt(t / site.ta));
      }

      double ad = ae / xFactor;
      final double aMin = site.a0 / (2.0 * r0);
      if (ad < aMin) ad = aMin;

      if (ad > aMaxDesign) aMaxDesign = ad;
      design.add(SpectrumPoint(period: t, acceleration: ad));

      final trF = _trFactor(factors.returnPeriod);
      epu.add(
        SpectrumPoint(period: t, acceleration: iFactor * ae * 1.10 * trF),
      );
    }

    return SpectrumResult(
      site: site,
      factors: factors,
      r0: r0,
      aMaxDesign: double.parse(aMaxDesign.toStringAsFixed(4)),
      elasticSpectrum: elastic,
      designSpectrum: design,
      epuSpectrum: epu,
    );
  }

  // ------------------------------------------------------------------
  // MODO 2017 (NTC-Sismo 2017, numerales 3.1.2/3.1.3, 3.4.1, 3.5.1/3.5.2
  // y sección 5.5 para corrección por irregularidad)
  // ------------------------------------------------------------------

  /// Corrección de Q' por irregularidad (sección 5.5 NTC-2017):
  /// Q' se multiplica por 0.8 (irregular) o 0.7 (muy irregular),
  /// sin que Q' resulte menor que 1.
  static double qPrimeWithIrregularity({
    required double qPrime,
    required double irregularityFactor,
  }) {
    final corrected = qPrime * irregularityFactor;
    return corrected < 1.0 ? 1.0 : corrected;
  }

  /// Sobrerresistencia base R0 según ecuación 3.5.1:
  /// 2.0 para mampostería y sistemas con Q ≥ 3; 1.75 en otro caso.
  static double r0Base2017(double q) => q >= 3.0 ? 2.0 : 1.75;

  static SpectrumResult _computeSpectrum2017({
    required SiteParameters site,
    required SeismicFactors factors,
  }) {
    final iFactor = factors.importanceGroup.factor;
    final alpha = factors.irregularity.factor;
    final qFactor = factors.q;
    final r0base = r0Base2017(qFactor);

    const double maxT = 5.0;
    const double dt = 0.02;
    final int steps = (maxT / dt).round();

    final elastic = <SpectrumPoint>[];
    final design = <SpectrumPoint>[];
    final epu = <SpectrumPoint>[];
    double aMaxDesign = 0.0;

    for (int step = 0; step <= steps; step++) {
      final t = double.parse((step * dt).toStringAsFixed(3));

      // Espectro elástico (ec. 3.1.2) con exponente variable p (ec. 3.1.3).
      double ae;
      if (t < site.ta) {
        ae = site.a0 + (site.c - site.a0) * (t / site.ta);
      } else if (t <= site.tb) {
        ae = site.c;
      } else {
        final p = pExponentNorm(site.k, site.tb, t);
        ae = site.c * math.pow(site.tb / t, p);
      }
      elastic.add(SpectrumPoint(period: t, acceleration: ae));

      // Reducción: ad = I · ae / (Q'_eff · R), con Q'_eff corregido por
      // irregularidad (sección 5.5) y R = k1·R0 + k2 (ecuación 3.5.1).
      double qPrime = qPrimeNorm(
        q: qFactor,
        k: site.k,
        ta_: site.ta,
        tb_: site.tb,
        t: t,
      );
      qPrime = qPrimeWithIrregularity(
        qPrime: qPrime,
        irregularityFactor: alpha,
      );
      final rTotal = rTotalNorm(q: qFactor, k1: factors.k1, ta_: site.ta, t: t);

      final double ad = (iFactor * ae) / (qPrime * rTotal);
      if (ad > aMaxDesign) aMaxDesign = ad;
      design.add(SpectrumPoint(period: t, acceleration: ad));

      final trF = _trFactor(factors.returnPeriod);
      epu.add(
        SpectrumPoint(period: t, acceleration: iFactor * ae * 1.10 * trF),
      );
    }

    List<SpectrumPoint>? ntc2004Main;
    List<SpectrumPoint>? ntc2004ApA;
    Map<double, List<SpectrumPoint>>? qComparisons;

    final effectiveComparison = factors.comparisonMode.isActive
        ? factors.comparisonMode
        : (factors.showComparison2004
              ? ComparisonMode.all
              : ComparisonMode.none);
    if (effectiveComparison.isActive) {
      if (effectiveComparison.showZonas)
        ntc2004Main = _computeNtc2004Main(site, factors);
      if (effectiveComparison.showApA)
        ntc2004ApA = _computeNtc2004ApendiceA(site, factors);

      qComparisons = {};
      for (final qVal in [1.5, 2.0, 3.0, 4.0]) {
        qComparisons[qVal] = _computeDesignForQ(site, factors, qVal);
      }
    }

    return SpectrumResult(
      site: site,
      factors: factors,
      r0: double.parse((factors.k1 * r0base).toStringAsFixed(3)),
      aMaxDesign: double.parse(aMaxDesign.toStringAsFixed(4)),
      elasticSpectrum: elastic,
      designSpectrum: design,
      epuSpectrum: epu,
      ntc2004MainSpectrum: ntc2004Main,
      ntc2004ApendiceASpectrum: ntc2004ApA,
      qComparisons: qComparisons,
    );
  }

  static List<SpectrumPoint> _computeDesignForQ(
    SiteParameters site,
    SeismicFactors factors,
    double targetQ,
  ) {
    final iFactor = factors.importanceGroup.factor;
    final alpha = factors.irregularity.factor;
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
        final p = pExponentNorm(site.k, site.tb, t);
        ae = site.c * math.pow(site.tb / t, p);
      }

      double qPrime = qPrimeNorm(
        q: targetQ,
        k: site.k,
        ta_: site.ta,
        tb_: site.tb,
        t: t,
      );
      qPrime = qPrimeWithIrregularity(
        qPrime: qPrime,
        irregularityFactor: alpha,
      );
      final rTotal = rTotalNorm(q: targetQ, k1: factors.k1, ta_: site.ta, t: t);

      final double ad = (iFactor * ae) / (qPrime * rTotal);
      points.add(SpectrumPoint(period: t, acceleration: ad));
    }
    return points;
  }

  static List<SpectrumPoint> _computeNtc2004Main(
    SiteParameters site,
    SeismicFactors factors,
  ) {
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

    final qFactor = factors.q;
    final points = <SpectrumPoint>[];

    const double maxT = 5.0;
    const double dt = 0.02;
    final int steps = (maxT / dt).round();

    for (int step = 0; step <= steps; step++) {
      final t = double.parse((step * dt).toStringAsFixed(3));
      double a;
      if (t < ta04) {
        a = a004 + (c04 - a004) * (t / ta04);
      } else if (t <= tb04) {
        a = c04;
      } else {
        a = c04 * math.pow(tb04 / t, rExp);
      }

      final qPrime = t < ta04 ? 1.0 + (qFactor - 1.0) * (t / ta04) : qFactor;
      points.add(SpectrumPoint(period: t, acceleration: a / qPrime));
    }
    return points;
  }

  static double _trFactor(ReturnPeriod tr) {
    switch (tr) {
      case ReturnPeriod.tr10:
        return 0.42;
      case ReturnPeriod.tr50:
        return 0.62;
      case ReturnPeriod.tr100:
        return 0.76;
      case ReturnPeriod.tr250:
        return 0.90;
      case ReturnPeriod.tr475:
        return 1.00;
      case ReturnPeriod.tr975:
        return 1.26;
      case ReturnPeriod.tr2500:
        return 1.62;
    }
  }

  static List<SpectrumPoint> _computeNtc2004ApendiceA(
    SiteParameters site,
    SeismicFactors factors,
  ) {
    final ts = site.ts;
    final ta = ts <= 0.5 ? 0.2 : ts * 0.3;
    final tb = ts <= 0.5 ? 0.6 : ts * 1.2;
    final c = ts <= 0.5 ? 0.18 : (0.2 + ts * 0.18).clamp(0.2, 0.65);
    final a0 = c * 0.3;

    final qFactor = factors.q;
    final points = <SpectrumPoint>[];

    const double maxT = 5.0;
    const double dt = 0.02;
    final int steps = (maxT / dt).round();

    for (int step = 0; step <= steps; step++) {
      final t = double.parse((step * dt).toStringAsFixed(3));
      double a;
      if (t < ta) {
        a = a0 + (c - a0) * (t / ta);
      } else if (t <= tb) {
        a = c;
      } else {
        a = c * math.pow(tb / t, 1.0);
      }

      final qPrime = t < ta ? 1.0 + (qFactor - 1.0) * (t / ta) : qFactor;
      points.add(SpectrumPoint(period: t, acceleration: a / qPrime));
    }
    return points;
  }
}
