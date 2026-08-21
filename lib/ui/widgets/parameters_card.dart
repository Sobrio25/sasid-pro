import 'package:flutter/material.dart';
import '../../models/seismic_models.dart';
import '../theme/app_theme.dart';

class ParametersCard extends StatelessWidget {
  final SpectrumResult result;

  const ParametersCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final site = result.site;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics_outlined, size: 20, color: AppColors.accent),
                    SizedBox(width: 8),
                    Text(
                      'Parámetros Espectrales NTC',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMain),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: site.zone.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: site.zone.color.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: site.zone.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        site.zone.name,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: site.zone.color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _paramChip('Ts (suelo)', '${site.ts.toStringAsFixed(3)} s', 'Periodo dominante del terreno', Colors.indigo),
                _paramChip('a0 (PGA)', '${site.a0.toStringAsFixed(3)} g', 'Aceleración pico del terreno', Colors.deepOrange),
                _paramChip('c (coef.)', site.c.toStringAsFixed(3), 'Coeficiente sísmico elástico', Colors.teal),
                _paramChip('Ta (inicio)', '${site.ta.toStringAsFixed(3)} s', 'Límite inferior de la meseta', Colors.purple),
                _paramChip('Tb (fin)', '${site.tb.toStringAsFixed(3)} s', 'Límite superior de la meseta', Colors.deepPurple),
                _paramChip('k (relación)', site.k.toStringAsFixed(3), 'Exponente de decaimiento', Colors.blueGrey),
                _paramChip('a_máx diseño', '${result.aMaxDesign.toStringAsFixed(4)} g', 'Ordenada espectral máxima reducida', AppColors.accent, isHighlighted: true),
                _paramChip('R0 (sobrerr.)', result.r0.toStringAsFixed(2), 'Factor de sobrerresistencia base', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paramChip(String label, String value, String tooltip, Color color, {bool isHighlighted = false}) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isHighlighted ? color.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isHighlighted ? color : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? color : AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
