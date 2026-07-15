import 'dart:io';
import 'dart:math';
import 'package:image/image.dart';

void main() async {
  const int baseSize = 1024;
  final image = Image(width: baseSize, height: baseSize);

  const bgR1 = 11, bgG1 = 17, bgB1 = 32;
  const bgR2 = 21, bgG2 = 30, bgB2 = 50;

  for (int y = 0; y < baseSize; y++) {
    for (int x = 0; x < baseSize; x++) {
      final t = y / baseSize;
      final r = (bgR1 + (bgR2 - bgR1) * t).round();
      final g = (bgG1 + (bgG2 - bgG1) * t).round();
      final b = (bgB1 + (bgB2 - bgB1) * t).round();
      image.setPixelRgb(x, y, r, g, b);
    }
  }

  final centerX = baseSize ~/ 2;
  final centerY = baseSize ~/ 2 + 30;
  final radius = baseSize ~/ 2 - 70;

  _drawGlow(image, centerX, centerY, radius, 45, 212, 191);

  drawCircle(image,
    x: centerX, y: centerY,
    radius: radius,
    color: ColorRgb8(21, 30, 50),
  );

  drawCircle(image,
    x: centerX, y: centerY,
    radius: radius - 30,
    color: ColorRgb8(15, 23, 42),
  );

  final accentR = 45, accentG = 212, accentB = 191;
  final accentDarkR = 30, accentDarkG = 160, accentB2 = 144;

  final boxW = (baseSize * 0.52).round();
  final boxH = (baseSize * 0.32).round();
  final boxX = centerX - boxW ~/ 2;
  final boxY = centerY + (baseSize * 0.05).round();
  final boxR = 50;

  _drawRoundedRect(image, boxX, boxY, boxX + boxW, boxY + boxH, boxR,
    ColorRgb8(accentDarkR, accentDarkG, accentB2));

  final boxHighlight = Image(width: baseSize, height: baseSize);
  _drawRoundedRect(boxHighlight,
    boxX + 8, boxY + 8, boxX + boxW - 8, boxY + boxH ~/ 3, boxR - 8,
    ColorRgba8(accentR, accentG, accentB, 100));
  compositeImage(image, boxHighlight);

  final lidW = (baseSize * 0.60).round();
  final lidH = (baseSize * 0.14).round();
  final lidX = centerX - lidW ~/ 2;
  final lidY = boxY - lidH + 12;
  final lidR = 35;
  _drawRoundedRect(image, lidX, lidY, lidX + lidW, lidY + lidH, lidR,
    ColorRgb8(accentR - 5, accentG - 10, accentB - 10));

  final lidHighlight = Image(width: baseSize, height: baseSize);
  _drawRoundedRect(lidHighlight,
    lidX + 10, lidY + 6, lidX + lidW - 10, lidY + lidH ~/ 2 + 4, 20,
    ColorRgba8(255, 255, 255, 50));
  compositeImage(image, lidHighlight);

  _drawGoldLock(image, centerX, lidY - (baseSize * 0.08).round(), baseSize);

  final goldLine = ColorRgb8(245, 180, 60);
  final lineY = lidY + lidH - 5;
  for (int x = lidX + 50; x < lidX + lidW - 50; x++) {
    for (int dy = 0; dy < 3; dy++) {
      image.setPixelRgb(x, lineY + dy, goldLine.r, goldLine.g, goldLine.b);
    }
  }

  final goldDot = ColorRgb8(245, 190, 80);
  final dotY1 = boxY + boxH ~/ 2 - 20;
  final dotY2 = boxY + boxH ~/ 2 + 20;
  for (final dotX in [boxX + 60, boxX + boxW - 60]) {
    fillCircle(image, x: dotX, y: dotY1, radius: 10, color: goldDot);
    fillCircle(image, x: dotX, y: dotY2, radius: 10, color: goldDot);
  }

  _drawVignette(image, centerX, centerY, radius, baseSize);

  final macosDir = Directory('macos/Runner/Assets.xcassets/AppIcon.appiconset');
  final iosDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');

  final macosSizes = {16: 16, 32: 32, 64: 64, 128: 128, 256: 256, 512: 512, 1024: 1024};
  for (final s in macosSizes.entries) {
    final resized = copyResize(image, width: s.value, height: s.value);
    final png = encodePng(resized);
    await File('${macosDir.path}/app_icon_${s.value}.png').writeAsBytes(png);
  }

  final iosSizes = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };

  for (final entry in iosSizes.entries) {
    final resized = copyResize(image, width: entry.value, height: entry.value);
    final png = encodePng(resized);
    await File('${iosDir.path}/${entry.key}').writeAsBytes(png);
  }

  const androidSizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in androidSizes.entries) {
    final dir = Directory('android/app/src/main/res/${entry.key}');
    final resized = copyResize(image, width: entry.value, height: entry.value);
    final png = encodePng(resized);
    await File('${dir.path}/ic_launcher.png').writeAsBytes(png);
  }

  print('✓ 应用图标已生成！(macOS / iOS / Android)');
}

void _drawGlow(Image img, int cx, int cy, int radius, int r, int g, int b) {
  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist < radius + 120) {
        final glowStrength = max(0.0, 1 - dist / (radius + 120));
        final glowAlpha = (glowStrength * glowStrength * 40).round();
        final pr = img.getPixel(x, y);
        final nr = (pr.r as int) + ((r - (pr.r as int)) * glowAlpha ~/ 255);
        final ng = (pr.g as int) + ((g - (pr.g as int)) * glowAlpha ~/ 255);
        final nb = (pr.b as int) + ((b - (pr.b as int)) * glowAlpha ~/ 255);
        img.setPixelRgb(x, y, nr, ng, nb);
      }
    }
  }
}

void _drawVignette(Image img, int cx, int cy, int radius, int baseSize) {
  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist > radius - 60) {
        final vStrength = min(1.0, (dist - radius + 60) / (baseSize * 0.5));
        final vAlpha = (vStrength * vStrength * 100).round();
        if (vAlpha > 0) {
          final pr = img.getPixel(x, y);
          final nr = (pr.r as int) * (255 - vAlpha) ~/ 255;
          final ng = (pr.g as int) * (255 - vAlpha) ~/ 255;
          final nb = (pr.b as int) * (255 - vAlpha) ~/ 255;
          img.setPixelRgb(x, y, nr, ng, nb);
        }
      }
    }
  }
}

void _drawRoundedRect(Image img, int x1, int y1, int x2, int y2, int r, Color color) {
  fillRect(img, x1: x1 + r, y1: y1, x2: x2 - r, y2: y2, color: color);
  fillRect(img, x1: x1, y1: y1 + r, x2: x2, y2: y2 - r, color: color);
  fillCircle(img, x: x1 + r, y: y1 + r, radius: r, color: color);
  fillCircle(img, x: x2 - r, y: y1 + r, radius: r, color: color);
  fillCircle(img, x: x1 + r, y: y2 - r, radius: r, color: color);
  fillCircle(img, x: x2 - r, y: y2 - r, radius: r, color: color);
}

void _drawGoldLock(Image img, int cx, int lockTop, int baseSize) {
  final goldLight = ColorRgb8(255, 220, 110);
  final goldMid = ColorRgb8(245, 180, 60);
  final goldDark = ColorRgb8(190, 130, 20);
  final keyholeColor = ColorRgb8(120, 80, 10);

  final lockW = (baseSize * 0.16).round();
  final lockH = (baseSize * 0.18).round();
  final shackleOuterR = lockW ~/ 2 - 6;
  final shackleThick = max(12, baseSize ~/ 65);
  final shackleCy = lockTop + shackleOuterR;
  final lockBodyTop = lockTop + shackleOuterR * 2 - shackleThick ~/ 2;

  for (int angle = 180; angle <= 360; angle += 1) {
    final rad = angle * pi / 180;
    for (int t = -shackleThick ~/ 2; t <= shackleThick ~/ 2; t++) {
      final r = shackleOuterR + t;
      final x = cx + (r * cos(rad)).round();
      final y = shackleCy + (r * sin(rad)).round();
      if (x >= 0 && x < baseSize && y >= 0 && y < baseSize) {
        final shade = (sin(rad) + 1) / 2;
        final gr = (goldLight.r * shade + goldDark.r * (1 - shade)).round();
        final gg = (goldLight.g * shade + goldDark.g * (1 - shade)).round();
        final gb = (goldLight.b * shade + goldDark.b * (1 - shade)).round();
        img.setPixelRgb(x, y, gr, gg, gb);
      }
    }
  }

  final leftLegX = cx - shackleOuterR;
  final rightLegX = cx + shackleOuterR;
  for (int dy = 0; dy < shackleOuterR; dy++) {
    for (int dx = -shackleThick ~/ 2; dx <= shackleThick ~/ 2; dx++) {
      if (dy > shackleCy - lockBodyTop - shackleThick ~/ 2) continue;
      final y = shackleCy + dy;
      img.setPixelRgb(leftLegX + dx, y, goldDark.r, goldDark.g, goldDark.b);
      img.setPixelRgb(rightLegX + dx, y, goldMid.r, goldMid.g, goldMid.b);
    }
  }

  final bodyR = max(10, lockW ~/ 8);
  _drawRoundedRect(img,
    cx - lockW ~/ 2, lockBodyTop,
    cx + lockW ~/ 2, lockBodyTop + lockH,
    bodyR, goldMid);

  fillRect(img,
    x1: cx - lockW ~/ 2 + 4, y1: lockBodyTop + 4,
    x2: cx + lockW ~/ 2 - 4, y2: lockBodyTop + lockH ~/ 4,
    color: goldLight);

  final keyholeCy = lockBodyTop + lockH * 0.4;
  final keyholeR = max(9, lockW ~/ 9);
  fillCircle(img, x: cx, y: keyholeCy.round(), radius: keyholeR, color: keyholeColor);

  final keySlotW = max(5, lockW ~/ 18);
  final keySlotH = max(14, lockH ~/ 6);
  fillRect(img,
    x1: cx - keySlotW ~/ 2,
    y1: keyholeCy.round() - 2,
    x2: cx + keySlotW ~/ 2,
    y2: keyholeCy.round() + keySlotH,
    color: keyholeColor);
}
