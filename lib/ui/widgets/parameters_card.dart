import 'package:flutter/material.dart';
import '../../models/epoch.dart';
import '../../models/seismic_models.dart';
import '../theme/app_theme.dart';
import 'section_header.dart';

class ParametersCard extends StatelessWidget {
  final SpectrumResult result;

  const ParametersCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final site = result.site;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              icon: Icons.analytics_outlined,
              title: 'Parámetros Espectrales NTC',
              trailing: _zoneBadge(result),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _paramTile(
                  'Ts (suelo)',
                  '${site.ts.toStringAsFixed(3)} s',
                  'Periodo dominante del terreno',
                  Colors.indigo,
                ),
                _paramTile(
                  'a0 (PGA)',
                  '${site.a0.toStringAsFixed(3)} g',
                  'Aceleración pico del terreno',
                  Colors.deepOrange,
                ),
                _paramTile(
                  'c (coef.)',
                  site.c.toStringAsFixed(3),
                  'Coeficiente sísmico elástico',
                  Colors.teal,
                ),
                _paramTile(
                  'Ta (inicio)',
                  '${site.ta.toStringAsFixed(3)} s',
                  'Límite inferior de la meseta',
                  Colors.purple,
                ),
                _paramTile(
                  'Tb (fin)',
                  '${site.tb.toStringAsFixed(3)} s',
                  'Límite superior de la meseta',
                  Colors.deepPurple,
                ),
                _paramTile(
                  'k (relación)',
                  site.k.toStringAsFixed(3),
                  'Exponente de decaimiento',
                  Colors.blueGrey,
                ),
                _paramTile(
                  'a_máx diseño',
                  '${result.aMaxDesign.toStringAsFixed(4)} g',
                  'Ordenada espectral máxima reducida',
                  AppColors.accent,
                  isHighlighted: true,
                ),
                _paramTile(
                  'R (sobrerr.)',
                  result.r0.toStringAsFixed(2),
                  result.factors.norm == NormVersion.ntc2016
                      ? 'Sobrerresistencia fija del SASID 2016'
                      : 'R = k1·R0 + k2 en meseta (k2 = 0)',
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoneBadge(SpectrumResult result) {
    return Tooltip(
      message: result.site.zone.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: result.site.zone.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: result.site.zone.color.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: result.site.zone.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: result.site.zone.color.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              result.factors.norm == NormVersion.ntc2023
                  ? '${result.site.zone2023} · ${result.site.zone.shortName}'
                  : result.site.zone.name,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: result.site.zone.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paramTile(
    String label,
    String value,
    String tooltip,
    Color color, {
    bool isHighlighted = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.infoBg : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isHighlighted
                ? AppColors.accent.withValues(alpha: 0.45)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isHighlighted ? AppColors.accent : AppColors.textMain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
