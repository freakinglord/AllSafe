import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:allsafe/services/steganography_service.dart';

Uint8List _makePng(int width, int height) {
  final image = img.Image(width: width, height: height);
  return img.encodePng(image);
}

void main() {
  group('SteganographyService', () {
    test('embed → extract round-trip returns original payload', () {
      final png = _makePng(100, 100);
      final payload = Uint8List.fromList([1, 2, 3, 4, 5]);
      final embedded = SteganographyService.embed(png, payload);
      final extracted = SteganographyService.extract(embedded);
      expect(extracted, equals(payload));
    });

    test('extract on plain PNG throws SteganographyException', () {
      final png = _makePng(100, 100);
      expect(() => SteganographyService.extract(png),
          throwsA(isA<SteganographyException>()));
    });

    test('embed on JPEG header throws SteganographyException', () {
      final jpeg = Uint8List.fromList([0xFF, 0xD8, 0x00, 0x00]);
      final payload = Uint8List.fromList([1, 2, 3]);
      expect(() => SteganographyService.embed(jpeg, payload),
          throwsA(isA<SteganographyException>()));
    });

    test('embed on image too small for payload throws SteganographyException', () {
      final png = _makePng(1, 1);
      final payload = Uint8List(100);
      expect(() => SteganographyService.embed(png, payload),
          throwsA(isA<SteganographyException>()));
    });

    test('extract on JPEG header throws SteganographyException', () {
      final jpeg = Uint8List.fromList([0xFF, 0xD8, 0x00, 0x00]);
      expect(() => SteganographyService.extract(jpeg),
          throwsA(isA<SteganographyException>()));
    });
  });
}
