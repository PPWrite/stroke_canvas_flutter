part of 'stroke_canvas.dart';

class StrokeCanvasPainter {
  StrokeCanvasPainter({
    Size size = const Size(1, 1),
    double pixelRatio = 1,
    Color lineColor = Colors.black,
    double strokeWidth = 3,
  })  : assert(pixelRatio > 0),
        assert(size.width > 0 || size.height > 0),
        assert(strokeWidth > 0),
        _size = size,
        _pixelRatio = pixelRatio,
        _sizeWidth = size.width * pixelRatio,
        _sizeHeight = size.height * pixelRatio {
    final info = _getPen(kStrokeCanvasPainterDefaultPenId);
    info.lineColor = lineColor;
    info.strokeWidth = strokeWidth;
  }

  /// 当前绘制的大小
  Size _size;

  /// 当前绘制的大小
  Size get size => _size;

  /// 当前绘制的大小
  set size(Size value) {
    if (value.width == _size.width && value.height == _size.height) return;

    _size = value;

    // 计算绘制大小
    _sizeWidth = value.width * pixelRatio;

    _sizeHeight = value.height * pixelRatio;
  }

  /// 绘制宽度
  double _sizeWidth;

  /// 绘制高度
  double _sizeHeight;

  /// 设备像素密度，通过`MediaQuery.of(context)devicePixelRatio`可以获取到。
  double _pixelRatio;

  /// 设备像素密度，通过`MediaQuery.of(context)devicePixelRatio`可以获取到。
  double get pixelRatio => _pixelRatio;

  /// 设备像素密度，通过`MediaQuery.of(context)devicePixelRatio`可以获取到。
  set pixelRatio(double value) {
    if (value == _pixelRatio) return;

    _pixelRatio = value;

    // 计算绘制大小
    _sizeWidth = (_size.width * value).ceil().toDouble();

    _sizeHeight = (_size.height * value).ceil().toDouble();
  }

  /// 默认的笔画颜色
  Color get lineColor => getLineColor();

  /// 默认的笔画颜色
  set lineColor(Color value) => setLineColor(value);

  /// 设置画笔颜色
  void setLineColor(Color color,
      {String penId = kStrokeCanvasPainterDefaultPenId}) {
    final info = _getPen(penId);
    if (info.lineColor.value != color.value) {
      info.lineColor = color;
      info.closedPath();
    }
  }

  /// 获取画笔颜色
  Color getLineColor({String penId = kStrokeCanvasPainterDefaultPenId}) {
    return _getPen(penId).lineColor;
  }

  /// 默认的笔画宽度。
  double get strokeWidth => getStrokeWidth();

  /// 默认的笔画宽度。
  set strokeWidth(double value) => setStrokeWidth(value);

  /// 设置画笔宽度
  void setStrokeWidth(double width,
      {String penId = kStrokeCanvasPainterDefaultPenId}) {
    _getPen(penId).strokeWidth = width;
  }

  /// 获取画笔宽度
  double getStrokeWidth({String penId = kStrokeCanvasPainterDefaultPenId}) {
    return _getPen(penId).strokeWidth;
  }

  /// 开始一个新的线条。
  /// [drawLine]是否触发绘制操作
  void newLine({
    bool drawLine = true,
    String penId = kStrokeCanvasPainterDefaultPenId,
  }) {
    _getPen(penId).previousPoint = null;
  }

  /// 当前线条绘制一个点。
  void drawPoint(
    double x,
    double y, {
    String? penId,
    double? width,
  }) {
    _addPoint(
      x,
      y,
      penId: penId ?? kStrokeCanvasPainterDefaultPenId,
      width: width,
    );

    _isShouldPaint = true;
  }

  /// 当前线条添加一个点，但不绘制。
  /// 在批量绘制但又不想实时显示时，可以先调用[addPoint]，最后调用[shouldPaint]。
  void addPoint(
    double x,
    double y, {
    String? penId,
    double? width,
    ui.Color? color,
  }) {
    _addPoint(
      x,
      y,
      needDraw: false,
      penId: penId ?? kStrokeCanvasPainterDefaultPenId,
      width: width,
    );
  }

  /// 绘制图片
  void drawImage(
    ui.Image image, {
    Rect? rect,
    Alignment alignment = Alignment.center,
    BoxFit fit = BoxFit.fill,
    ColorFilter? colorFilter,
  }) {
    _addImage(
      image,
      rect: rect,
      alignment: alignment,
      fit: fit,
      colorFilter: colorFilter,
    );

    _isShouldPaint = true;
  }

  /// 添加图片但不触发绘制操作，知道主动调用[shouldPaint]相关方法。
  /// 在批量绘制但又不想实时显示时，可以先调用[addImage]，最后调用[shouldPaint]。
  void addImage(
    ui.Image image, {
    Rect? rect,
    Alignment alignment = Alignment.center,
    BoxFit fit = BoxFit.fill,
    ColorFilter? colorFilter,
  }) {
    _addImage(
      image,
      rect: rect,
      alignment: alignment,
      fit: fit,
      colorFilter: colorFilter,
      needDraw: false,
    );
  }

  /// 清理画布的次数
  int _cleanCount = 0;

  /// 清空画布
  void clean() {
    _cleanCount++;
    _pens.forEach((_, value) {
      value.previousPoint = null;
      value.newPath();
    });

    _drawables.dispose();
    _drawables = _StrokeCanvasPaintableList();
    _drawingDrawables.dispose();
    _drawingDrawables = _StrokeCanvasPaintableList();

    _isShouldPaint = true;
  }

  /// 获取绘制的图片
  Future<MemoryImage> getDrawnMemoryImage() async {
    ui.Image img = await getDrawnImage();

    final by = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();

    return MemoryImage(by!.buffer.asUint8List(), scale: _pixelRatio);
  }

  /// 获取绘制的图片，在图片使用完成后，需要调用dispose方法释放内存。
  Future<ui.Image> getDrawnImage() async {
    ui.Image img;
    if (_isDispose) {
      img = await _createEmptyImage();
    } else {
      _StrokeCanvasPaintableList _trailPaths = _StrokeCanvasPaintableList();
      _trailPaths.append(_drawingDrawables);
      _trailPaths.append(_drawables);
      for (var info in _pens.values) {
        if (info.path.isNotEmpty) {
          _trailPaths.add(info.path);
        }
      }

      img = await _paintToImage(_trailPaths);
    }

    return img;
  }

  /// 绘制
  void shouldPaint() {
    _isShouldPaint = true;
  }

  /// 已经绘制
  void _painted() {
    _isShouldPaint = false;
  }

  bool _isDispose = false;
  void dispose() {
    _isDispose = true;
    clean();
  }

  /// 是否已经更新
  bool _isShouldPaint = false;

  /// 笔的信息
  final Map<String, _StrokeCanvasPen> _pens = {};

  _StrokeCanvasPen _getPen(String penId) {
    var info = _pens[penId];
    if (info == null) {
      info = _StrokeCanvasPen(onClosedPath: (path) => _addDrawable(path));
      _pens[penId] = info;
    }

    return info;
  }

  _StrokeCanvasPaintableList _drawables = _StrokeCanvasPaintableList();
  _StrokeCanvasPaintableList _drawingDrawables = _StrokeCanvasPaintableList();

  void _addPoint(
    double x,
    double y, {
    required String penId,
    double? width,
    bool needDraw = true,
  }) {
    if (_isDispose) return;

    final pen = _getPen(penId);

    final point = _StrokeCanvasPoint(x, y, w: width ?? pen.strokeWidth);

    final previousPoint = pen.previousPoint;

    if (previousPoint == null || point.same(previousPoint)) {
      // 没有最后一个点，或者最后一个点和当前点坐标相同，
      // 则只需要再绘制一个点就行
      //_paintPoint(canvas, paint, point);
      pen.addPoint(point);
      pen.previousPoint = point;
    } else {
      // 坐标不相同进行差点

      var step = point.distance(previousPoint).toInt();
      // 性能不够先注释掉
      // step *= 3;

      // 插入点
      if (step > 1) {
        final stepX = (point.x - previousPoint.x) / step;
        final stepY = (point.y - previousPoint.y) / step;
        final stepWidth = (point.w - previousPoint.w) / step;

        _StrokeCanvasPoint previousSetPoint = previousPoint;
        for (var i = 1; i <= step; i++) {
          final setpPoint = _StrokeCanvasPoint(
            previousPoint.x + stepX * i,
            previousPoint.y + stepY * i,
            w: previousPoint.w + stepWidth * i,
          );

          pen.addLine(previousSetPoint, setpPoint);

          previousSetPoint = setpPoint;

          if (i == step) {
            // 最后一个点
            pen.previousPoint = setpPoint;
          }
        }
      } else {
        // 不需要插入点，直接绘制
        pen.addLine(previousPoint, point);

        pen.previousPoint = point;
      }
    }
  }

  /// 添加图片
  void _addImage(
    ui.Image image, {
    Rect? rect,
    Alignment alignment = Alignment.center,
    BoxFit fit = BoxFit.fill,
    ColorFilter? colorFilter,
    bool needDraw = true,
  }) {
    if (_isDispose) return;

    if (rect != null) {
      rect = ui.Rect.fromLTWH(
        rect.left * _pixelRatio,
        rect.top * _pixelRatio,
        rect.width * _pixelRatio,
        rect.height * _pixelRatio,
      );
    }

    final img = _StrokeCanvasPaintableImage(
      image: _StrokeCanvasImage(image),
      width: _sizeWidth,
      height: _sizeHeight,
      pixelRatio: _pixelRatio,
      rect: rect,
      alignment: alignment,
      fit: fit,
      colorFilter: colorFilter,
    );

    _addDrawable(img);
  }

  void _addDrawable(_StrokeCanvasPaintable d, [int? insertIdx]) {
    if (insertIdx != null) {
      _drawables.insert(insertIdx, d);
    } else {
      _drawables.add(d);
    }

    if (_drawables.length >= 10) {
      _drawingDrawables.append(_drawables);
      _drawables = _StrokeCanvasPaintableList();
      _compress();
    }
  }

  Future<void> _compress() async {
    final tage = _cleanCount;
    final image = await _paintToImage(_drawingDrawables);

    if (tage == _cleanCount) {
      final img = _StrokeCanvasPaintableImage(
        image: _StrokeCanvasImage(image),
        width: _sizeWidth,
        height: _sizeHeight,
        pixelRatio: _pixelRatio,
      );

      _addDrawable(img, 0);

      _drawingDrawables.dispose();

      _drawingDrawables = _StrokeCanvasPaintableList();

      _isShouldPaint = true;
    } else {
      image.dispose();
    }
  }

  Future<ui.Image> _paintToImage(_StrokeCanvasPaintableList drawbles) async {
    final recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    canvas.clipRect(Rect.fromLTWH(0, 0, _sizeWidth, _sizeHeight));
    canvas.scale(_pixelRatio);

    drawbles.paint(canvas, ui.Size(_sizeWidth, _sizeHeight));

    final p = recorder.endRecording();

    final image = await p.toImage(_sizeWidth.toInt(), _sizeHeight.toInt());

    p.dispose();

    return image;
  }

  /// 创建空的图片
  Future<ui.Image> _createEmptyImage() async {
    final recorder = ui.PictureRecorder();
    final _ = Canvas(recorder);
    final p = recorder.endRecording();
    final img = await p.toImage(_sizeWidth.toInt(), _sizeHeight.toInt());
    p.dispose();
    return img;
  }
}
