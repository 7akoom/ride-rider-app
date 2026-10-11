import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../tokens/palette.dart';

/// The captain's car as the map draws it: seen from above, nose up (north), painted in
/// the brand's colour with tyres, mirrors, windows and lights. Drawn here rather than
/// shipped as a picture, so each copy's car has its brand's colour. [size] is in device
/// pixels; every measure below is a share of it.
Future<Uint8List> carIconPng(Palette palette, double size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(size);
  final body = palette.brand;
  final edge = Color.lerp(body, palette.ink, 0.62)!;
  final glass = Color.lerp(palette.ink, palette.onInk, 0.15)!;
  final fill = Paint();

  RRect box(double left, double top, double right, double bottom, double radius) =>
      RRect.fromLTRBR(left, top, right, bottom, Radius.circular(radius));

  // A soft shadow, so the car stands out on any street.
  canvas.drawRRect(
    box(0.29, 0.12, 0.71, 0.92, 0.13),
    Paint()
      ..color = palette.ink.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.035),
  );

  fill.color = palette.ink;
  for (final (x, y) in const [(0.255, 0.20), (0.665, 0.20), (0.255, 0.64), (0.665, 0.64)]) {
    canvas.drawRRect(box(x, y, x + 0.08, y + 0.15, 0.025), fill);
  }

  final shell = box(0.29, 0.09, 0.71, 0.89, 0.12);
  canvas.drawRRect(shell, fill..color = body);
  canvas.drawRRect(
    shell,
    Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.018,
  );

  // The bonnet's two creases.
  final crease = Paint()
    ..color = Color.lerp(body, palette.ink, 0.1)!
    ..strokeWidth = 0.008;
  canvas
    ..drawLine(const Offset(0.40, 0.13), const Offset(0.38, 0.30), crease)
    ..drawLine(const Offset(0.60, 0.13), const Offset(0.62, 0.30), crease);

  Path shape(List<Offset> corners) => Path()..addPolygon(corners, true);
  fill.color = glass;
  canvas
    // Windscreen, side windows, rear window.
    ..drawPath(shape(const [Offset(0.37, 0.31), Offset(0.63, 0.31), Offset(0.66, 0.42), Offset(0.34, 0.42)]), fill)
    ..drawPath(shape(const [Offset(0.315, 0.43), Offset(0.333, 0.43), Offset(0.333, 0.66), Offset(0.315, 0.64)]), fill)
    ..drawPath(shape(const [Offset(0.685, 0.43), Offset(0.667, 0.43), Offset(0.667, 0.66), Offset(0.685, 0.64)]), fill)
    ..drawPath(shape(const [Offset(0.345, 0.66), Offset(0.655, 0.66), Offset(0.63, 0.75), Offset(0.37, 0.75)]), fill);

  // The roof, a shade darker than the body.
  canvas.drawRRect(box(0.335, 0.42, 0.665, 0.66, 0.04), fill..color = Color.lerp(body, palette.ink, 0.07)!);

  // Mirrors.
  final mirrorEdge = Paint()
    ..color = edge
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.012;
  for (final left in const [0.25, 0.695]) {
    final mirror = Rect.fromLTRB(left, 0.37, left + 0.055, 0.41);
    canvas
      ..drawOval(mirror, fill..color = body)
      ..drawOval(mirror, mirrorEdge);
  }

  // Headlights at the front, tail lights at the back.
  final head = Color.lerp(palette.onInk, palette.brand, 0.4)!;
  for (final left in const [0.33, 0.59]) {
    canvas
      ..drawRRect(box(left, 0.105, left + 0.08, 0.13, 0.012), fill..color = head)
      ..drawRRect(box(left, 0.855, left + 0.08, 0.875, 0.01), fill..color = palette.danger);
  }

  final image = await recorder.endRecording().toImage(size.round(), size.round());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  return bytes!.buffer.asUint8List();
}
