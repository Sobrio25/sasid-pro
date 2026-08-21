enum Epoch {
  tmin(
    name: 'Tmin',
    label: 'Tmin',
    hexCode: '0x01',
    assetPath: 'assets/grids/Mallas Futuras/Malla Tmin/ES_DFTmin.grd',
  ),
  y1985(
    name: '1985',
    label: '1985',
    hexCode: '0x02',
    assetPath: 'assets/grids/Mallas Futuras/Malla1985/ES_DF1985.grd',
  ),
  y2010(
    name: '2010',
    label: '2010',
    hexCode: '0x04',
    assetPath: 'assets/grids/Mallas Futuras/Malla2010/ES_DF2010.grd',
  ),
  y2030(
    name: '2030',
    label: '2030',
    hexCode: '0x08',
    assetPath: 'assets/grids/Mallas Futuras/Malla2030/ES_DF2030.grd',
  ),
  y2050(
    name: '2050',
    label: '2050',
    hexCode: '0x10',
    assetPath: 'assets/grids/Mallas Futuras/Malla2050/ES_DF2050.grd',
  ),
  y2100(
    name: '2100',
    label: '2100',
    hexCode: '0x20',
    assetPath: 'assets/grids/Mallas Futuras/Malla2100/ES_DF2100.grd',
  );

  final String name;
  final String label;
  final String hexCode;
  final String assetPath;
  const Epoch({
    required this.name,
    required this.label,
    required this.hexCode,
    required this.assetPath,
  });
}

enum NormVersion {
  ntc2016(label: 'NTC 2016 (SASID)', short: 'E. Diseño 2016'),
  ntc2017(label: 'NTC 2017', short: 'E. Diseño 2017'),
  ntc2023(label: 'NTC 2023', short: 'E. Diseño 2023');

  final String label;
  final String short;
  const NormVersion({required this.label, required this.short});
}

/// Nivel de desempeño según NTC-Sismo 2023, numeral 3.3.2.
enum PerformanceLevel {
  seguridadVida(
    label: 'Seguridad de Vida',
    rFactor: 1.0,
    description: "R' = R (3.3.2a)",
  ),
  ocupacionInmediata(
    label: 'Ocupación Inmediata',
    rFactor: 0.75,
    description: "R' = 0.75·R (3.3.2b)",
  );

  final String label;
  final double rFactor;
  final String description;
  const PerformanceLevel({
    required this.label,
    required this.rFactor,
    required this.description,
  });
}

enum ReturnPeriod {
  tr10(value: 10, label: 'Tr=10a'),
  tr50(value: 50, label: 'Tr=50a'),
  tr100(value: 100, label: 'Tr=100a'),
  tr250(value: 250, label: 'Tr=250a'),
  tr475(value: 475, label: 'Tr=475a'),
  tr975(value: 975, label: 'Tr=975a'),
  tr2500(value: 2500, label: 'Tr=2500a');

  final int value;
  final String label;
  const ReturnPeriod({required this.value, required this.label});
}

enum SpectrumType {
  elastic(label: 'Elástico', code: 'E'),
  design(label: 'Diseño', code: 'D'),
  epu(label: 'Peligro Uniforme', code: 'EPU');

  final String label;
  final String code;
  const SpectrumType({required this.label, required this.code});
}

enum ComparisonMode {
  none(label: 'Ninguna'),
  ntc2004ApA(label: 'vs NTC 2004 Ap. A'),
  ntc2004Zonas(label: 'vs NTC 2004 Zonas'),
  all(label: 'Todas');

  final String label;
  const ComparisonMode({required this.label});
  bool get showApA =>
      this == ComparisonMode.ntc2004ApA || this == ComparisonMode.all;
  bool get showZonas =>
      this == ComparisonMode.ntc2004Zonas || this == ComparisonMode.all;
  bool get isActive => this != ComparisonMode.none;
}

enum VariationType {
  none(label: 'Ninguna'),
  ts(label: 'Periodo Ts'),
  c(label: 'Coeficiente c'),
  a0(label: 'Aceleración a0'),
  k(label: 'Exponente k');

  final String label;
  const VariationType({required this.label});
}

enum CoordinateMode {
  punto(label: 'Punto'),
  coordenada(label: 'Coordenada'),
  direccion(label: 'Dirección');

  final String label;
  const CoordinateMode({required this.label});
}
