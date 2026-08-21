import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 1. Grupo de Importancia
            _dropdownRow(
              label: '1. Grupo de Importancia:',
              value: factors.importanceGroup,
              items: ImportanceGroup.values.map((g) {
                return DropdownMenuItem(
                  value: g,
                  child: Text('${g.name} (I = ${g.factor})', style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onFactorsChanged(factors.copyWith(importanceGroup: val));
              },
            ),
            const SizedBox(height: 8),

            // 2. Factor de Comportamiento Sísmico Q
            _dropdownRow(
              label: '2. Factor de Comportamiento Sísmico (Q):',
              value: factors.q,
              items: [1.0, 1.5, 2.0, 3.0, 4.0].map((qVal) {
                return DropdownMenuItem(
                  value: qVal,
                  child: Text('Q = $qVal', style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onFactorsChanged(factors.copyWith(q: val));
              },
            ),
            const SizedBox(height: 8),

            // 3. Factor de Irregularidad
            _dropdownRow(
              label: '3. Factor de Irregularidad (α):',
              value: factors.irregularity,
              items: IrregularityFactor.values.map((irr) {
                return DropdownMenuItem(
                  value: irr,
                  child: Text(irr.name, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onFactorsChanged(factors.copyWith(irregularity: val));
              },
            ),
            const SizedBox(height: 8),

            // 4. Factor de Hiperestaticidad k1
            _dropdownRow(
              label: '4. Factor de Hiperestaticidad (k1):',
              value: factors.k1,
              items: [0.8, 1.0, 1.25].map((kVal) {
                return DropdownMenuItem(
                  value: kVal,
                  child: Text('k1 = $kVal', style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onFactorsChanged(factors.copyWith(k1: val));
              },
            ),
            const Divider(height: 16),

            // Opciones avanzadas: EPU y Comparación 2004 con switches compactos
            SwitchListTile(
              title: const Text('Mostrar EPU (Peligro Uniforme)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              value: factors.showEpu,
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.accent,
              onChanged: (val) => onFactorsChanged(factors.copyWith(showEpu: val)),
            ),
            SwitchListTile(
              title: const Text('Modo Comparación NTC 2004', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              value: factors.showComparison2004,
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.accent,
              onChanged: (val) => onFactorsChanged(factors.copyWith(showComparison2004: val)),
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
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
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
