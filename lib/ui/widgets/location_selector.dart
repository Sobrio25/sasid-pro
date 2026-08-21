import 'package:flutter/material.dart';
import '../../models/cdmx_preset.dart';
import '../../services/geocoding_service.dart';
import '../theme/app_theme.dart';

class LocationSelector extends StatefulWidget {
  final double currentLat;
  final double currentLon;
  final Function(double lat, double lon) onLocationChanged;

  const LocationSelector({
    super.key,
    required this.currentLat,
    required this.currentLon,
    required this.onLocationChanged,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  final TextEditingController _searchController = TextEditingController();

  List<GeocodingSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _latController = TextEditingController(text: widget.currentLat.toStringAsFixed(6));
    _lonController = TextEditingController(text: widget.currentLon.toStringAsFixed(6));
  }

  @override
  void didUpdateWidget(covariant LocationSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLat != widget.currentLat) {
      _latController.text = widget.currentLat.toStringAsFixed(6);
    }
    if (oldWidget.currentLon != widget.currentLon) {
      _lonController.text = widget.currentLon.toStringAsFixed(6);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyManualCoords() {
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());
    if (lat != null && lon != null) {
      widget.onLocationChanged(lat, lon);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await GeocodingService.searchAddress(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 3),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Coordenadas'),
              Tab(text: 'Buscar Dirección / Sitios'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Vista 1: Entrada manual de coordenadas
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: const InputDecoration(
                            labelText: 'Latitud (°)',
                            prefixIcon: Icon(Icons.north, size: 16),
                          ),
                          onSubmitted: (_) => _applyManualCoords(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _lonController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: const InputDecoration(
                            labelText: 'Longitud (°)',
                            prefixIcon: Icon(Icons.west, size: 16),
                          ),
                          onSubmitted: (_) => _applyManualCoords(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _applyManualCoords,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Actualizar Espectro'),
                    ),
                  ),
                ],
              ),

              // Vista 2: Buscador por dirección o catálogo de sitios
              Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar colonia, calle o sitio en CDMX...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _isSearching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: Padding(
                                padding: EdgeInsets.all(10.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchResults = []);
                                  },
                                )
                              : null,
                    ),
                    onChanged: _performSearch,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: _searchResults.isEmpty
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: CdmxPresets.landmarks.length,
                            itemBuilder: (context, index) {
                              final p = CdmxPresets.landmarks[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: ActionChip(
                                  label: Text(p.name, style: const TextStyle(fontSize: 11)),
                                  avatar: const Icon(Icons.place, size: 14, color: AppColors.accent),
                                  onPressed: () => widget.onLocationChanged(p.latitude, p.longitude),
                                ),
                              );
                            },
                          )
                        : ListView.separated(
                            itemCount: _searchResults.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _searchResults[index];
                              return ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                leading: const Icon(Icons.location_on, size: 18, color: AppColors.accent),
                                title: Text(item.displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(item.source, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                onTap: () {
                                  widget.onLocationChanged(item.latitude, item.longitude);
                                  setState(() => _searchResults = []);
                                  _searchController.text = item.displayName;
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
