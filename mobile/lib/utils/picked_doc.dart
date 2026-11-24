import 'dart:typed_data';

/// A document image chosen with the camera or from a file, held in memory until the
/// customer is submitted.
class PickedDoc {
  const PickedDoc({required this.bytes, required this.name, required this.contentType});

  final Uint8List bytes;
  final String name;
  final String contentType;
}
