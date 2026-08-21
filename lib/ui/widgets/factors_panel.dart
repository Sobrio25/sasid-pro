import 'package:flutter/material.dart';
import '../../models/epoch.dart';
import '../../models/seismic_models.dart';
import '../theme/app_theme.dart';

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
            const Row(
              children: [
                Icon(Icons.tune, size: 18, color: AppColors.accent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Factores Sísmicos Estructurales',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _dropdownRow<ImportanceGroup>(
              label: '1. Grupo de Importancia:',
              value: factors.importanceGroup,
              items: ImportanceGroup.values
                  .map(
                    (g) => DropdownMenuItem(
                      value: g,
                      child: Text(
                        '${g.name} (I=${g.factor})',
                        style: const TextStyle(fontSize: 12),
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
            const SizedBox(height: 8),
            _dropdownRow<double>(
              label: '2. Factor Q:',
              value: factors.q,
              items: [1.0, 1.5, 2.0, 3.0, 4.0]
                  .map(
                    (q) => DropdownMenuItem(
                      value: q,
                      child: Text(
                        'Q = $q',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onFactorsChanged(factors.copyWith(q: v));
              },
            ),
            const SizedBox(height: 8),
            _dropdownRow<IrregularityFactor>(
              label: '3. Irregularidad α:',
              value: factors.irregularity,
              items: IrregularityFactor.values
                  .map(
                    (irr) => DropdownMenuItem(
                      value: irr,
                      child: Text(
                        irr.name,
                        style: const TextStyle(fontSize: 12),
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
            const SizedBox(height: 8),
            _dropdownRow<double>(
              label: '4. Hiperestaticidad k1:',
              value: factors.k1,
              items: [0.8, 1.0, 1.25]
                  .map(
                    (k) => DropdownMenuItem(
                      value: k,
                      child: Text(
                        'k1 = $k',
                        style: const TextStyle(fontSize: 12),
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
            if (_locked)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Comparación activa: Grupo/α/k1 bloqueados (=1.0) como en SASID original §3.3c',
                  style: TextStyle(fontSize: 10, color: Colors.orange),
                ),
              ),
            const Divider(height: 16),
            _dropdownRow<NormVersion>(
              label: 'Norma:',
              value: factors.norm,
              items: NormVersion.values
                  .map(
                    (n) => DropdownMenuItem(
                      value: n,
                      child: Text(
                        n.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onFactorsChanged(factors.copyWith(norm: v));
              },
            ),
            if (factors.norm == NormVersion.ntc2023)
              _dropdownRow<PerformanceLevel>(
                label: 'Nivel de desempeño:',
                value: factors.performanceLevel,
                items: PerformanceLevel.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          p.label,
                          style: const TextStyle(fontSize: 12),
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
            if (factors.norm == NormVersion.ntc2023 &&
                factors.performanceLevel == PerformanceLevel.ocupacionInmediata)
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  'Ocupación Inmediata: Q = 1 según numeral 3.2',
                  style: TextStyle(fontSize: 10, color: Colors.orange),
                ),
              ),
            SwitchListTile(
              title: const Text(
                'Mostrar EPU',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              value: factors.showEpu,
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.accent,
              onChanged: (v) => onFactorsChanged(factors.copyWith(showEpu: v)),
            ),
            _dropdownRow(
              label: 'Tr (EPU):',
              value: factors.returnPeriod,
              items: ReturnPeriod.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        r.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null)
                  onFactorsChanged(factors.copyWith(returnPeriod: v));
              },
            ),
            _dropdownRow(
              label: 'Época/Malla:',
              value: factors.epoch,
              items: Epoch.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        '${e.label} (${e.hexCode})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onFactorsChanged(factors.copyWith(epoch: v));
              },
            ),
            _dropdownRow(
              label: 'Comparación NTC 2004:',
              value: factors.comparisonMode,
              items: ComparisonMode.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c.label,
                        style: const TextStyle(fontSize: 12),
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
            _dropdownRow(
              label: 'Exportar espectro:',
              value: factors.exportSpectrumType,
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
                if (v != null)
                  onFactorsChanged(factors.copyWith(exportSpectrumType: v));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownRow<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
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
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: onChanged == null ? const Color(0xFFF1F5F9) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
