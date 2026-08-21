import 'package:flutter/material.dart';
import '../../models/epoch.dart';
import '../../models/seismic_models.dart';
import '../theme/app_theme.dart';
import 'section_header.dart';

class FactorsPanel extends StatelessWidget {
  final SeismicFactors factors;
  final Function(SeismicFactors updated) onFactorsChanged;
  const FactorsPanel({
    super.key,
    required this.factors,
    required this.onFactorsChanged,
  });
  bool get _locked => factors.comparisonMode.isActive;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              icon: Icons.tune,
              title: 'Factores Sísmicos Estructurales',
            ),
            const SizedBox(height: 14),
            _sectionLabel('PARÁMETROS ESTRUCTURALES'),
            const SizedBox(height: 8),
            _dropdownRow<ImportanceGroup>(
              label: '1. Grupo de Importancia',
              value: factors.importanceGroup,
              items: ImportanceGroup.values
                  .map(
                    (g) => DropdownMenuItem(
                      value: g,
                      child: Text(
                        '${g.name} (I=${g.factor})',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _locked
                  ? null
                  : (v) {
                      if (v != null)
                        onFactorsChanged(factors.copyWith(importanceGroup: v));
                    },
            ),
            const SizedBox(height: 10),
            _dropdownRow<double>(
              label: '2. Factor Q',
              value: factors.q,
              items: [1.0, 1.5, 2.0, 3.0, 4.0]
                  .map(
                    (q) => DropdownMenuItem(
                      value: q,
                      child: Text(
                        'Q = $q',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onFactorsChanged(factors.copyWith(q: v));
              },
            ),
            const SizedBox(height: 10),
            _dropdownRow<IrregularityFactor>(
              label: factors.norm == NormVersion.ntc2016
                  ? '3. Irregularidad α'
                  : "3. Irregularidad (corrección Q')",
              value:
                  IrregularityFactor.optionsFor(
                    factors.norm,
                  ).contains(factors.irregularity)
                  ? factors.irregularity
                  : IrregularityFactor.regular,
              items: IrregularityFactor.optionsFor(factors.norm)
                  .map(
                    (irr) => DropdownMenuItem(
                      value: irr,
                      child: Text(
                        irr.name,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _locked
                  ? null
                  : (v) {
                      if (v != null)
                        onFactorsChanged(factors.copyWith(irregularity: v));
                    },
            ),
            const SizedBox(height: 10),
            _dropdownRow<double>(
              label: '4. Hiperestaticidad k1',
              value: factors.k1,
              items: [0.8, 1.0, 1.25]
                  .map(
                    (k) => DropdownMenuItem(
                      value: k,
                      child: Text(
                        'k1 = $k',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _locked
                  ? null
                  : (v) {
                      if (v != null) onFactorsChanged(factors.copyWith(k1: v));
                    },
            ),
            if (_locked) ...[
              const SizedBox(height: 10),
              const InfoBanner(
                icon: Icons.lock_outline,
                message:
                    'Comparación activa: Grupo / α / k1 bloqueados (=1.0), como en SASID original §3.3c',
              ),
            ],
            const SizedBox(height: 14),
            _sectionLabel('NORMATIVA Y ESPECTRO'),
            const SizedBox(height: 8),
            _dropdownRow<NormVersion>(
              label: 'Norma',
              value: factors.norm,
              items: NormVersion.values
                  .map(
                    (n) => DropdownMenuItem(
                      value: n,
                      child: Text(
                        n.label,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onFactorsChanged(factors.copyWith(norm: v));
              },
            ),
            if (factors.norm == NormVersion.ntc2023) ...[
              const SizedBox(height: 10),
              _dropdownRow<PerformanceLevel>(
                label: 'Nivel de desempeño',
                value: factors.performanceLevel,
                items: PerformanceLevel.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          p.label,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    onFactorsChanged(factors.copyWith(performanceLevel: v));
                  }
                },
              ),
            ],
            if (factors.norm == NormVersion.ntc2023 &&
                factors.performanceLevel == PerformanceLevel.ocupacionInmediata)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: InfoBanner(
                  icon: Icons.info_outline,
                  message: 'Ocupación Inmediata: Q = 1 según numeral 3.2',
                ),
              ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    size: 16,
                    color: factors.showEpu
                        ? AppColors.spectrumEpu
                        : AppColors.textFaint,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Mostrar EPU',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  Switch(
                    value: factors.showEpu,
                    activeThumbColor: AppColors.accent,
                    onChanged: (v) =>
                        onFactorsChanged(factors.copyWith(showEpu: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _dropdownRow(
              label: 'Tr (EPU)',
              value: factors.returnPeriod,
              items: ReturnPeriod.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        r.label,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null)
                  onFactorsChanged(factors.copyWith(returnPeriod: v));
              },
            ),
            const SizedBox(height: 10),
            _dropdownRow(
              label: 'Época / Malla',
              value: factors.epoch,
              items: Epoch.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        '${e.label} (${e.hexCode})',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onFactorsChanged(factors.copyWith(epoch: v));
              },
            ),
            const SizedBox(height: 10),
            _dropdownRow(
              label: 'Comparación NTC 2004',
              value: factors.comparisonMode,
              items: ComparisonMode.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c.label,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                final locked = v.isActive
                    ? factors.withComparisonLocked().copyWith(
                        comparisonMode: v,
                        showComparison2004: v.isActive,
                      )
                    : factors.copyWith(
                        comparisonMode: v,
                        showComparison2004: false,
                      );
                onFactorsChanged(locked);
              },
            ),
            const SizedBox(height: 10),
            _dropdownRow(
              label: 'Exportar espectro',
              value: factors.exportSpectrumType,
              items: SpectrumType.values
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.label,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null)
                  onFactorsChanged(factors.copyWith(exportSpectrumType: v));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: AppColors.textFaint,
      ),
    );
  }

  Widget _dropdownRow<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    final disabled = onChanged == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: disabled ? AppColors.chipBg : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: disabled ? AppColors.border : AppColors.borderStrong,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: disabled ? AppColors.textFaint : AppColors.accent,
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(10),
              elevation: 8,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
