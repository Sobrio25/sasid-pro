import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/epoch.dart';
import '../../models/seismic_models.dart';
import '../theme/app_theme.dart';
import 'section_header.dart';

class DataTableView extends StatefulWidget {
  final SpectrumResult result;
  const DataTableView({super.key, required this.result});
  @override
  State<DataTableView> createState() => _DataTableViewState();
}

class _DataTableViewState extends State<DataTableView> {
  SpectrumType _view = SpectrumType.design;

  Color get _viewColor {
    switch (_view) {
      case SpectrumType.elastic:
        return AppColors.spectrumElastic;
      case SpectrumType.epu:
        return AppColors.spectrumEpu;
      case SpectrumType.design:
        return AppColors.spectrumDesign;
    }
  }

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
            SectionHeader(
              icon: Icons.table_chart_outlined,
              title: 'Tabla de Valores Tabulados',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<SpectrumType>(
                    segments: SpectrumType.values
                        .map(
                          (s) => ButtonSegment(value: s, label: Text(s.label)),
                        )
                        .toList(),
                    selected: {_view},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) =>
                        setState(() => _view = selection.first),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: const Text('Copiar', style: TextStyle(fontSize: 12)),
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
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.chipBg,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(9),
                        topRight: Radius.circular(9),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PERIODO T',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          'Sa ${_view.label.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: _viewColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: pts.length,
                      itemBuilder: (c, i) {
                        final pt = pts[i];
                        final ptD = widget.result.designSpectrum[i];
                        final ptE = widget.result.elasticSpectrum[i];
                        final isEven = i.isEven;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          color: isEven
                              ? Colors.transparent
                              : AppColors.surface.withValues(alpha: 0.7),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${pt.period.toStringAsFixed(3)} s',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  color: AppColors.textMain,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    pt.acceleration.toStringAsFixed(4),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                      color: _viewColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (_view != SpectrumType.design)
                                    Text(
                                      'd ${ptD.acceleration.toStringAsFixed(4)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                        color: AppColors.textFaint,
                                      ),
                                    ),
                                  if (_view != SpectrumType.design)
                                    const SizedBox(width: 8),
                                  if (_view != SpectrumType.elastic)
                                    Text(
                                      'e ${ptE.acceleration.toStringAsFixed(4)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                        color: AppColors.textFaint,
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
            const SizedBox(height: 8),
            Text(
              'Mostrando: ${_view.label} · Tr ${widget.result.factors.returnPeriod.label} · ${pts.length} puntos',
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
