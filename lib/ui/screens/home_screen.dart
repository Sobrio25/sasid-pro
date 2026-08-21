import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/epoch.dart';
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
  double _currentLat = 19.432608;
  double _currentLon = -99.133208;
  SeismicFactors _factors = const SeismicFactors();
  late SpectrumResult _result;
  CoordinateMode _coordMode = CoordinateMode.coordenada;
  bool _puntoEnabled = true;
  VariationType _variation = VariationType.none;
  bool _showMunicipios = false;
  bool _showLomas = true;

  bool _loadingGrid = false;
  @override
  void initState() {
    super.initState();
    _result = SeismicEngine.computeSpectrum(
      site: SeismicEngine.calculateSiteParameters(
        _currentLat,
        _currentLon,
        epoch: _factors.epoch,
      ),
      factors: _factors,
    );
    _recalculate();
  }

  Future<void> _recalculate() async {
    setState(() => _loadingGrid = true);
    final site = await SeismicEngine.calculateSiteParametersWithGrid(
      _currentLat,
      _currentLon,
      epoch: _factors.epoch,
      norm: _factors.norm,
    );
    if (!mounted) return;
    setState(() {
      _result = SeismicEngine.computeSpectrum(site: site, factors: _factors);
      _loadingGrid = false;
    });
  }

  void _onCoordinatesChanged(double lat, double lon) {
    _currentLat = lat;
    _currentLon = lon;
    setState(() {});
    _recalculate();
  }

  void _onFactorsChanged(SeismicFactors u) {
    _factors = u;
    setState(() {});
    _recalculate();
  }

  Future<void> _exportTxt() async {
    final content = ExportService.generateSap2000Txt(
      _result,
      type: _factors.exportSpectrumType,
    );
    final path = await ExportService.saveToFile(
      content,
      'espectro_${_factors.exportSpectrumType.code}.txt',
    );
    if (!mounted) return;
    if (path != null)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guardado en $path'),
          backgroundColor: Colors.green,
        ),
      );
    else {
      await Clipboard.setData(ClipboardData(text: content));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copiado al portapapeles'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _exportCsv() async {
    final content = ExportService.generateCsv(_result);
    final path = await ExportService.saveToFile(content, 'espectro.csv');
    if (!mounted) return;
    if (path != null)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV guardado en $path'),
          backgroundColor: Colors.green,
        ),
      );
    else {
      await Clipboard.setData(ClipboardData(text: content));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV copiado'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'NTC-Sismo 2017/2023 | v0.2.0',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<CdmxPreset>(
            icon: const Icon(Icons.bookmarks_outlined, color: Colors.white),
            tooltip: 'Sitios Predefinidos',
            onSelected: (p) => _onCoordinatesChanged(p.latitude, p.longitude),
            itemBuilder: (c) => CdmxPresets.landmarks
                .map(
                  (p) => PopupMenuItem(
                    value: p,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          p.subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.map_outlined, color: Colors.white),
            tooltip: 'Mapa',
            onSelected: (v) {
              setState(() {
                if (v == 'municipios') _showMunicipios = !_showMunicipios;
                if (v == 'lomas') _showLomas = !_showLomas;
                if (v == 'centrar') {}
              });
            },
            itemBuilder: (c) => [
              CheckedPopupMenuItem(
                value: 'municipios',
                checked: _showMunicipios,
                child: const Text('Mostrar municipios'),
              ),
              CheckedPopupMenuItem(
                value: 'lomas',
                checked: _showLomas,
                child: const Text('Mostrar división lomas'),
              ),
              const PopupMenuDivider(),
              ...VariationType.values.map(
                (vt) => PopupMenuItem(
                  value: 'var_${vt.name}',
                  child: Row(
                    children: [
                      Icon(
                        vt == _variation ? Icons.check : Icons.circle_outlined,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text('Variación ${vt.label}'),
                    ],
                  ),
                  onTap: () => setState(() => _variation = vt),
                ),
              ),
            ],
          ),
          PopupMenuButton<SpectrumType>(
            icon: const Icon(Icons.code, color: Colors.white),
            tooltip: 'Exportar TXT',
            onSelected: (t) {
              setState(
                () => _factors = _factors.copyWith(exportSpectrumType: t),
              );
              _exportTxt();
            },
            itemBuilder: (c) => SpectrumType.values
                .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: 'PDF',
            onPressed: _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.table_view, color: Colors.white),
            tooltip: 'CSV',
            onPressed: _exportCsv,
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: Container(
        color: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Coord: ${_currentLat.toStringAsFixed(6)}, ${_currentLon.toStringAsFixed(6)}',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
            Text(
              'Malla activa: ${_result.site.activeMallaHex} (${_factors.epoch.label}) | Tr ${_factors.returnPeriod.label}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          final left = SizedBox(
            width: 420,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 18,
                              color: AppColors.accent,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Ubicación Geográfica',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
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
                            puntoEnabled: _coordMode == CoordinateMode.punto
                                ? _puntoEnabled
                                : true,
                            variation: _variation,
                            showMunicipios: _showMunicipios,
                            showLomasDivision: _showLomas,
                            site: _result.site,
                          ),
                        ),
                        const SizedBox(height: 10),
                        LocationSelector(
                          currentLat: _currentLat,
                          currentLon: _currentLon,
                          mode: _coordMode,
                          onModeChanged: (m) => setState(() => _coordMode = m),
                          puntoEnabled: _puntoEnabled,
                          onPuntoChanged: (v) =>
                              setState(() => _puntoEnabled = v),
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
          );
          final right = Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                ParametersCard(result: _result),
                const SizedBox(height: 8),
                SpectrumChart(result: _result),
                const SizedBox(height: 8),
                if (_factors.comparisonMode.isActive) ...[
                  ComparisonGrid(result: _result),
                  const SizedBox(height: 8),
                ],
                DataTableView(result: _result),
              ],
            ),
          );
          if (isWide)
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [left, right],
            );
          return ListView(
            padding: const EdgeInsets.all(10),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 240,
                        child: CdmxMapView(
                          latitude: _currentLat,
                          longitude: _currentLon,
                          currentZone: _result.site.zone,
                          onCoordinatesSelected: _onCoordinatesChanged,
                          puntoEnabled: _coordMode == CoordinateMode.punto
                              ? _puntoEnabled
                              : true,
                          variation: _variation,
                          showMunicipios: _showMunicipios,
                          showLomasDivision: _showLomas,
                          site: _result.site,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LocationSelector(
                        currentLat: _currentLat,
                        currentLon: _currentLon,
                        mode: _coordMode,
                        onModeChanged: (m) => setState(() => _coordMode = m),
                        puntoEnabled: _puntoEnabled,
                        onPuntoChanged: (v) =>
                            setState(() => _puntoEnabled = v),
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
              if (_factors.comparisonMode.isActive) ...[
                ComparisonGrid(result: _result),
                const SizedBox(height: 8),
              ],
              DataTableView(result: _result),
            ],
          );
        },
      ),
    );
  }
}
