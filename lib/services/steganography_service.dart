import 'dart:typed_data';
import 'package:image/image.dart' as img;

class SteganographyException implements Exception {
  final String message;
  const SteganographyException(this.message);
  @override
  String toString() => message;
}

/// Hides arbitrary binary data inside PNG images using LSB steganography.
///
/// Method: 1 bit is stored in the LSB of each R, G, B channel (3 bits/pixel).
/// The payload is prefixed with a 9-byte header:
///   STEG (4 bytes magic) | version (1 byte) | payload length (4 bytes, big-endian)
///
/// Only PNG images are supported — JPEG lossy compression destroys hidden bits.
class SteganographyService {
  static const List<int> _magic = [0x53, 0x54, 0x45, 0x47]; // "STEG"
  static const int _version = 0x01;
  static const int _headerSize = 9; // magic(4) + version(1) + length(4)

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Embeds [payload] into [pngBytes] and returns a new PNG with hidden data.
  static Uint8List embed(Uint8List pngBytes, Uint8List payload) {
    _rejectJpeg(pngBytes);

    final image = img.decodePng(pngBytes);
    if (image == null) {
      throw const SteganographyException(
          'Failed to decode image. Make sure it is a valid PNG file.');
    }

    // Normalise to 4-channel RGBA for consistent channel access
    final canvas =
        image.numChannels < 4 ? image.convert(numChannels: 4) : image;

    // Build full data blob: header + payload
    final header = _buildHeader(payload.length);
    final fullData = Uint8List(header.length + payload.length)
      ..setAll(0, header)
      ..setAll(header.length, payload);

    // Capacity check (3 bits per pixel via R, G, B)
    final bitsNeeded = fullData.length * 8;
    final pixelsAvailable = canvas.width * canvas.height;
    if (bitsNeeded > pixelsAvailable * 3) {
      final minPixels = (bitsNeeded / 3).ceil();
      throw SteganographyException(
        'Image is too small to hold the safe.\n'
        'Required: $minPixels pixels (${fullData.length} bytes).\n'
        'Available: $pixelsAvailable pixels '
        '(${pixelsAvailable * 3 ~/ 8} bytes capacity).\n'
        'Use a larger PNG image.',
      );
    }

    // Embed bits into LSBs of R, G, B channels, row-major order
    int bitIndex = 0;
    final maxBits = fullData.length * 8;

    outer:
    for (int y = 0; y < canvas.height; y++) {
      for (int x = 0; x < canvas.width; x++) {
        if (bitIndex >= maxBits) break outer;

        final pixel = canvas.getPixel(x, y);
        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();
        final int a = pixel.a.toInt();

        if (bitIndex < maxBits) r = (r & 0xFE) | _getBit(fullData, bitIndex++);
        if (bitIndex < maxBits) g = (g & 0xFE) | _getBit(fullData, bitIndex++);
        if (bitIndex < maxBits) b = (b & 0xFE) | _getBit(fullData, bitIndex++);

        canvas.setPixelRgba(x, y, r, g, b, a);
      }
    }

    return img.encodePng(canvas);
  }

  /// Extracts a hidden payload from [pngBytes].
  /// Throws [SteganographyException] if no safe is found.
  static Uint8List extract(Uint8List pngBytes) {
    _rejectJpeg(pngBytes);

    final image = img.decodePng(pngBytes);
    if (image == null) {
      throw const SteganographyException(
          'Failed to decode image. Make sure it is a valid PNG file.');
    }

    final canvas =
        image.numChannels < 4 ? image.convert(numChannels: 4) : image;

    // Stream bits from LSBs and assemble bytes
    int currentByte = 0;
    int bitCount = 0;
    final extracted = <int>[];
    int? payloadLength;

    void addBit(int channelValue) {
      currentByte = (currentByte << 1) | (channelValue & 1);
      if (++bitCount == 8) {
        extracted.add(currentByte);
        currentByte = 0;
        bitCount = 0;
      }
    }

    outer:
    for (int y = 0; y < canvas.height; y++) {
      for (int x = 0; x < canvas.width; x++) {
        final pixel = canvas.getPixel(x, y);
        addBit(pixel.r.toInt());
        addBit(pixel.g.toInt());
        addBit(pixel.b.toInt());

        // Parse header once we have enough bytes
        if (payloadLength == null && extracted.length >= _headerSize) {
          _validateHeader(extracted);
          payloadLength = (extracted[5] << 24) |
              (extracted[6] << 16) |
              (extracted[7] << 8) |
              extracted[8];
          if (payloadLength <= 0 || payloadLength > 50 * 1024 * 1024) {
            throw const SteganographyException(
                'Corrupt or invalid safe data detected in this image.');
          }
        }

        if (payloadLength != null &&
            extracted.length >= _headerSize + payloadLength) {
          break outer;
        }
      }
    }

    if (payloadLength == null) {
      throw const SteganographyException(
        'No safe found in this image.\n'
        'Make sure you selected the correct PNG file that contains a safe.',
      );
    }

    return Uint8List.fromList(
        extracted.sublist(_headerSize, _headerSize + payloadLength));
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  static Uint8List _buildHeader(int payloadLength) {
    final h = Uint8List(_headerSize);
    h[0] = _magic[0];
    h[1] = _magic[1];
    h[2] = _magic[2];
    h[3] = _magic[3];
    h[4] = _version;
    // Payload length as big-endian uint32
    h[5] = (payloadLength >> 24) & 0xFF;
    h[6] = (payloadLength >> 16) & 0xFF;
    h[7] = (payloadLength >> 8) & 0xFF;
    h[8] = payloadLength & 0xFF;
    return h;
  }

  /// Extracts bit [bitIndex] from [data], MSB-first within each byte.
  static int _getBit(Uint8List data, int bitIndex) {
    return (data[bitIndex >> 3] >> (7 - (bitIndex & 7))) & 1;
  }

  static void _validateHeader(List<int> bytes) {
    for (int i = 0; i < _magic.length; i++) {
      if (bytes[i] != _magic[i]) {
        throw const SteganographyException(
          'This image does not contain a safe.\n'
          'No hidden data signature was found.',
        );
      }
    }
    if (bytes[4] != _version) {
      throw SteganographyException(
        'Unsupported safe format version: ${bytes[4]}. '
        'Please update the app.',
      );
    }
  }

  static void _rejectJpeg(Uint8List bytes) {
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      throw const SteganographyException(
        'JPEG images cannot be used — lossy compression destroys hidden data.\n'
        'Please use a PNG image instead.',
      );
    }
  }
}
