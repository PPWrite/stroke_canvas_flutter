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

Future<_StrokeCanvasPaintableImage> _paintToPaintableImage(
  _StrokeCanvasPaintable drawble,
  double width,
  double height,
  double pixelRatio,
) async {
  final image = await _paintToImage(drawble, width, height);

  return _StrokeCanvasPaintableImage(
    image: _StrokeCanvasImage(image),
    width: width,
    height: height,
    pixelRatio: pixelRatio,
    fit: BoxFit.none,
  );
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

_StrokeCanvasPaintablePictrue _paintToPaintablePicture(
  _StrokeCanvasPaintable drawble,
  double width,
  double height,
) {
  return _StrokeCanvasPaintablePictrue(
    picture: _paintToPicture(drawble, width, height),
    width: width,
    height: height,
  );
}

Widget _paintToWidget(
  _StrokeCanvasPaintablePictrue picture,
  double width,
  double height,
  double pixelRatio,
) {
  // 创建widget
  return RepaintBoundary(
    child: CustomPaint(
      isComplex: true,
      painter: _StrokeCanvasCustomPainter(
        paintable: picture,
        pixelRatio: pixelRatio,
      ),
      size: ui.Size(width, height),
    ),
  );
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
