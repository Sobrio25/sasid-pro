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
import '../widgets/section_header.dart';

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
      site: SeismicEngine.calculateSiteParametersSync(
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
          backgroundColor: AppColors.success,
        ),
      );
    else {
      await Clipboard.setData(ClipboardData(text: content));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Copiado al portapapeles'),
          backgroundColor: AppColors.success,
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
          backgroundColor: AppColors.success,
        ),
      );
    else {
      await Clipboard.setData(ClipboardData(text: content));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('CSV copiado'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _exportPdf() async {
    await ExportService.exportPdfReport(_result);
  }

  PreferredSizeWidget get _progressBar => PreferredSize(
    preferredSize: const Size.fromHeight(3),
    child: ColoredBox(
      color: AppColors.primary,
      child: _loadingGrid
          ? const LinearProgressIndicator(minHeight: 3)
          : const SizedBox(height: 3, width: double.infinity),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.accentLight, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.waves, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SASID A - Espectros de Diseño Sísmico',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1),
                  Text(
                    'NTC-Sismo 2017/2023 · CDMX',
                    style: TextStyle(fontSize: 11, color: AppColors.textFaint),
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
                    height: 48,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 18,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 10),
                        Column(
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
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.layers_outlined, color: Colors.white),
            tooltip: 'Capas del Mapa',
            onSelected: (v) {
              setState(() {
                if (v == 'municipios') _showMunicipios = !_showMunicipios;
                if (v == 'lomas') _showLomas = !_showLomas;
                if (v == 'centrar') {}
              });
            },
            itemBuilder: (c) => [
              const PopupMenuItem(
                value: 'hdr_capas',
                enabled: false,
                height: 32,
                child: Text(
                  'CAPAS',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textFaint,
                  ),
                ),
              ),
              CheckedPopupMenuItem(
                value: 'municipios',
                checked: _showMunicipios,
                height: 40,
                child: const Text('Mostrar municipios'),
              ),
              CheckedPopupMenuItem(
                value: 'lomas',
                checked: _showLomas,
                height: 40,
                child: const Text('Mostrar división lomas'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'hdr_var',
                enabled: false,
                height: 32,
                child: Text(
                  'MAPA DE VARIACIÓN',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textFaint,
                  ),
                ),
              ),
              ...VariationType.values.map(
                (vt) => PopupMenuItem(
                  value: 'var_${vt.name}',
                  height: 38,
                  child: Row(
                    children: [
                      Icon(
                        vt == _variation
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: vt == _variation
                            ? AppColors.accent
                            : AppColors.textFaint,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        vt.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: vt == _variation
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: vt == _variation
                              ? AppColors.textMain
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => setState(() => _variation = vt),
                ),
              ),
            ],
          ),
          const _AppBarDivider(),
          PopupMenuButton<SpectrumType>(
            icon: const Icon(Icons.code, color: Colors.white),
            tooltip: 'Exportar TXT (SAP2000)',
            onSelected: (t) {
              setState(
                () => _factors = _factors.copyWith(exportSpectrumType: t),
              );
              _exportTxt();
            },
            itemBuilder: (c) => SpectrumType.values
                .map(
                  (s) => PopupMenuItem(
                    value: s,
                    height: 40,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.data_object,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 10),
                        Text(s.label),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: 'Exportar PDF',
            onPressed: _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.table_view, color: Colors.white),
            tooltip: 'Exportar CSV',
            onPressed: _exportCsv,
          ),
          const SizedBox(width: 6),
        ],
        bottom: _progressBar,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.primary,
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.place, size: 12, color: AppColors.textFaint),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                '${_currentLat.toStringAsFixed(6)}, ${_currentLon.toStringAsFixed(6)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            const Icon(Icons.grid_on, size: 12, color: AppColors.textFaint),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'Malla ${_result.site.activeMallaHex} (${_factors.epoch.label}) · Tr ${_factors.returnPeriod.label}',
                style: const TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 11.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          if (isWide)
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 420,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 24),
                    children: [
                      _locationCard(mapHeight: 280),
                      const SizedBox(height: 14),
                      FactorsPanel(
                        factors: _factors,
                        onFactorsChanged: _onFactorsChanged,
                      ),
                    ],
                  ),
                ),
                Container(width: 1, color: AppColors.border),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(9, 16, 16, 24),
                    children: [
                      ParametersCard(result: _result),
                      const SizedBox(height: 14),
                      SpectrumChart(result: _result),
                      const SizedBox(height: 14),
                      if (_factors.comparisonMode.isActive) ...[
                        ComparisonGrid(result: _result),
                        const SizedBox(height: 14),
                      ],
                      DataTableView(result: _result),
                    ],
                  ),
                ),
              ],
            );
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _locationCard(mapHeight: 240),
              const SizedBox(height: 12),
              ParametersCard(result: _result),
              const SizedBox(height: 12),
              SpectrumChart(result: _result),
              const SizedBox(height: 12),
              FactorsPanel(
                factors: _factors,
                onFactorsChanged: _onFactorsChanged,
              ),
              const SizedBox(height: 12),
              if (_factors.comparisonMode.isActive) ...[
                ComparisonGrid(result: _result),
                const SizedBox(height: 12),
              ],
              DataTableView(result: _result),
            ],
          );
        },
      ),
    );
  }

  Widget _locationCard({required double mapHeight}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              icon: Icons.map_outlined,
              title: 'Ubicación Geográfica',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.chipBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentLat.toStringAsFixed(4)}, ${_currentLon.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: mapHeight,
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
            const SizedBox(height: 12),
            LocationSelector(
              currentLat: _currentLat,
              currentLon: _currentLon,
              mode: _coordMode,
              onModeChanged: (m) => setState(() => _coordMode = m),
              puntoEnabled: _puntoEnabled,
              onPuntoChanged: (v) => setState(() => _puntoEnabled = v),
              onLocationChanged: _onCoordinatesChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBarDivider extends StatelessWidget {
  const _AppBarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.white24,
    );
  }
}
