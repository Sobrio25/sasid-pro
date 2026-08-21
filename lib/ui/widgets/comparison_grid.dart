import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/seismic_models.dart';
import '../theme/app_theme.dart';
import 'section_header.dart';

class ComparisonGrid extends StatelessWidget {
  final SpectrumResult result;

  const ComparisonGrid({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (!result.factors.showComparison2004 || result.qComparisons == null) {
      return const SizedBox.shrink();
    }

    final qValues = [1.5, 2.0, 3.0, 4.0];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              icon: Icons.compare_arrows,
              title: 'Comparación Multicriterio NTC 2017/2023 vs NTC 2004',
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 650;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 2 : 1,
                    childAspectRatio: isWide ? 1.6 : 1.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: qValues.length,
                  itemBuilder: (context, index) {
                    final q = qValues[index];
                    final designPts = result.qComparisons![q] ?? [];
                    return _miniComparisonChart(
                      q,
                      designPts,
                      result.ntc2004MainSpectrum ?? [],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniComparisonChart(
    double qVal,
    List<SpectrumPoint> design,
    List<SpectrumPoint> ntc2004,
  ) {
    final designSpots = design
        .map((p) => FlSpot(p.period, p.acceleration))
        .toList();
    final ntcSpots = ntc2004
        .map((p) => FlSpot(p.period, p.acceleration))
        .toList();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Q = $qVal',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Variación NTC',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0.0,
                maxX: 5.0,
                minY: 0.0,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 0.2,
                  verticalInterval: 1.0,
                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: AppColors.border, strokeWidth: 1),
                  getDrawingVerticalLine: (value) =>
                      const FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      interval: 1.0,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 0.2,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppColors.borderStrong),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: designSpots,
                    isCurved: true,
                    color: AppColors.spectrumDesign,
                    barWidth: 2.0,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: ntcSpots,
                    isCurved: true,
                    color: AppColors.spectrumNtc2004,
                    barWidth: 1.5,
                    dashArray: [4, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
