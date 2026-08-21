import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/seismic_models.dart';
import '../theme/app_theme.dart';

class SpectrumChart extends StatefulWidget {
  final SpectrumResult result;

  const SpectrumChart({super.key, required this.result});

  @override
  State<SpectrumChart> createState() => _SpectrumChartState();
}

class _SpectrumChartState extends State<SpectrumChart> {
  bool _showDesign = true;
  bool _showElastic = true;
  bool _showEpu = true;
  bool _showNtc2004 = true;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    final designSpots = result.designSpectrum.map((p) => FlSpot(p.period, p.acceleration)).toList();
    final elasticSpots = result.elasticSpectrum.map((p) => FlSpot(p.period, p.acceleration)).toList();
    final epuSpots = result.epuSpectrum.map((p) => FlSpot(p.period, p.acceleration)).toList();

    final List<LineChartBarData> lineBars = [];

    if (_showDesign) {
      lineBars.add(
        LineChartBarData(
          spots: designSpots,
          isCurved: true,
          curveSmoothness: 0.1,
          color: AppColors.spectrumDesign,
          barWidth: 3.0,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.spectrumDesign.withValues(alpha: 0.08),
          ),
        ),
      );
    }

    if (_showElastic) {
      lineBars.add(
        LineChartBarData(
          spots: elasticSpots,
          isCurved: true,
          curveSmoothness: 0.1,
          color: AppColors.spectrumElastic,
          barWidth: 2.0,
          dashArray: [5, 4],
          dotData: const FlDotData(show: false),
        ),
      );
    }

    if (result.factors.showEpu && _showEpu) {
      lineBars.add(
        LineChartBarData(
          spots: epuSpots,
          isCurved: true,
          curveSmoothness: 0.1,
          color: AppColors.spectrumEpu,
          barWidth: 2.0,
          dashArray: [2, 2],
          dotData: const FlDotData(show: false),
        ),
      );
    }

    if (result.factors.showComparison2004 && result.ntc2004MainSpectrum != null && _showNtc2004) {
      final ntc2004Spots = result.ntc2004MainSpectrum!.map((p) => FlSpot(p.period, p.acceleration)).toList();
      lineBars.add(
        LineChartBarData(
          spots: ntc2004Spots,
          isCurved: true,
          curveSmoothness: 0.1,
          color: AppColors.spectrumNtc2004,
          barWidth: 2.0,
          dashArray: [6, 6],
          dotData: const FlDotData(show: false),
        ),
      );
    }

    double maxY = result.elasticSpectrum.map((p) => p.acceleration).reduce((a, b) => a > b ? a : b);
    if (result.factors.showEpu) maxY *= 1.15;
    maxY = ((maxY * 1.15) * 10).ceil() / 10.0;
    if (maxY < 0.5) maxY = 0.5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, size: 20, color: AppColors.accent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Espectro de Respuesta Sísmica (Sa vs T)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMain),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'T ∈ [0.0, 5.0 s]',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _legendToggle(
                  label: 'E. Diseño 2017/2023',
                  color: AppColors.spectrumDesign,
                  value: _showDesign,
                  onChanged: (v) => setState(() => _showDesign = v),
                ),
                _legendToggle(
                  label: 'E. Elástico',
                  color: AppColors.spectrumElastic,
                  value: _showElastic,
                  onChanged: (v) => setState(() => _showElastic = v),
                  isDashed: true,
                ),
                if (result.factors.showEpu)
                  _legendToggle(
                    label: 'EPU (Peligro Uniforme)',
                    color: AppColors.spectrumEpu,
                    value: _showEpu,
                    onChanged: (v) => setState(() => _showEpu = v),
                    isDashed: true,
                  ),
                if (result.factors.showComparison2004)
                  _legendToggle(
                    label: 'NTC 2004 Zonas',
                    color: AppColors.spectrumNtc2004,
                    value: _showNtc2004,
                    onChanged: (v) => setState(() => _showNtc2004 = v),
                    isDashed: true,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 320,
              child: LineChart(
                LineChartData(
                  minX: 0.0,
                  maxX: 5.0,
                  minY: 0.0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: maxY / 5,
                    verticalInterval: 0.5,
                    getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.border, strokeWidth: 0.8),
                    getDrawingVerticalLine: (value) => const FlLine(color: AppColors.border, strokeWidth: 0.8),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('Periodo Estructural T (segundos)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        interval: 0.5,
                        getTitlesWidget: (value, meta) => Text('${value.toStringAsFixed(1)}s', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text('Aceleración Espectral Sa (g)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: maxY / 5,
                        getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: AppColors.border),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            'T: ${spot.x.toStringAsFixed(2)} s\nSa: ${spot.y.toStringAsFixed(4)} g',
                            const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: lineBars,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendToggle({
    required String label,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isDashed = false,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: value ? color : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: value ? FontWeight.bold : FontWeight.normal,
                color: value ? AppColors.textMain : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
