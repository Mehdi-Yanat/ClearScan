import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Longest side (px) used when saving. Keeps memory bounded on phones.
const int kSaveMaxSide = 3000;

/// Longest side (px) of the downscaled copy used for the live preview.
const int kPreviewMaxSide = 1000;

/// Keep the order stable: it matches the filter cards in the UI.
enum DocFilter { original, magic, bw, gray, vivid }

class EnhanceJob {
  const EnhanceJob({
    required this.bytes,
    required this.filter,
    required this.brightness,
    required this.contrast,
    this.maxSide = kSaveMaxSide,
    this.quality = 92,
  });

  final Uint8List bytes;
  final DocFilter filter;

  /// 0..1, 0.5 = unchanged.
  final double brightness;

  /// 0..1, 0.5 = unchanged.
  final double contrast;
  final int maxSide;
  final int quality;
}

/// Decodes, fixes EXIF rotation and shrinks the image once, so every live
/// preview pass works on a small file. Safe to run with `compute`.
Uint8List makePreviewSource(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unsupported image');
  final small = _resizeToMaxSide(img.bakeOrientation(decoded), kPreviewMaxSide);
  return Uint8List.fromList(img.encodeJpg(small, quality: 90));
}

/// Applies the selected filter plus brightness/contrast and returns JPEG
/// bytes. Used for both the preview and the final save, so what the user sees
/// is what gets exported. Safe to run with `compute`.
Uint8List processDocument(EnhanceJob job) {
  var src = img.decodeImage(job.bytes);
  if (src == null) throw const FormatException('Unsupported image');
  src = _resizeToMaxSide(img.bakeOrientation(src), job.maxSide);

  final w = src.width;
  final h = src.height;
  final rgb = Uint8List(w * h * 3);
  var i = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = src.getPixel(x, y);
      rgb[i++] = p.r.toInt();
      rgb[i++] = p.g.toInt();
      rgb[i++] = p.b.toInt();
    }
  }

  switch (job.filter) {
    case DocFilter.original:
      _brightnessContrast(rgb, job.brightness, job.contrast);
    case DocFilter.magic:
      _flattenIllumination(rgb, w, h);
      _levels(rgb, 20, 240);
      _brightnessContrast(rgb, job.brightness, job.contrast);
    case DocFilter.bw:
      _flattenIllumination(rgb, w, h);
      _toGray(rgb);
      _brightnessContrast(rgb, job.brightness, job.contrast);
      _adaptiveThreshold(rgb, w, h);
    case DocFilter.gray:
      _toGray(rgb);
      _brightnessContrast(rgb, job.brightness, job.contrast);
    case DocFilter.vivid:
      _saturate(rgb, 1.35);
      _brightnessContrast(rgb, job.brightness, job.contrast);
  }

  final out = img.Image(width: w, height: h);
  i = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      out.setPixelRgb(x, y, rgb[i], rgb[i + 1], rgb[i + 2]);
      i += 3;
    }
  }
  return Uint8List.fromList(img.encodeJpg(out, quality: job.quality));
}

img.Image _resizeToMaxSide(img.Image src, int maxSide) {
  if (math.max(src.width, src.height) <= maxSide) return src;
  return src.width >= src.height
      ? img.copyResize(
          src,
          width: maxSide,
          interpolation: img.Interpolation.average,
        )
      : img.copyResize(
          src,
          height: maxSide,
          interpolation: img.Interpolation.average,
        );
}

// ---------------------------------------------------------------------------
// Per-pixel helpers. All of them work in place on interleaved RGB bytes.
// ---------------------------------------------------------------------------

void _brightnessContrast(Uint8List rgb, double brightness, double contrast) {
  final c = contrast + 0.5;
  final b = (brightness - 0.5) * 100;
  if ((c - 1).abs() < 1e-6 && b.abs() < 1e-6) return;
  final lut = Uint8List(256);
  for (var v = 0; v < 256; v++) {
    lut[v] = ((v - 128) * c + 128 + b).round().clamp(0, 255);
  }
  for (var i = 0; i < rgb.length; i++) {
    rgb[i] = lut[rgb[i]];
  }
}

/// Maps [lo]..[hi] to 0..255. Pushes near-white paper to pure white and
/// darkens ink a little.
void _levels(Uint8List rgb, int lo, int hi) {
  final lut = Uint8List(256);
  final scale = 255 / (hi - lo);
  for (var v = 0; v < 256; v++) {
    lut[v] = ((v - lo) * scale).round().clamp(0, 255);
  }
  for (var i = 0; i < rgb.length; i++) {
    rgb[i] = lut[rgb[i]];
  }
}

void _toGray(Uint8List rgb) {
  for (var i = 0; i < rgb.length; i += 3) {
    final l = (rgb[i] * 299 + rgb[i + 1] * 587 + rgb[i + 2] * 114) ~/ 1000;
    rgb[i] = l;
    rgb[i + 1] = l;
    rgb[i + 2] = l;
  }
}

void _saturate(Uint8List rgb, double s) {
  for (var i = 0; i < rgb.length; i += 3) {
    final r = rgb[i].toDouble();
    final g = rgb[i + 1].toDouble();
    final b = rgb[i + 2].toDouble();
    final l = 0.299 * r + 0.587 * g + 0.114 * b;
    rgb[i] = (l + (r - l) * s).round().clamp(0, 255);
    rgb[i + 1] = (l + (g - l) * s).round().clamp(0, 255);
    rgb[i + 2] = (l + (b - l) * s).round().clamp(0, 255);
  }
}

/// Removes shadows and uneven lighting.
///
/// 1. Split the image into a coarse grid of cells.
/// 2. Take the 90th-percentile value per cell and channel. Ink covers a
///    small share of a cell, so this is the paper colour, not the text.
/// 3. Blur the grid and sample it bilinearly to get a smooth "background".
/// 4. Divide each pixel by that background, so paper becomes white.
void _flattenIllumination(Uint8List rgb, int w, int h) {
  final cell = math.max(8, math.max(w, h) ~/ 48);
  final gw = (w + cell - 1) ~/ cell;
  final gh = (h + cell - 1) ~/ cell;
  var grid = Float32List(gw * gh * 3);
  final hist = Int32List(768);

  for (var gy = 0; gy < gh; gy++) {
    final y0 = gy * cell;
    final y1 = math.min(h, y0 + cell);
    for (var gx = 0; gx < gw; gx++) {
      final x0 = gx * cell;
      final x1 = math.min(w, x0 + cell);
      hist.fillRange(0, 768, 0);
      for (var y = y0; y < y1; y++) {
        var idx = (y * w + x0) * 3;
        for (var x = x0; x < x1; x++) {
          hist[rgb[idx]]++;
          hist[256 + rgb[idx + 1]]++;
          hist[512 + rgb[idx + 2]]++;
          idx += 3;
        }
      }
      final target = ((y1 - y0) * (x1 - x0) * 0.9).floor();
      for (var c = 0; c < 3; c++) {
        var acc = 0;
        var v = 255;
        for (var k = 0; k < 256; k++) {
          acc += hist[c * 256 + k];
          if (acc > target) {
            v = k;
            break;
          }
        }
        grid[(gy * gw + gx) * 3 + c] = v.toDouble();
      }
    }
  }

  // Cells that are mostly dark graphics (a photo, a logo) would otherwise be
  // "corrected" to white. Never let the background fall below half the median.
  for (var c = 0; c < 3; c++) {
    final vals = <double>[for (var i = 0; i < gw * gh; i++) grid[i * 3 + c]]
      ..sort();
    final floor = vals[vals.length ~/ 2] * 0.5;
    for (var i = 0; i < gw * gh; i++) {
      if (grid[i * 3 + c] < floor) grid[i * 3 + c] = floor;
    }
  }

  grid = _blurGrid(_blurGrid(grid, gw, gh), gw, gh);

  final x0s = Int32List(w);
  final x1s = Int32List(w);
  final xws = Float32List(w);
  for (var x = 0; x < w; x++) {
    final f = ((x + 0.5) / cell - 0.5).clamp(0.0, gw - 1.0).toDouble();
    final i0 = f.floor();
    x0s[x] = i0;
    x1s[x] = math.min(i0 + 1, gw - 1);
    xws[x] = f - i0;
  }

  for (var y = 0; y < h; y++) {
    final fy = ((y + 0.5) / cell - 0.5).clamp(0.0, gh - 1.0).toDouble();
    final j0 = fy.floor();
    final j1 = math.min(j0 + 1, gh - 1);
    final wy = fy - j0;
    var idx = y * w * 3;
    for (var x = 0; x < w; x++) {
      final p00 = (j0 * gw + x0s[x]) * 3;
      final p10 = (j0 * gw + x1s[x]) * 3;
      final p01 = (j1 * gw + x0s[x]) * 3;
      final p11 = (j1 * gw + x1s[x]) * 3;
      final wx = xws[x];
      for (var ch = 0; ch < 3; ch++) {
        final top = grid[p00 + ch] + (grid[p10 + ch] - grid[p00 + ch]) * wx;
        final bot = grid[p01 + ch] + (grid[p11 + ch] - grid[p01 + ch]) * wx;
        final bg = top + (bot - top) * wy;
        final v = rgb[idx] * 255 / (bg < 1 ? 1 : bg);
        rgb[idx] = v > 255 ? 255 : v.round();
        idx++;
      }
    }
  }
}

Float32List _blurGrid(Float32List src, int gw, int gh) {
  final dst = Float32List(src.length);
  for (var gy = 0; gy < gh; gy++) {
    for (var gx = 0; gx < gw; gx++) {
      for (var c = 0; c < 3; c++) {
        var sum = 0.0;
        var n = 0;
        for (var dy = -1; dy <= 1; dy++) {
          final yy = gy + dy;
          if (yy < 0 || yy >= gh) continue;
          for (var dx = -1; dx <= 1; dx++) {
            final xx = gx + dx;
            if (xx < 0 || xx >= gw) continue;
            sum += src[(yy * gw + xx) * 3 + c];
            n++;
          }
        }
        dst[(gy * gw + gx) * 3 + c] = sum / n;
      }
    }
  }
  return dst;
}

/// Local-mean threshold on a gray image (red channel is read). A pixel turns
/// black when it is clearly darker than its neighbourhood, or very dark in
/// absolute terms (so solid black areas do not turn white inside).
/// The integral image is a Uint32List: fine up to ~16M pixels, and
/// [kSaveMaxSide] keeps us well below that.
void _adaptiveThreshold(Uint8List rgb, int w, int h) {
  final stride = w + 1;
  final integral = Uint32List(stride * (h + 1));
  for (var y = 0; y < h; y++) {
    var rowSum = 0;
    for (var x = 0; x < w; x++) {
      rowSum += rgb[(y * w + x) * 3];
      integral[(y + 1) * stride + (x + 1)] =
          integral[y * stride + (x + 1)] + rowSum;
    }
  }

  final half = math.max(7, math.max(w, h) ~/ 60);
  for (var y = 0; y < h; y++) {
    final y0 = math.max(0, y - half);
    final y1 = math.min(h - 1, y + half);
    for (var x = 0; x < w; x++) {
      final x0 = math.max(0, x - half);
      final x1 = math.min(w - 1, x + half);
      final area = (x1 - x0 + 1) * (y1 - y0 + 1);
      final sum =
          integral[(y1 + 1) * stride + (x1 + 1)] -
          integral[y0 * stride + (x1 + 1)] -
          integral[(y1 + 1) * stride + x0] +
          integral[y0 * stride + x0];
      final idx = (y * w + x) * 3;
      final lum = rgb[idx];
      final v = (lum < (sum / area) * 0.85 || lum < 60) ? 0 : 255;
      rgb[idx] = v;
      rgb[idx + 1] = v;
      rgb[idx + 2] = v;
    }
  }
}
