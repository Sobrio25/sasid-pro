import 'dart:typed_data';
import 'package:flutter/services.dart';

class SurferGrid {
  final int nx;
  final int ny;
  final double xmin;
  final double xmax;
  final double ymin;
  final double ymax;
  final double zmin;
  final double zmax;
  final Float32List values;

  SurferGrid({
    required this.nx,
    required this.ny,
    required this.xmin,
    required this.xmax,
    required this.ymin,
    required this.ymax,
    required this.zmin,
    required this.zmax,
    required this.values,
  });

  double interpolate(double lon, double lat) {
    final lonClamped = lon.clamp(xmin, xmax);
    final latClamped = lat.clamp(ymin, ymax);
    final dx = (xmax - xmin) / (nx - 1);
    final dy = (ymax - ymin) / (ny - 1);
    final fx = (lonClamped - xmin) / dx;
    final fy = (latClamped - ymin) / dy;
    int ix = fx.floor().clamp(0, nx - 2);
    int iy = fy.floor().clamp(0, ny - 2);
    final tx = fx - ix;
    final ty = fy - iy;
    double v00 = values[iy * nx + ix].toDouble();
    double v10 = values[iy * nx + ix + 1].toDouble();
    double v01 = values[(iy + 1) * nx + ix].toDouble();
    double v11 = values[(iy + 1) * nx + ix + 1].toDouble();
    if (v00 == 1.70141e38) v00 = zmin;
    if (v10 == 1.70141e38) v10 = zmin;
    if (v01 == 1.70141e38) v01 = zmin;
    if (v11 == 1.70141e38) v11 = zmin;
    final vx0 = v00 * (1 - tx) + v10 * tx;
    final vx1 = v01 * (1 - tx) + v11 * tx;
    return vx0 * (1 - ty) + vx1 * ty;
  }
}

class GrdService {
  static final Map<String, SurferGrid> _cache = {};

  static Future<SurferGrid?> loadGrid(String assetPath) async {
    if (_cache.containsKey(assetPath)) return _cache[assetPath];
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      if (bytes.length >= 56 &&
          bytes[0] == 0x44 &&
          bytes[1] == 0x53 &&
          bytes[2] == 0x42 &&
          bytes[3] == 0x42) {
        return _parseBinary(assetPath, data);
      }
      final text = String.fromCharCodes(bytes);
      if (text.startsWith('DSAA')) return _parseAscii(assetPath, text);
      return null;
    } catch (_) {
      return null;
    }
  }

  static SurferGrid _parseBinary(String path, ByteData data) {
    final bd = data;
    final nx = bd.getInt16(4, Endian.little);
    final ny = bd.getInt16(6, Endian.little);
    final xmin = bd.getFloat64(8, Endian.little);
    final xmax = bd.getFloat64(16, Endian.little);
    final ymin = bd.getFloat64(24, Endian.little);
    final ymax = bd.getFloat64(32, Endian.little);
    final zmin = bd.getFloat64(40, Endian.little);
    final zmax = bd.getFloat64(48, Endian.little);
    final count = nx * ny;
    final values = Float32List(count);
    for (int i = 0; i < count; i++) {
      values[i] = bd.getFloat32(56 + i * 4, Endian.little);
    }
    final grid = SurferGrid(
      nx: nx,
      ny: ny,
      xmin: xmin,
      xmax: xmax,
      ymin: ymin,
      ymax: ymax,
      zmin: zmin,
      zmax: zmax,
      values: values,
    );
    _cache[path] = grid;
    return grid;
  }

  static SurferGrid? _parseAscii(String path, String text) {
    try {
      final tokens = text
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();
      final nx = int.parse(tokens[1]);
      final ny = int.parse(tokens[2]);
      final xmin = double.parse(tokens[3]);
      final xmax = double.parse(tokens[4]);
      final ymin = double.parse(tokens[5]);
      final ymax = double.parse(tokens[6]);
      final zmin = double.parse(tokens[7]);
      final zmax = double.parse(tokens[8]);
      final count = nx * ny;
      final values = Float32List(count);
      for (int i = 0; i < count; i++) {
        values[i] = double.parse(tokens[9 + i]);
      }
      final grid = SurferGrid(
        nx: nx,
        ny: ny,
        xmin: xmin,
        xmax: xmax,
        ymin: ymin,
        ymax: ymax,
        zmin: zmin,
        zmax: zmax,
        values: values,
      );
      _cache[path] = grid;
      return grid;
    } catch (_) {
      return null;
    }
  }

  /// CMaximo.grd: valores en gal (mili-g); dividir entre 1000 para fracción de g.
  static Future<double?> interpolateCmax(double lat, double lon) async {
    final grid = await loadGrid('assets/grids/CMaximo.grd');
    if (grid == null) return null;
    final raw = grid.interpolate(lon, lat);
    return raw / 1000.0;
  }

  /// ES_DF{época}.grd: periodo fundamental Ts del suelo directamente en segundos.
  static Future<double?> interpolateTs(
    double lat,
    double lon,
    String assetPath,
  ) async {
    final grid = await loadGrid(assetPath);
    if (grid == null) return null;
    return grid.interpolate(lon, lat);
  }
}
