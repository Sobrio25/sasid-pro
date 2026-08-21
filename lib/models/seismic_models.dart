import 'package:flutter/material.dart';
import 'epoch.dart';

enum GeotechnicalZone {
  zonaI(
    name: 'Zona I - Lomas',
    shortName: 'Lomas',
    tsRange: 'Ts <= 0.5 s',
    color: Color(0xFF2E7D32),
    description:
        'Terreno firme compuesto por tobas volcánicas, arenas y gravas compactas.',
  ),
  zonaII(
    name: 'Zona II - Transición',
    shortName: 'Transición',
    tsRange: '0.5 s < Ts <= 1.0 s',
    color: Color(0xFFF57F17),
    description:
        'Depósitos arcillosos de espesor moderado intercalados con estratos arenosos.',
  ),
  zonaIIIa(
    name: 'Zona IIIa - Lago',
    shortName: 'Lago (IIIa)',
    tsRange: '1.0 s < Ts <= 1.5 s',
    color: Color(0xFFE65100),
    description:
        'Depósitos arcillosos altamente compresibles con periodos entre 1.0 y 1.5 s.',
  ),
  zonaIIIb(
    name: 'Zona IIIb - Lago',
    shortName: 'Lago (IIIb)',
    tsRange: '1.5 s < Ts <= 2.0 s',
    color: Color(0xFFD84315),
    description:
        'Depósitos arcillosos de gran espesor con periodos dominantes entre 1.5 y 2.0 s.',
  ),
  zonaIIIc(
    name: 'Zona IIIc - Lago',
    shortName: 'Lago (IIIc)',
    tsRange: '2.0 s < Ts <= 3.0 s',
    color: Color(0xFFC62828),
    description:
        'Zona de lago profundo con periodos dominantes entre 2.0 y 3.0 s.',
  ),
  zonaIIId(
    name: 'Zona IIId - Lago',
    shortName: 'Lago (IIId)',
    tsRange: 'Ts > 3.0 s',
    color: Color(0xFF880E4F),
    description:
        'Zona de máxima amplificación dinámica del suelo con Ts > 3.0 s.',
  );

  final String name;
  final String shortName;
  final String tsRange;
  final Color color;
  final String description;

  const GeotechnicalZone({
    required this.name,
    required this.shortName,
    required this.tsRange,
    required this.color,
    required this.description,
  });
}

enum ImportanceGroup {
  grupoA(
    name: 'Grupo A (Estructuras esenciales)',
    factor: 1.5,
    code: 'A',
    description:
        'Hospitales, escuelas, centrales eléctricas, telecomunicaciones.',
  ),
  grupoB(
    name: 'Grupo B (Estructuras comunes)',
    factor: 1.0,
    code: 'B',
    description:
        'Viviendas, oficinas, comercios, hoteles e industrias estándar.',
  ),
  grupoA2(
    name: 'Subgrupo A2 (NTC 2017)',
    factor: 1.3,
    code: 'A2',
    description:
        'Edificaciones con sustancias inflamables o tóxicas en cantidades '
        'intermedias (numeral 3.3 NTC-2017 / Art. 139 Reglamento).',
  ),
  grupoA1(
    name: 'Grupo A1 (Especiales / NTC 2023)',
    factor: 1.75,
    code: 'A1',
    description:
        'Instalaciones críticas con sustancias peligrosas o de seguridad nacional.',
  );

  final String name;
  final double factor;
  final String code;
  final String description;

  const ImportanceGroup({
    required this.name,
    required this.factor,
    required this.code,
    required this.description,
  });
}

enum IrregularityFactor {
  regular(name: 'Regular', factor: 1.0),
  irregular(name: 'Irregular (α = 0.9)', factor: 0.9),
  fuertementeIrregular(name: 'Irregular (corr. Q\' × 0.8)', factor: 0.8),
  muyIrregular(name: 'Muy Irregular (corr. Q\' × 0.7)', factor: 0.7);

  final String name;
  final double factor;

  const IrregularityFactor({required this.name, required this.factor});

  /// Opciones aplicables según la norma seleccionada.
  ///
  /// - NTC 2016 (SASID A): cuatro niveles de α divisor (1.0/0.9/0.8/0.7).
  /// - NTC 2017/2023 (sec. 5.5): solo Regular, Irregular (×0.8) y
  ///   Muy irregular (×0.7) como corrección de Q'.
  static List<IrregularityFactor> optionsFor(NormVersion norm) {
    switch (norm) {
      case NormVersion.ntc2016:
        return IrregularityFactor.values;
      case NormVersion.ntc2017:
      case NormVersion.ntc2023:
        return [
          IrregularityFactor.regular,
          IrregularityFactor.fuertementeIrregular,
          IrregularityFactor.muyIrregular,
        ];
    }
  }
}

class SeismicFactors {
  final ImportanceGroup importanceGroup;
  final double q; // 1.0, 1.5, 2.0, 3.0, 4.0
  final IrregularityFactor irregularity;
  final double k1; // 0.8, 1.0, 1.25
  final bool showEpu;
  final bool showComparison2004;
  final ComparisonMode comparisonMode;
  final SpectrumType exportSpectrumType;
  final ReturnPeriod returnPeriod;
  final Epoch epoch;
  final NormVersion norm;
  final PerformanceLevel performanceLevel;

  const SeismicFactors({
    this.importanceGroup = ImportanceGroup.grupoB,
    this.q = 2.0,
    this.irregularity = IrregularityFactor.regular,
    this.k1 = 1.0,
    this.showEpu = false,
    this.showComparison2004 = false,
    this.comparisonMode = ComparisonMode.none,
    this.exportSpectrumType = SpectrumType.design,
    this.returnPeriod = ReturnPeriod.tr475,
    this.epoch = Epoch.y2010,
    this.norm = NormVersion.ntc2016,
    this.performanceLevel = PerformanceLevel.seguridadVida,
  });

  SeismicFactors copyWith({
    ImportanceGroup? importanceGroup,
    double? q,
    IrregularityFactor? irregularity,
    double? k1,
    bool? showEpu,
    bool? showComparison2004,
    ComparisonMode? comparisonMode,
    SpectrumType? exportSpectrumType,
    ReturnPeriod? returnPeriod,
    Epoch? epoch,
    NormVersion? norm,
    PerformanceLevel? performanceLevel,
  }) {
    return SeismicFactors(
      importanceGroup: importanceGroup ?? this.importanceGroup,
      q: q ?? this.q,
      irregularity: irregularity ?? this.irregularity,
      k1: k1 ?? this.k1,
      showEpu: showEpu ?? this.showEpu,
      showComparison2004:
          showComparison2004 ??
          (comparisonMode ?? this.comparisonMode).isActive,
      comparisonMode: comparisonMode ?? this.comparisonMode,
      exportSpectrumType: exportSpectrumType ?? this.exportSpectrumType,
      returnPeriod: returnPeriod ?? this.returnPeriod,
      epoch: epoch ?? this.epoch,
      norm: norm ?? this.norm,
      performanceLevel: performanceLevel ?? this.performanceLevel,
    );
  }

  SeismicFactors withComparisonLocked() {
    if (!comparisonMode.isActive) return this;
    return copyWith(
      importanceGroup: ImportanceGroup.grupoB,
      irregularity: IrregularityFactor.regular,
      k1: 1.0,
    );
  }
}

class SiteParameters {
  final double latitude;
  final double longitude;
  final double ts; // Periodo del suelo (s)
  final double a0; // Aceleración máxima del terreno (PGA / g)
  final double c; // Coeficiente sísmico
  final double ta; // Periodo característico Ta (s)
  final double tb; // Periodo característico Tb (s)
  final double k; // Exponente de relación de desplazamientos
  final GeotechnicalZone zone;
  final Epoch epoch;
  final String activeMallaHex;

  const SiteParameters({
    required this.latitude,
    required this.longitude,
    required this.ts,
    required this.a0,
    required this.c,
    required this.ta,
    required this.tb,
    required this.k,
    required this.zone,
    this.epoch = Epoch.y2010,
    this.activeMallaHex = '0x04',
  });

  /// Zona sísmica NTC-Sismo 2023 (numeral 1.3):
  /// A (Ts ≤ 0.5 s), B (0.5 < Ts ≤ 1.0 s), C (Ts > 1.0 s).
  String get zone2023 {
    if (ts <= 0.5) return 'Zona A';
    if (ts <= 1.0) return 'Zona B';
    return 'Zona C';
  }
}

class SpectrumPoint {
  final double period; // T (s)
  final double acceleration; // Sa (g)

  const SpectrumPoint({required this.period, required this.acceleration});

  @override
  String toString() => '($period s, ${acceleration.toStringAsFixed(4)} g)';
}

class SpectrumResult {
  final SiteParameters site;
  final SeismicFactors factors;
  final double r0; // Factor de sobrerresistencia base
  final double aMaxDesign; // Aceleración máxima del espectro de diseño (g)
  final List<SpectrumPoint> elasticSpectrum;
  final List<SpectrumPoint> designSpectrum;
  final List<SpectrumPoint> epuSpectrum;
  final List<SpectrumPoint>? ntc2004MainSpectrum;
  final List<SpectrumPoint>? ntc2004ApendiceASpectrum;
  final Map<double, List<SpectrumPoint>>? qComparisons; // Q -> points

  const SpectrumResult({
    required this.site,
    required this.factors,
    required this.r0,
    required this.aMaxDesign,
    required this.elasticSpectrum,
    required this.designSpectrum,
    required this.epuSpectrum,
    this.ntc2004MainSpectrum,
    this.ntc2004ApendiceASpectrum,
    this.qComparisons,
  });
}
