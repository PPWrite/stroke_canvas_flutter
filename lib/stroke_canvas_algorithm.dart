part of 'stroke_canvas.dart';

/// 获取图片信息
Future<ImageInfo> resolveImageProviderInfo(
  ImageProvider image, {
  double pixelRatio = 1,
}) async {
  ImageStream stream = image.resolve(ImageConfiguration(
    bundle: (image is AssetImage) ? image.bundle ?? rootBundle : null,
    devicePixelRatio: pixelRatio,
    platform: defaultTargetPlatform,
  ));
  Completer<ImageInfo> completer = Completer();

  final listener = ImageStreamListener((ImageInfo imageInfo, _) {
    return completer.complete(imageInfo);
  });
  stream.addListener(listener);

  return completer.future.then((value) {
    stream.removeListener(listener);
    return value;
  });
}

Future<ui.Image> _paintToImage(
  _StrokeCanvasPaintable drawble,
  double width,
  double height,
) async {
  final p = _paintToPicture(drawble, width, height);

  final image = await p.toImage(width.toInt(), height.toInt());

  p.dispose();

  return image;
}

ui.Picture _paintToPicture(
  _StrokeCanvasPaintable drawble,
  double width,
  double height,
) {
  final recorder = ui.PictureRecorder();
  Canvas canvas = Canvas(recorder);
  canvas.clipRect(Rect.fromLTWH(0, 0, width, height));

  drawble.paint(canvas, ui.Size(width, height));

  return recorder.endRecording();
}

/// 创建空的图片
Future<ui.Image> _createEmptyImage(double width, double height) async {
  final recorder = ui.PictureRecorder();
  final _ = Canvas(recorder);
  final p = recorder.endRecording();
  final img = await p.toImage(width.toInt(), height.toInt());
  p.dispose();
  return img;
}
