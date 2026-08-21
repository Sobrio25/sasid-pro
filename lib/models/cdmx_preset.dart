class CdmxPreset {
  final String name;
  final String subtitle;
  final double latitude;
  final double longitude;
  final String zoneType;

  const CdmxPreset({
    required this.name,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    required this.zoneType,
  });
}

class CdmxPresets {
  static const List<CdmxPreset> landmarks = [
    CdmxPreset(
      name: 'Zócalo / Centro Histórico',
      subtitle: 'Alcaldía Cuauhtémoc (Zona de Lago)',
      latitude: 19.432608,
      longitude: -99.133208,
      zoneType: 'Lago (Zona III)',
    ),
    CdmxPreset(
      name: 'Ciudad Universitaria (UNAM)',
      subtitle: 'Alcaldía Coyoacán (Zona de Lomas / Pedregal)',
      latitude: 19.332822,
      longitude: -99.186638,
      zoneType: 'Lomas (Zona I)',
    ),
    CdmxPreset(
      name: 'Paseo de la Reforma / Ángel',
      subtitle: 'Alcaldía Cuauhtémoc (Zona de Lago / Transición)',
      latitude: 19.427021,
      longitude: -99.167665,
      zoneType: 'Lago (Zona IIIb)',
    ),
    CdmxPreset(
      name: 'Santa Fe (Distrito Financiero)',
      subtitle: 'Alcaldía Cuajimalpa / Álvaro Obregón (Zona de Lomas)',
      latitude: 19.359850,
      longitude: -99.260450,
      zoneType: 'Lomas (Zona I)',
    ),
    CdmxPreset(
      name: 'Polanco / Chapultepec',
      subtitle: 'Alcaldía Miguel Hidalgo (Zona de Transición)',
      latitude: 19.433800,
      longitude: -99.191200,
      zoneType: 'Transición (Zona II)',
    ),
    CdmxPreset(
      name: 'Colonia Roma / Condesa',
      subtitle: 'Alcaldía Cuauhtémoc (Zona de Lago blando)',
      latitude: 19.416200,
      longitude: -99.163300,
      zoneType: 'Lago (Zona IIIb)',
    ),
    CdmxPreset(
      name: 'Tlatelolco / Plaza de las Tres Culturas',
      subtitle: 'Alcaldía Cuauhtémoc (Zona de Lago profundo)',
      latitude: 19.451700,
      longitude: -99.137800,
      zoneType: 'Lago (Zona IIIc)',
    ),
    CdmxPreset(
      name: 'Aeropuerto AICM',
      subtitle: 'Alcaldía Venustiano Carranza (Zona de Lago profundo)',
      latitude: 19.436100,
      longitude: -99.071900,
      zoneType: 'Lago (Zona IIIc)',
    ),
    CdmxPreset(
      name: 'Central de Abasto / Iztapalapa',
      subtitle: 'Alcaldía Iztapalapa (Zona de Lago)',
      latitude: 19.367000,
      longitude: -99.088000,
      zoneType: 'Lago (Zona IIIc)',
    ),
    CdmxPreset(
      name: 'San Ángel / Insurgentes Sur',
      subtitle: 'Alcaldía Álvaro Obregón (Zona de Lomas / Transición)',
      latitude: 19.348000,
      longitude: -99.189000,
      zoneType: 'Lomas (Zona I)',
    ),
    CdmxPreset(
      name: 'Xochimilco Centro / Embarcadero',
      subtitle: 'Alcaldía Xochimilco (Zona lacustre)',
      latitude: 19.263500,
      longitude: -99.103700,
      zoneType: 'Lago (Zona IIId)',
    ),
  ];

  static const List<CdmxPreset> alcaldias = [
    CdmxPreset(name: 'Álvaro Obregón', subtitle: 'Sede Alcaldía', latitude: 19.3900, longitude: -99.2000, zoneType: 'Lomas / Transición'),
    CdmxPreset(name: 'Azcapotzalco', subtitle: 'Sede Alcaldía', latitude: 19.4850, longitude: -99.1850, zoneType: 'Transición / Lago'),
    CdmxPreset(name: 'Benito Juárez', subtitle: 'Sede Alcaldía', latitude: 19.3800, longitude: -99.1550, zoneType: 'Transición / Lago'),
    CdmxPreset(name: 'Coyoacán', subtitle: 'Sede Alcaldía', latitude: 19.3500, longitude: -99.1620, zoneType: 'Lomas / Transición'),
    CdmxPreset(name: 'Cuajimalpa de Morelos', subtitle: 'Sede Alcaldía', latitude: 19.3550, longitude: -99.2900, zoneType: 'Lomas (Zona I)'),
    CdmxPreset(name: 'Cuauhtémoc', subtitle: 'Sede Alcaldía', latitude: 19.4400, longitude: -99.1500, zoneType: 'Lago (Zona III)'),
    CdmxPreset(name: 'Gustavo A. Madero', subtitle: 'Sede Alcaldía', latitude: 19.4800, longitude: -99.1100, zoneType: 'Transición / Lago'),
    CdmxPreset(name: 'Iztacalco', subtitle: 'Sede Alcaldía', latitude: 19.3950, longitude: -99.1000, zoneType: 'Lago (Zona III)'),
    CdmxPreset(name: 'Iztapalapa', subtitle: 'Sede Alcaldía', latitude: 19.3550, longitude: -99.0750, zoneType: 'Lago (Zona III)'),
    CdmxPreset(name: 'La Magdalena Contreras', subtitle: 'Sede Alcaldía', latitude: 19.3000, longitude: -99.2400, zoneType: 'Lomas (Zona I)'),
    CdmxPreset(name: 'Miguel Hidalgo', subtitle: 'Sede Alcaldía', latitude: 19.4100, longitude: -99.1900, zoneType: 'Lomas / Transición'),
    CdmxPreset(name: 'Milpa Alta', subtitle: 'Sede Alcaldía', latitude: 19.1900, longitude: -99.0200, zoneType: 'Lomas / Volcánica'),
    CdmxPreset(name: 'Tláhuac', subtitle: 'Sede Alcaldía', latitude: 19.2850, longitude: -99.0050, zoneType: 'Lago (Zona III)'),
    CdmxPreset(name: 'Tlalpan', subtitle: 'Sede Alcaldía', latitude: 19.2880, longitude: -99.1680, zoneType: 'Lomas (Zona I)'),
    CdmxPreset(name: 'Venustiano Carranza', subtitle: 'Sede Alcaldía', latitude: 19.4250, longitude: -99.0900, zoneType: 'Lago (Zona III)'),
    CdmxPreset(name: 'Xochimilco', subtitle: 'Sede Alcaldía', latitude: 19.2550, longitude: -99.1050, zoneType: 'Lago (Zona III)'),
  ];
}
