import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/seismic_models.dart';
import '../../models/cdmx_preset.dart';
import '../../services/seismic_engine.dart';
import '../../services/export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cdmx_map_view.dart';
import '../widgets/location_selector.dart';
import '../widgets/factors_panel.dart';
import '../widgets/parameters_card.dart';
import '../widgets/spectrum_chart.dart';
import '../widgets/comparison_grid.dart';
import '../widgets/data_table_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Estado inicial: Centro Histórico (Zócalo CDMX)
  double _currentLat = 19.432608;
  double _currentLon = -99.133208;
  SeismicFactors _factors = const SeismicFactors();
  late SpectrumResult _result;

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  void _recalculate() {
    final site = SeismicEngine.calculateSiteParameters(_currentLat, _currentLon);
    _result = SeismicEngine.computeSpectrum(site: site, factors: _factors);
  }

  void _onCoordinatesChanged(double lat, double lon) {
    setState(() {
      _currentLat = lat;
      _currentLon = lon;
      _recalculate();
    });
  }

  void _onFactorsChanged(SeismicFactors updated) {
    setState(() {
      _factors = updated;
      _recalculate();
    });
  }

  void _exportTxt() {
    final content = ExportService.generateSap2000Txt(_result);
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Espectro en formato SAP2000/ETABS copiado al portapapeles.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportCsv() {
    final content = ExportService.generateCsv(_result);
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Espectro en formato CSV para Excel copiado al portapapeles.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportPdf() async {
    await ExportService.exportPdfReport(_result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.waves, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SASID A - Espectros de Diseño Sísmico',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Normas Técnicas Complementarias CDMX (NTC-Sismo)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Selector rápido de ubicaciones de interés
          PopupMenuButton<CdmxPreset>(
            icon: const Icon(Icons.bookmarks_outlined, color: Colors.white),
            tooltip: 'Sitios Predefinidos CDMX',
            onSelected: (preset) => _onCoordinatesChanged(preset.latitude, preset.longitude),
            itemBuilder: (context) => CdmxPresets.landmarks.map((p) {
              return PopupMenuItem(
                value: p,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(p.subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              );
            }).toList(),
          ),

          // Botón Exportar PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: 'Generar Memoria en PDF',
            onPressed: _exportPdf,
          ),

          // Botón Exportar TXT SAP2000
          IconButton(
            icon: const Icon(Icons.code, color: Colors.white),
            tooltip: 'Exportar a SAP2000 / ETABS (.txt)',
            onPressed: _exportTxt,
          ),

          // Botón Exportar CSV Excel
          IconButton(
            icon: const Icon(Icons.table_view, color: Colors.white),
            tooltip: 'Exportar CSV Excel',
            onPressed: _exportCsv,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          if (isWide) {
            // Diseño en dos columnas para Desktop / Tablets
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna Izquierda: Mapa, Coordenadas y Factores
                SizedBox(
                  width: 420,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.map_outlined, size: 18, color: AppColors.accent),
                                  SizedBox(width: 6),
                                  Text('Ubicación Geográfica', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 260,
                                child: CdmxMapView(
                                  latitude: _currentLat,
                                  longitude: _currentLon,
                                  currentZone: _result.site.zone,
                                  onCoordinatesSelected: _onCoordinatesChanged,
                                ),
                              ),
                              const SizedBox(height: 10),
                              LocationSelector(
                                currentLat: _currentLat,
                                currentLon: _currentLon,
                                onLocationChanged: _onCoordinatesChanged,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FactorsPanel(
                        factors: _factors,
                        onFactorsChanged: _onFactorsChanged,
                      ),
                    ],
                  ),
                ),

                // Columna Derecha: Parámetros, Gráfica de Espectro y Comparativas
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      ParametersCard(result: _result),
                      const SizedBox(height: 8),
                      SpectrumChart(result: _result),
                      const SizedBox(height: 8),
                      if (_factors.showComparison2004) ...[
                        ComparisonGrid(result: _result),
                        const SizedBox(height: 8),
                      ],
                      DataTableView(result: _result),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Diseño en una sola columna para pantallas móviles
            return ListView(
              padding: const EdgeInsets.all(10),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 240,
                          child: CdmxMapView(
                            latitude: _currentLat,
                            longitude: _currentLon,
                            currentZone: _result.site.zone,
                            onCoordinatesSelected: _onCoordinatesChanged,
                          ),
                        ),
                        const SizedBox(height: 10),
                        LocationSelector(
                          currentLat: _currentLat,
                          currentLon: _currentLon,
                          onLocationChanged: _onCoordinatesChanged,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ParametersCard(result: _result),
                const SizedBox(height: 8),
                SpectrumChart(result: _result),
                const SizedBox(height: 8),
                FactorsPanel(
                  factors: _factors,
                  onFactorsChanged: _onFactorsChanged,
                ),
                const SizedBox(height: 8),
                if (_factors.showComparison2004) ...[
                  ComparisonGrid(result: _result),
                  const SizedBox(height: 8),
                ],
                DataTableView(result: _result),
              ],
            );
          }
        },
      ),
    );
  }
}
