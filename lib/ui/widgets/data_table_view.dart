import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/epoch.dart';
import '../../models/seismic_models.dart';
import '../theme/app_theme.dart';

class DataTableView extends StatefulWidget {
  final SpectrumResult result;
  const DataTableView({super.key, required this.result});
  @override
  State<DataTableView> createState() => _DataTableViewState();
}

class _DataTableViewState extends State<DataTableView> {
  SpectrumType _view = SpectrumType.design;
  @override
  Widget build(BuildContext context) {
    List<SpectrumPoint> pts;
    switch (_view) {
      case SpectrumType.elastic:
        pts = widget.result.elasticSpectrum;
        break;
      case SpectrumType.epu:
        pts = widget.result.epuSpectrum;
        break;
      case SpectrumType.design:
        pts = widget.result.designSpectrum;
        break;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.table_chart_outlined,
                      size: 20,
                      color: AppColors.accent,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Tabla de Valores Tabulados',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                  ],
                ),
                DropdownButton<SpectrumType>(
                  value: _view,
                  items: SpectrumType.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s.label,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _view = v);
                  },
                ),
              ],
            ),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copiar Tabla'),
                  onPressed: () {
                    final buf = StringBuffer(
                      'Periodo (s)\tSa ${_view.label} (g)\n',
                    );
                    for (final p in pts)
                      buf.writeln(
                        '${p.period.toStringAsFixed(4)}\t${p.acceleration.toStringAsFixed(6)}',
                      );
                    Clipboard.setData(ClipboardData(text: buf.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tabla copiada')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'Mostrando: ${_view.label} | Tr ${widget.result.factors.returnPeriod.label}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                itemCount: pts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (c, i) {
                  final pt = pts[i];
                  final ptD = widget.result.designSpectrum[i];
                  final ptE = widget.result.elasticSpectrum[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'T = ${pt.period.toStringAsFixed(3)} s',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Sa: ${pt.acceleration.toStringAsFixed(4)} g',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _view == SpectrumType.design
                                    ? AppColors.spectrumDesign
                                    : _view == SpectrumType.elastic
                                    ? AppColors.spectrumElastic
                                    : AppColors.spectrumEpu,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (_view != SpectrumType.design)
                              Text(
                                'Sa_d: ${ptD.acceleration.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            if (_view != SpectrumType.elastic)
                              Text(
                                ' Sa_e: ${ptE.acceleration.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
