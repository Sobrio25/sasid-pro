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
  final TextEditingController _searchController = TextEditingController();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: CoordinateMode.values
                .map(
                  (m) => Expanded(
                    child: InkWell(
                      onTap: () => widget.onModeChanged(m),
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.mode == m
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          m.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: widget.mode == m
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: widget.mode == m
                                ? AppColors.accent
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 10),
        if (widget.mode == CoordinateMode.punto)
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => widget.onPuntoChanged(!widget.puntoEnabled),
                icon: Icon(
                  widget.puntoEnabled ? Icons.location_on : Icons.location_off,
                  size: 16,
                ),
                label: Text(
                  widget.puntoEnabled ? 'Desactivar punto' : 'Activar punto',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.puntoEnabled
                    ? 'Clic en el mapa para seleccionar'
                    : 'Punto desactivado',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        if (widget.mode == CoordinateMode.coordenada)
          Column(
            children: [
              Row(
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
                    icon: Icon(_expanded ? Icons.remove : Icons.add),
                    tooltip: _expanded ? 'Contraer' : 'Expandir',
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!_expanded)
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _copyBoth,
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text(
                        'Copiar ambas',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pasteBoth,
                      icon: const Icon(Icons.paste, size: 14),
                      label: const Text(
                        'Pegar ambas',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              if (_expanded)
                Text(
                  'Pegar lat\\tlon desde Excel con tabulación',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _apply,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Cambiar'),
                ),
              ),
            ],
          ),
        if (widget.mode == CoordinateMode.direccion)
          Column(
            children: [
              DropdownButtonFormField<String>(
                value: _municipio.text.isEmpty ? null : _municipio.text,
                decoration: const InputDecoration(
                  labelText: 'Municipio/Alcaldía',
                ),
                items: CdmxPresets.alcaldias
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.name,
                        child: Text(a.name, style: TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  _municipio.text = v ?? '';
                },
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _calle,
                      decoration: const InputDecoration(labelText: 'Calle'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _numero,
                      decoration: const InputDecoration(labelText: 'Número'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _colonia,
                      decoration: const InputDecoration(labelText: 'Colonia'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _cp,
                      decoration: const InputDecoration(labelText: 'CP'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                      : const Icon(Icons.search, size: 16),
                  label: const Text('Buscar'),
                ),
              ),
              if (_results.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (c, i) {
                      final it = _results[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          it.displayName,
                          style: const TextStyle(fontSize: 11),
                          maxLines: 2,
                        ),
                        subtitle: Text(
                          it.source,
                          style: const TextStyle(fontSize: 10),
                        ),
                        onTap: () =>
                            widget.onLocationChanged(it.latitude, it.longitude),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
