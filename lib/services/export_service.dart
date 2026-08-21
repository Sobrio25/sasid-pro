import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/seismic_models.dart';

class ExportService {
  /// Genera archivo .TXT con formato estándar para SAP2000, ETABS, etc.
  static String generateSap2000Txt(SpectrumResult result, {String projectName = 'Proyecto Estructural'}) {
    final sb = StringBuffer();
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    sb.writeln(r'$ =================================================================');
    sb.writeln(r'$ ESPECTRO DE DISEÑO SÍSMICO - NTC CDMX (SASID)');
    sb.writeln(r'$ =================================================================');
    sb.writeln(r'$ Proyecto: ' '$projectName');
    sb.writeln(r'$ Fecha de Generación: ' '$now');
    sb.writeln(r'$ Software: SASID Flutter Pro v4.0');
    sb.writeln(r'$ -----------------------------------------------------------------');
    sb.writeln(r'$ PARÁMETROS GEOGRÁFICOS Y GEOTÉCNICOS:');
    sb.writeln(r'$ Latitud: ' '${result.site.latitude.toStringAsFixed(6)}');
    sb.writeln(r'$ Longitud: ' '${result.site.longitude.toStringAsFixed(6)}');
    sb.writeln(r'$ Zona Geotécnica: ' '${result.site.zone.name}');
    sb.writeln(r'$ Periodo del Suelo (Ts): ' '${result.site.ts.toStringAsFixed(3)} s');
    sb.writeln(r'$ Aceleración del Terreno (a0): ' '${result.site.a0.toStringAsFixed(3)} g');
    sb.writeln(r'$ Coeficiente Sísmico (c): ' '${result.site.c.toStringAsFixed(3)}');
    sb.writeln(r'$ Periodos Meseta (Ta - Tb): ' '${result.site.ta.toStringAsFixed(3)} s - ${result.site.tb.toStringAsFixed(3)} s');
    sb.writeln(r'$ Exponente k: ' '${result.site.k.toStringAsFixed(3)}');
    sb.writeln(r'$ -----------------------------------------------------------------');
    sb.writeln(r'$ FACTORES SÍSMICOS DE ESTRUCTURA:');
    sb.writeln(r'$ Grupo de Importancia: ' '${result.factors.importanceGroup.name} (I = ${result.factors.importanceGroup.factor})');
    sb.writeln(r'$ Factor Comportamiento Sísmico (Q): ' '${result.factors.q}');
    sb.writeln(r'$ Factor Irregularidad (alpha): ' '${result.factors.irregularity.factor}');
    sb.writeln(r'$ Factor Hiperestaticidad (k1): ' '${result.factors.k1}');
    sb.writeln(r'$ Factor Sobrerresistencia Base (R0): ' '${result.r0}');
    sb.writeln(r'$ Aceleración Máxima de Diseño (aMax): ' '${result.aMaxDesign.toStringAsFixed(4)} g');
    sb.writeln(r'$ =================================================================');
    sb.writeln(r'$ TABLA DE ESPECTRO DE DISEÑO: [Periodo (s)] \t [Aceleración Sa (g)]');
    sb.writeln(r'$ =================================================================');

    for (final pt in result.designSpectrum) {
      sb.writeln('${pt.period.toStringAsFixed(4)}\t${pt.acceleration.toStringAsFixed(6)}');
    }

    return sb.toString();
  }

  /// Genera archivo .CSV compatible con Microsoft Excel
  static String generateCsv(SpectrumResult result, {String projectName = 'Proyecto Estructural'}) {
    final sb = StringBuffer();
    sb.writeln('"Propiedad","Valor","Unidad"');
    sb.writeln('"Proyecto","$projectName",""');
    sb.writeln('"Latitud","${result.site.latitude}","°"');
    sb.writeln('"Longitud","${result.site.longitude}","°"');
    sb.writeln('"Zona Geotécnica","${result.site.zone.name}",""');
    sb.writeln('"Periodo del Suelo (Ts)","${result.site.ts}","s"');
    sb.writeln('"Aceleración del Terreno (a0)","${result.site.a0}","g"');
    sb.writeln('"Coeficiente Sísmico (c)","${result.site.c}",""');
    sb.writeln('"Periodo Ta","${result.site.ta}","s"');
    sb.writeln('"Periodo Tb","${result.site.tb}","s"');
    sb.writeln('"Exponente k","${result.site.k}",""');
    sb.writeln('"Grupo de Importancia","${result.factors.importanceGroup.code} (I=${result.factors.importanceGroup.factor})",""');
    sb.writeln('"Factor Q","${result.factors.q}",""');
    sb.writeln('"Factor Irregularidad","${result.factors.irregularity.factor}",""');
    sb.writeln('"Factor k1","${result.factors.k1}",""');
    sb.writeln('"Factor R0","${result.r0}",""');
    sb.writeln('"Aceleración Máxima de Diseño","${result.aMaxDesign}","g"');
    sb.writeln('');
    sb.writeln('"Periodo T (s)","Espectro Diseño Sa (g)","Espectro Elástico Sa (g)","EPU Sa (g)"');

    for (int i = 0; i < result.designSpectrum.length; i++) {
      final t = result.designSpectrum[i].period;
      final sd = result.designSpectrum[i].acceleration;
      final se = result.elasticSpectrum[i].acceleration;
      final epu = result.epuSpectrum[i].acceleration;
      sb.writeln('${t.toStringAsFixed(3)},${sd.toStringAsFixed(6)},${se.toStringAsFixed(6)},${epu.toStringAsFixed(6)}');
    }

    return sb.toString();
  }

  /// Genera y presenta el reporte de memoria de cálculo en PDF
  static Future<void> exportPdfReport(SpectrumResult result, {String projectName = 'Memoria de Cálculo Sísmico'}) async {
    final pdf = pw.Document();
    final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Filas para la tabla en el PDF (resumen cada 0.1s para tamaño compacto)
    final List<List<String>> tableData = [
      ['T (s)', 'Diseño Sa (g)', 'Elástico Sa (g)', 'EPU Sa (g)'],
    ];

    for (final pt in result.designSpectrum) {
      if ((pt.period * 10).round() % 1 == 0 || (pt.period == result.site.ta) || (pt.period == result.site.tb)) {
        final i = result.designSpectrum.indexOf(pt);
        final se = result.elasticSpectrum[i].acceleration;
        final epu = result.epuSpectrum[i].acceleration;
        tableData.add([
          pt.period.toStringAsFixed(2),
          pt.acceleration.toStringAsFixed(4),
          se.toStringAsFixed(4),
          epu.toStringAsFixed(4),
        ]);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Text(
            'SASID A - NTC CDMX | Memoria de Espectro de Diseño',
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8),
          ),
        ),
        build: (context) => [
          // Título principal
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('0F172A'),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SISTEMA DE ACCIONES SÍSMICAS DE DISEÑO',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Normas Técnicas Complementarias para Diseño por Sismo (NTC-CDMX)',
                      style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9),
                    ),
                  ],
                ),
                pw.Text(
                  now,
                  style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 8),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Datos del proyecto y sitio
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PARÁMETROS DEL SITIO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('1E3A8A'))),
                      pw.Divider(color: PdfColors.grey300),
                      _pdfRow('Latitud:', '${result.site.latitude.toStringAsFixed(6)}°'),
                      _pdfRow('Longitud:', '${result.site.longitude.toStringAsFixed(6)}°'),
                      _pdfRow('Zonificación:', result.site.zone.name),
                      _pdfRow('Periodo Suelo (Ts):', '${result.site.ts.toStringAsFixed(3)} s'),
                      _pdfRow('Acel. Terreno (a0):', '${result.site.a0.toStringAsFixed(3)} g'),
                      _pdfRow('Coeficiente (c):', result.site.c.toStringAsFixed(3)),
                      _pdfRow('Meseta (Ta - Tb):', '${result.site.ta.toStringAsFixed(3)} s - ${result.site.tb.toStringAsFixed(3)} s'),
                      _pdfRow('Exponente (k):', result.site.k.toStringAsFixed(3)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FACTORES SÍSMICOS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('1E3A8A'))),
                      pw.Divider(color: PdfColors.grey300),
                      _pdfRow('Importancia:', '${result.factors.importanceGroup.code} (I = ${result.factors.importanceGroup.factor})'),
                      _pdfRow('Factor Q:', result.factors.q.toString()),
                      _pdfRow('Irregularidad (α):', result.factors.irregularity.factor.toString()),
                      _pdfRow('Hiperestaticidad (k1):', result.factors.k1.toString()),
                      _pdfRow('Sobrerresistencia (R0):', result.r0.toString()),
                      _pdfRow('Sa Máx. Diseño:', '${result.aMaxDesign.toStringAsFixed(4)} g'),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('F0FDF4'),
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColor.fromHex('86EFAC')),
                        ),
                        child: pw.Text(
                          'Cálculo conforme al Apéndice A de las NTC-Sismo.',
                          style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('166534')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // Tabla tabulada de valores
          pw.Text('TABLA DE ORDENADAS ESPECTRALES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('1E3A8A'))),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: tableData.first,
            data: tableData.sublist(1),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('1E3A8A')),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            cellAlignment: pw.Alignment.center,
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 4),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Memoria_Espectro_SASID.pdf',
    );
  }

  static pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ],
      ),
    );
  }
}
