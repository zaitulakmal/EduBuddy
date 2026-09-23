import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the system share sheet with the PNG, which offers "Save Image" to Photos.
/// `anchor` is the tapped button; iPad needs it to place the share popover.
Future<void> shareImage(BuildContext anchor, Uint8List png, String fileName) async {
  final box = anchor.findRenderObject() as RenderBox?;
  final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  await SharePlus.instance.share(ShareParams(
    files: [XFile.fromData(png, mimeType: 'image/png')],
    fileNameOverrides: [fileName],
    sharePositionOrigin: origin,
  ));
}
