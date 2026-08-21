import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/cdmx_preset.dart';
import '../../models/epoch.dart';
import '../../services/geocoding_service.dart';
import '../theme/app_theme.dart';

class LocationSelector extends StatefulWidget {
  final double currentLat;
  final double currentLon;
  final CoordinateMode mode;
  final ValueChanged<CoordinateMode> onModeChanged;
  final bool puntoEnabled;
  final ValueChanged<bool> onPuntoChanged;
  final Function(double lat, double lon) onLocationChanged;

  const LocationSelector({
    super.key,
    required this.currentLat,
    required this.currentLon,
    required this.mode,
    required this.onModeChanged,
    required this.puntoEnabled,
    required this.onPuntoChanged,
    required this.onLocationChanged,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  late TextEditingController _latController;
  late TextEditingController _lonController;
  final TextEditingController _municipio = TextEditingController();
  final TextEditingController _calle = TextEditingController();
  final TextEditingController _numero = TextEditingController();
  final TextEditingController _colonia = TextEditingController();
  final TextEditingController _cp = TextEditingController();
  bool _expanded = false;
  List<GeocodingSearchResult> _results = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(
      text: widget.currentLat.toStringAsFixed(6),
    );
    _lonController = TextEditingController(
      text: widget.currentLon.toStringAsFixed(6),
    );
  }

  @override
  void didUpdateWidget(covariant LocationSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLat != widget.currentLat)
      _latController.text = widget.currentLat.toStringAsFixed(6);
    if (oldWidget.currentLon != widget.currentLon)
      _lonController.text = widget.currentLon.toStringAsFixed(6);
  }

  void _apply() {
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());
    if (lat != null && lon != null) widget.onLocationChanged(lat, lon);
  }

  void _copyBoth() {
    Clipboard.setData(
      ClipboardData(
        text:
            '${widget.currentLat.toStringAsFixed(6)}\t${widget.currentLon.toStringAsFixed(6)}',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coordenadas copiadas (lat\\tlon)')),
    );
  }

  Future<void> _pasteBoth() async {
    final data = await Clipboard.getData('text/plain');
    final txt = data?.text ?? '';
    final parts = txt.split(RegExp(r'[\t,\s]+'));
    if (parts.length >= 2) {
      _latController.text = parts[0];
      _lonController.text = parts[1];
      _apply();
    }
  }

  Future<void> _searchDireccion() async {
    final q =
        '${_calle.text} ${_numero.text} ${_colonia.text} ${_municipio.text} ${_cp.text}'
            .trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    final r = await GeocodingService.searchAddress(q);
    setState(() {
      _results = r;
      _searching = false;
    });
  }

  IconData _iconFor(CoordinateMode m) {
    switch (m) {
      case CoordinateMode.punto:
        return Icons.ads_click;
      case CoordinateMode.coordenada:
        return Icons.gps_fixed;
      case CoordinateMode.direccion:
        return Icons.location_city;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<CoordinateMode>(
          segments: CoordinateMode.values
              .map(
                (m) => ButtonSegment(
                  value: m,
                  icon: Icon(_iconFor(m), size: 15),
                  label: Text(m.label),
                ),
              )
              .toList(),
          selected: {widget.mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              widget.onModeChanged(selection.first),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _buildModeContent(),
        ),
      ],
    );
  }

  Widget _buildModeContent() {
    switch (widget.mode) {
      case CoordinateMode.punto:
        return _puntoContent();
      case CoordinateMode.coordenada:
        return _coordenadaContent();
      case CoordinateMode.direccion:
        return _direccionContent();
    }
  }

  Widget _puntoContent() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => widget.onPuntoChanged(!widget.puntoEnabled),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.puntoEnabled
                ? AppColors.accent
                : AppColors.chipBg,
            foregroundColor: widget.puntoEnabled
                ? Colors.white
                : AppColors.textMuted,
          ),
          icon: Icon(
            widget.puntoEnabled
                ? Icons.location_on
                : Icons.location_off_outlined,
            size: 16,
          ),
          label: Text(
            widget.puntoEnabled ? 'Desactivar punto' : 'Activar punto',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.touch_app,
                size: 14,
                color: widget.puntoEnabled
                    ? AppColors.accent
                    : AppColors.textFaint,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  widget.puntoEnabled
                      ? 'Clic en el mapa para seleccionar'
                      : 'Selección en mapa desactivada',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _coordenadaContent() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _latController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Latitud (°)',
                  prefixIcon: Icon(Icons.north, size: 16),
                ),
                onSubmitted: (_) => _apply(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _lonController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Longitud (°)',
                  prefixIcon: Icon(Icons.west, size: 16),
                ),
                onSubmitted: (_) => _apply(),
              ),
            ),
            IconButton(
              icon: Icon(_expanded ? Icons.unfold_less : Icons.unfold_more),
              tooltip: _expanded ? 'Contraer opciones' : 'Más opciones',
              color: AppColors.accent,
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (!_expanded)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _copyBoth,
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text(
                  'Copiar ambas',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _pasteBoth,
                icon: const Icon(Icons.paste_rounded, size: 14),
                label: const Text(
                  'Pegar ambas',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        if (_expanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: AppColors.accent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pegue desde Excel con el formato lat\\tlon (tabulación)',
                    style: TextStyle(fontSize: 10.5, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _apply,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text(
              'Aplicar coordenadas',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _direccionContent() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _municipio.text.isEmpty ? null : _municipio.text,
          decoration: const InputDecoration(
            labelText: 'Municipio / Alcaldía',
            prefixIcon: Icon(Icons.location_city, size: 16),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.accent,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10),
          items: CdmxPresets.alcaldias
              .map(
                (a) => DropdownMenuItem(
                  value: a.name,
                  child: Text(a.name, style: const TextStyle(fontSize: 12.5)),
                ),
              )
              .toList(),
          onChanged: (v) {
            setState(() {
              _municipio.text = v ?? '';
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _calle,
                decoration: const InputDecoration(labelText: 'Calle'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _numero,
                decoration: const InputDecoration(labelText: 'Número'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _colonia,
                decoration: const InputDecoration(labelText: 'Colonia'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _cp,
                decoration: const InputDecoration(labelText: 'CP'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _searchDireccion,
            icon: _searching
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search_rounded, size: 16),
            label: const Text(
              'Buscar dirección',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              height: 132,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _results.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 36),
                itemBuilder: (c, i) {
                  final it = _results[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    title: Text(
                      it.displayName,
                      style: const TextStyle(fontSize: 11.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      it.source,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textFaint,
                      ),
                    ),
                    onTap: () =>
                        widget.onLocationChanged(it.latitude, it.longitude),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
