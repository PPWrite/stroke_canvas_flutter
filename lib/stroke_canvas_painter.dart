part of 'stroke_canvas.dart';

class StrokeCanvasPainter {
  StrokeCanvasPainter({
    Size size = const Size(1, 1),
    double pixelRatio = 1,
    Color lineColor = Colors.black,
    double strokeWidth = 3,
    double eraserWidth = 30,
    bool isEraser = false,
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
    info.eraserWidth = eraserWidth;
    info.isEraser = false;
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

  /// 默认的橡皮模式
  bool get isEraser => getIsEraser();

  /// 默认橡皮模式
  set isEraser(bool isEraser) => setIsEraser(isEraser);

  /// 设置画橡皮模式
  void setIsEraser(bool isEraser,
      {String penId = kStrokeCanvasPainterDefaultPenId}) {
    final info = _getPen(penId);
    if (info.isEraser != isEraser) {
      info.isEraser = isEraser;
      info.closedPath();
    }
  }

  /// 获取橡皮模式
  bool getIsEraser({String penId = kStrokeCanvasPainterDefaultPenId}) {
    return _getPen(penId).isEraser;
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

  /// 默认的橡皮宽度。
  double get eraserWidth => getEraserWidth();

  /// 默认的橡皮宽度。
  set eraserWidth(double value) => setEraserWidth(value);

  /// 设置橡皮宽度
  void setEraserWidth(double width,
      {String penId = kStrokeCanvasPainterDefaultPenId}) {
    _getPen(penId).eraserWidth = width;
  }

  /// 获取橡皮宽度
  double getEraserWidth({String penId = kStrokeCanvasPainterDefaultPenId}) {
    return _getPen(penId).eraserWidth;
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

  /// 添加图片但不触发绘制操作，直到主动调用[shouldPaint]相关方法或者其他绘制操作。
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
    _mergingDrawables.dispose();
    _mergingDrawables = _StrokeCanvasPaintableList();

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
      _trailPaths.append(_mergingDrawables);
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

  /// 标记当前是否需要绘制。
  /// 这个值可以告诉[StrokeCanvas]这个widget是否需要更新。
  /// 每一次帧刷新时，如果此值为true，
  /// [StrokeCanvas]就会将当前的画布数据绘制到UI界面上，并将当前属性改为false。
  bool _isShouldPaint = false;

  /// 笔的信息
  final Map<String, _StrokeCanvasPen> _pens = {};

  /// 根据笔id获取笔信息
  _StrokeCanvasPen _getPen(String penId) {
    var info = _pens[penId];
    if (info == null) {
      // 创建笔信息，并且在笔关闭绘制路径的回调中绘制路径
      info = _StrokeCanvasPen(onClosedPath: (path) => _addDrawable(path));
      _pens[penId] = info;
    }

    return info;
  }

  /// 可绘制对象的集合。
  /// 此集合中往往存放着很多矢量图片数据，矢量数据太多会严重拖累绘制性能，
  /// 所以当数量超过[_mergeThreshold]后，需要将矢量数据转成位图数据，
  /// 这个转成位图的过程称为“合并”。
  _StrokeCanvasPaintableList _drawables = _StrokeCanvasPaintableList();

  /// 合并中的可绘制对象集合。
  /// 合并前会将[_drawables]集合中的对象转移到这个集合中，等待进行合并。
  _StrokeCanvasPaintableList _mergingDrawables = _StrokeCanvasPaintableList();

  /// 触发合并操作的阈值。
  final int _mergeThreshold = 10;

  void _addPoint(
    double x,
    double y, {
    required String penId,
    double? width,
    bool needDraw = true,
  }) {
    if (_isDispose) return;

    final pen = _getPen(penId);
    double penW = width ?? strokeWidth;
    double eraserW = width ?? eraserWidth;
    //设置笔宽度和橡皮宽度
    final point = _StrokeCanvasPoint(x, y, w: isEraser ? eraserW : penW);

    final previousPoint = pen.previousPoint;

    if (previousPoint == null || point.same(previousPoint)) {
      // 没有最后一个点，或者最后一个点和当前点坐标相同，
      // 则只需要再绘制一个点就行
      //_paintPoint(canvas, paint, point);
      pen.addPoint(point);
      pen.previousPoint = point;
    } else {
      // 将当前点和上一点的距离，作为插点的数量
      var pointNum = point.distance(previousPoint).toInt();
      // 为了让线条更平滑，将插点数量增加三倍，
      // 非常影响性能，先注释掉了
      // pointNum *= 3;

      // 插入点
      if (pointNum > 1) {
        // x步进值
        final stepX = (point.x - previousPoint.x) / pointNum;
        // y步进值
        final stepY = (point.y - previousPoint.y) / pointNum;
        // 宽度步进值
        final stepWidth = (point.w - previousPoint.w) / pointNum;

        // 插点过程中的上一个点
        _StrokeCanvasPoint previousStepPoint = previousPoint;
        for (var i = 1; i <= pointNum; i++) {
          // 计算插点坐标和宽度
          final setpPoint = _StrokeCanvasPoint(
            previousPoint.x + stepX * i,
            previousPoint.y + stepY * i,
            w: previousPoint.w + stepWidth * i,
          );
          // 绘制
          pen.addLine(previousStepPoint, setpPoint);
          // 当前点成为下一个循环的上一个点
          previousStepPoint = setpPoint;

          if (i == pointNum) {
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

  // 添加可绘制对象
  void _addDrawable(_StrokeCanvasPaintable d, [int? insertIdx]) {
    if (insertIdx != null) {
      _drawables.insert(insertIdx, d);
    } else {
      _drawables.add(d);
    }

    if (_drawables.length >= _mergeThreshold) {
      // 但数量大于等于10时，合并可绘制对象，节约内存和性能。
      _mergingDrawables.append(_drawables);
      _drawables = _StrokeCanvasPaintableList();
      _mergeDrawables();
    }
  }

  /// 合并可绘制对象
  Future<void> _mergeDrawables() async {
    // 存储一下画布清理次数
    final tage = _cleanCount;
    // 将可绘制对象绘制到位图中，异步操作
    final image = await _paintToImage(_mergingDrawables);

    // 如果合并完成后，画布清理数据没有变，说明画布没进行清理操作
    if (tage == _cleanCount) {
      final img = _StrokeCanvasPaintableImage(
        image: _StrokeCanvasImage(image),
        width: _sizeWidth,
        height: _sizeHeight,
        pixelRatio: _pixelRatio,
      );

      // 重新插入到可绘制对象集合中的第一个位置
      _addDrawable(img, 0);
      // 释放数据
      _mergingDrawables.dispose();
      // 新建列表
      _mergingDrawables = _StrokeCanvasPaintableList();
      // 标记当前需要绘制
      _isShouldPaint = true;
    } else {
      // 画布已经清理了，把图片释放掉
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
