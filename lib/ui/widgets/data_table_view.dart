import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/seismic_models.dart';
import '../theme/app_theme.dart';

class DataTableView extends StatelessWidget {
  final SpectrumResult result;

  const DataTableView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
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
                    Icon(Icons.table_chart_outlined, size: 20, color: AppColors.accent),
                    SizedBox(width: 8),
                    Text(
                      'Tabla de Valores Tabulados',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMain),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copiar Tabla'),
                  onPressed: () {
                    final buffer = StringBuffer('Periodo (s)\tSa Diseño (g)\tSa Elástico (g)\n');
                    for (int i = 0; i < result.designSpectrum.length; i++) {
                      buffer.writeln('${result.designSpectrum[i].period}\t${result.designSpectrum[i].acceleration}\t${result.elasticSpectrum[i].acceleration}');
                    }
                    Clipboard.setData(ClipboardData(text: buffer.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tabla copiada al portapapeles con formato tabular.')),
                    );
                  },
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
                itemCount: result.designSpectrum.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final ptD = result.designSpectrum[index];
                  final ptE = result.elasticSpectrum[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('T = ${ptD.period.toStringAsFixed(3)} s', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                        Row(
                          children: [
                            Text('Sa_d: ${ptD.acceleration.toStringAsFixed(4)} g', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.spectrumDesign)),
                            const SizedBox(width: 16),
                            Text('Sa_e: ${ptE.acceleration.toStringAsFixed(4)} g', style: const TextStyle(fontSize: 12, color: AppColors.spectrumElastic)),
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
