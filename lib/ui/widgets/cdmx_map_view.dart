import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/epoch.dart';
import '../../models/seismic_models.dart';
import '../../services/map_service.dart';
import '../theme/app_theme.dart';

class CdmxMapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final GeotechnicalZone currentZone;
  final Function(double lat, double lon) onCoordinatesSelected;
  final bool puntoEnabled;
  final VariationType variation;
  final bool showMunicipios;
  final bool showLomasDivision;
  final SiteParameters? site;
  const CdmxMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.currentZone,
    required this.onCoordinatesSelected,
    this.puntoEnabled = true,
    this.variation = VariationType.none,
    this.showMunicipios = false,
    this.showLomasDivision = true,
    this.site,
  });
  @override
  State<CdmxMapView> createState() => _CdmxMapViewState();
}

class _CdmxMapViewState extends State<CdmxMapView> {
  final MapController _mapController = MapController();
  bool _showZoneOverlays = true;
  List<List<LatLng>> _municipios = [];
  final Map<String, List<ZonaPolygon>> _zonas = {};
  LatLng? _mousePos;
  LatLng _initialCenter = const LatLng(19.432608, -99.133208);
  @override
  void initState() {
    super.initState();
    _initialCenter = LatLng(widget.latitude, widget.longitude);
    _loadMunicipios();
    _loadZonas();
  }

  Future<void> _loadMunicipios() async {
    final p = await MapService.loadAreaPolygons();
    if (mounted) setState(() => _municipios = p);
  }

  Future<void> _loadZonas() async {
    for (final z in MapService.zonas) {
      final polys = await MapService.loadZona(z);
      if (!mounted) return;
      setState(() => _zonas[z] = polys);
    }
  }

  /// Color oficial por zona geotécnica NTC.
  static Color _colorForZona(String zona) {
    switch (zona) {
      case 'Zona I':
        return GeotechnicalZone.zonaI.color;
      case 'Zona II':
        return GeotechnicalZone.zonaII.color;
      default:
        return GeotechnicalZone.zonaIIIc.color;
    }
  }

  void _centerCdmx() {
    _mapController.move(const LatLng(19.432608, -99.133208), 11.2);
  }

  void _resetPosition() {
    _mapController.move(_initialCenter, 11.5);
  }

  Color _variationColor() {
    if (widget.site == null) return AppColors.accent;
    switch (widget.variation) {
      case VariationType.ts:
        if (widget.site!.ts <= 0.5) return GeotechnicalZone.zonaI.color;
        if (widget.site!.ts <= 1.0) return GeotechnicalZone.zonaII.color;
        return GeotechnicalZone.zonaIIIc.color;
      case VariationType.c:
        return Color.lerp(
          const Color(0xFF22C55E),
          const Color(0xFFDC2626),
          (widget.site!.c / 1.1).clamp(0, 1),
        )!;
      case VariationType.a0:
        return Color.lerp(
          const Color(0xFFFACC15),
          const Color(0xFF7C3AED),
          (widget.site!.a0 / 0.25).clamp(0, 1),
        )!;
      case VariationType.k:
        return Color.lerp(
          const Color(0xFF06B6D4),
          const Color(0xFF0F172A),
          ((widget.site!.k - 1) / 1.5).clamp(0, 1),
        )!;
      case VariationType.none:
        return AppColors.accent;
    }
  }

  String _variationValue() {
    if (widget.site == null) return '';
    switch (widget.variation) {
      case VariationType.ts:
        return '${widget.site!.ts.toStringAsFixed(2)} s';
      case VariationType.c:
        return widget.site!.c.toStringAsFixed(3);
      case VariationType.a0:
        return '${widget.site!.a0.toStringAsFixed(3)} g';
      case VariationType.k:
        return widget.site!.k.toStringAsFixed(2);
      case VariationType.none:
        return '';
    }
  }

  @override
  void didUpdateWidget(covariant CdmxMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _mapController.move(
        LatLng(widget.latitude, widget.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPos = LatLng(widget.latitude, widget.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentPos,
              initialZoom: 11.5,
              minZoom: 9.0,
              maxZoom: 17.0,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture) setState(() => _mousePos = pos.center);
              },
              onTap: (_, point) {
                if (widget.puntoEnabled)
                  widget.onCoordinatesSelected(point.latitude, point.longitude);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sasid.app',
              ),
              // Zonificación geotécnica oficial NTC-2017: 3 capas separadas
              // (III abajo, II, I encima) con agujeros vía holePoints.
              if (_showZoneOverlays &&
                  widget.showLomasDivision &&
                  _zonas.isNotEmpty)
                for (final zonaKey in MapService.zonas.reversed)
                  if ((_zonas[zonaKey] ?? []).isNotEmpty)
                    PolygonLayer(
                      polygons: [
                        for (final poly in _zonas[zonaKey]!)
                          Polygon(
                            points: poly.outer,
                            holePointsList: poly.holes,
                            color: _colorForZona(
                              'Zona $zonaKey',
                            ).withValues(alpha: 0.18),
                            borderColor: _colorForZona('Zona $zonaKey'),
                            borderStrokeWidth: 1.5,
                          ),
                      ],
                    ),
              if (widget.showMunicipios && _municipios.isNotEmpty)
                PolygonLayer(
                  polygons: _municipios
                      .map(
                        (pts) => Polygon(
                          points: pts,
                          color: Colors.transparent,
                          borderColor: const Color(0xFF64748B),
                          borderStrokeWidth: 1.2,
                        ),
                      )
                      .toList(),
                ),
              if (widget.variation != VariationType.none && widget.site != null)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: [
                        LatLng(widget.latitude + 0.02, widget.longitude - 0.02),
                        LatLng(widget.latitude + 0.02, widget.longitude + 0.02),
                        LatLng(widget.latitude - 0.02, widget.longitude + 0.02),
                        LatLng(widget.latitude - 0.02, widget.longitude - 0.02),
                      ],
                      color: _variationColor().withValues(alpha: 0.35),
                      borderColor: _variationColor(),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentPos,
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: widget.currentZone.color.withValues(
                              alpha: 0.25,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Icon(
                          Icons.location_on,
                          size: 36,
                          color: widget.currentZone.color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Atribución obligatoria según OSM Tile Usage Policy.
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                _mapBtn(
                  icon: Icons.my_location,
                  tooltip: 'Centrar CDMX',
                  onPressed: _centerCdmx,
                ),
                const SizedBox(height: 6),
                _mapBtn(
                  icon: Icons.home,
                  tooltip: 'Regresar posición inicial',
                  onPressed: _resetPosition,
                ),
                const SizedBox(height: 6),
                _mapBtn(
                  icon: _showZoneOverlays
                      ? Icons.layers
                      : Icons.layers_outlined,
                  tooltip: _showZoneOverlays
                      ? 'Ocultar Zonificación'
                      : 'Mostrar Zonificación',
                  onPressed: () =>
                      setState(() => _showZoneOverlays = !_showZoneOverlays),
                  isActive: _showZoneOverlays,
                ),
                const SizedBox(height: 6),
                _mapBtn(
                  icon: Icons.add,
                  tooltip: 'Acercar',
                  onPressed: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  ),
                ),
                const SizedBox(height: 6),
                _mapBtn(
                  icon: Icons.remove,
                  tooltip: 'Alejar',
                  onPressed: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  ),
                ),
              ],
            ),
          ),
          if (_mousePos != null)
            Positioned(
              bottom: 38,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '(${_mousePos!.latitude.toStringAsFixed(4)}, ${_mousePos!.longitude.toStringAsFixed(4)})',
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            ),
          if (widget.variation != VariationType.none && widget.site != null)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Variación: ${widget.variation.label}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _variationColor().withValues(alpha: 0.3),
                                _variationColor(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _variationValue(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _legendItem(
                      'Lomas (Ts ≤ 0.5s)',
                      GeotechnicalZone.zonaI.color,
                    ),
                    const SizedBox(width: 10),
                    _legendItem('Transición', GeotechnicalZone.zonaII.color),
                    const SizedBox(width: 10),
                    _legendItem(
                      'Lago (Ts > 1.0s)',
                      GeotechnicalZone.zonaIIIc.color,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? AppColors.accent : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 18,
          color: isActive ? Colors.white : AppColors.textMain,
        ),
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
      ],
    );
  }
}
