part of 'stroke_canvas.dart';

/// 画布的绘制模式。
/// 如果绘制时不需要橡皮功能，则使用[hd]模式。
/// 需要橡皮功能则使用[supportEraser]模式。
enum StrokeCanvasPaintMode {
  /// 采用矢量绘制模式，绘制效果极佳，但是在进行Widget缩放时会有性能问题。
  hd,

  /// 支持橡皮的绘制模式，使用位图和矢量图混合渲染，绘制质量稍差。
  supportEraser,
}

/// 绘制的路径的类型
enum StrokeCanvasPaintPathType {
  /// 连线模式
  line,

  /// 打点模式
  point,
}

/// 用来进行画布绘制的class。
class StrokeCanvasPainter {
  /// 初始化方法。
  /// 需要使用[size]方法设置绘制的区域大小。
  /// [pixelRatio]设置为[MediaQuery.devicePixelRatio]。
  /// [lineColor]设置默认的笔迹颜色。
  /// [strokeWidth]和[eraserWidth]设置笔迹和橡皮的默认宽度。
  /// 如果[isEraser]传入true，则画面会变成橡皮模式。
  /// [mode]决定了当前绘制的模式，如果为[StrokeCanvasPaintMode.hd]模式，则[eraserWidth]、[isEraser]参数无效。
  /// [pathType]参数可以设置绘制路径的类型，[pathAlpha]可以设置路径的透明度。
  StrokeCanvasPainter({
    Size size = const Size(1, 1),
    double pixelRatio = 1,
    Color lineColor = Colors.black,
    double strokeWidth = 3,
    double eraserWidth = 30,
    bool isEraser = false,
    StrokeCanvasPaintMode mode = StrokeCanvasPaintMode.supportEraser,
    StrokeCanvasPaintPathType pathType = StrokeCanvasPaintPathType.line,
    int pathAlpha = 255,
  })  : assert(pixelRatio > 0),
        assert(size.width > 0 || size.height > 0),
        assert(strokeWidth > 0),
        _mode = mode,
        _size = size,
        _pixelRatio = pixelRatio,
        _sizeWidth = (size.width * pixelRatio).ceil().toDouble(),
        _sizeHeight = (size.height * pixelRatio).ceil().toDouble() {
    final info = _getPen(kStrokeCanvasPainterDefaultPenId);
    info.strokeWidth = strokeWidth;
    info.eraserWidth = eraserWidth;
    info.lineColor = lineColor;
    info.isEraser = false;
    info.pathType = pathType;
    info.pathAlpha = pathAlpha;
  }

  /// [StrokeCanvasPaintMode.hd]绘制模式的构造函数。
  StrokeCanvasPainter.hd({
    Size size = const Size(1, 1),
    double pixelRatio = 1,
    Color lineColor = Colors.black,
    double strokeWidth = 3,
    StrokeCanvasPaintPathType pathType = StrokeCanvasPaintPathType.line,
    int pathAlpha = 255,
  })  : assert(pixelRatio > 0),
        assert(size.width > 0 || size.height > 0),
        assert(strokeWidth > 0),
        _mode = StrokeCanvasPaintMode.hd,
        _size = size,
        _pixelRatio = pixelRatio,
        _sizeWidth = size.width.ceil().toDouble(),
        _sizeHeight = size.height.ceil().toDouble() {
    final info = _getPen(kStrokeCanvasPainterDefaultPenId);
    info.strokeWidth = strokeWidth;
    info.lineColor = lineColor;
    info.pathType = pathType;
    info.pathAlpha = pathAlpha;
  }

  /// [StrokeCanvasPaintMode.supportEraser]模式的构造函数。
  StrokeCanvasPainter.supportEraser({
    Size size = const Size(1, 1),
    double pixelRatio = 1,
    Color lineColor = Colors.black,
    double strokeWidth = 3,
    double eraserWidth = 30,
    bool isEraser = false,
    StrokeCanvasPaintPathType pathType = StrokeCanvasPaintPathType.line,
    int pathAlpha = 255,
  })  : assert(pixelRatio > 0),
        assert(size.width > 0 || size.height > 0),
        assert(strokeWidth > 0),
        _mode = StrokeCanvasPaintMode.supportEraser,
        _size = size,
        _pixelRatio = pixelRatio,
        _sizeWidth = (size.width * pixelRatio).ceil().toDouble(),
        _sizeHeight = (size.height * pixelRatio).ceil().toDouble() {
    final info = _getPen(kStrokeCanvasPainterDefaultPenId);
    info.strokeWidth = strokeWidth;
    info.eraserWidth = eraserWidth;
    info.lineColor = lineColor;
    info.isEraser = false;
    info.pathType = pathType;
    info.pathAlpha = pathAlpha;
  }

  /// 绘制模式
  final StrokeCanvasPaintMode _mode;

  /// 当前绘制的大小
  Size _size;

  /// 所属的widget的大小
  Size? _widgetSize;

  /// 当前绘制的大小
  Size get size => _size;

  /// 当前绘制的大小
  set size(Size value) {
    if (value.width == _size.width && value.height == _size.height) return;

    _size = value;

    // 计算绘制大小
    _sizeWidth = (value.width * pixelRatio).ceil().toDouble();

    _sizeHeight = (value.height * pixelRatio).ceil().toDouble();

    _isShouldPaint = true;
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

    _isShouldPaint = true;
  }

  /// 默认的橡皮模式
  bool get isEraser => getIsEraser();

  /// 默认橡皮模式
  set isEraser(bool isEraser) => setIsEraser(isEraser);

  /// 设置画橡皮模式
  void setIsEraser(bool isEraser,
      {String penId = kStrokeCanvasPainterDefaultPenId}) {
    if (_mode == StrokeCanvasPaintMode.hd) return;

    final info = _getPen(penId);
    if (info.isEraser != isEraser) {
      info.isEraser = isEraser;
      info.closedPath();
    }
  }

  /// 获取橡皮模式
  bool getIsEraser({String penId = kStrokeCanvasPainterDefaultPenId}) {
    if (_mode == StrokeCanvasPaintMode.hd) return false;

    return _getPen(penId).isEraser;
  }

  /// 默认的笔画颜色
  Color get lineColor => getLineColor();

  /// 默认的笔画颜色
  set lineColor(Color value) => setLineColor(value);

  /// 获取画笔颜色
  Color getLineColor({String penId = kStrokeCanvasPainterDefaultPenId}) {
    return _getPen(penId).lineColor;
  }

  /// 设置画笔颜色
  void setLineColor(Color color,
      {String penId = kStrokeCanvasPainterDefaultPenId}) {
    final info = _getPen(penId);
    if (info.lineColor.value != color.value) {
      info.lineColor = color;
      info.closedPath();
    }
  }

  /// 默认的笔画宽度。
  double get strokeWidth => getStrokeWidth();

  /// 默认的笔画宽度。
  set strokeWidth(double value) => setStrokeWidth(value);

  /// 获取画笔宽度
  double getStrokeWidth({String penId = kStrokeCanvasPainterDefaultPenId}) {
    return _getPen(penId).strokeWidth;
  }

  /// 设置画笔宽度
  void setStrokeWidth(double width,
      {String penId = kStrokeCanvasPainterDefaultPenId}) {
    _getPen(penId).strokeWidth = width;
  }

  /// 默认的橡皮宽度。
  double get eraserWidth => getEraserWidth();

  /// 默认的橡皮宽度。
  set eraserWidth(double value) => setEraserWidth(value);

  /// 获取橡皮宽度
  double getEraserWidth({String penId = kStrokeCanvasPainterDefaultPenId}) {
    if (_mode == StrokeCanvasPaintMode.hd) return 0;

    return _getPen(penId).eraserWidth;
  }

  /// 设置橡皮宽度
  void setEraserWidth(double width,
      {String penId = kStrokeCanvasPainterDefaultPenId}) {
    if (_mode == StrokeCanvasPaintMode.hd) return;
    _getPen(penId).eraserWidth = width;
  }

  /// 路径类型
  StrokeCanvasPaintPathType get pathType => getPathType();
  set pathType(StrokeCanvasPaintPathType v) => setPathType(v);

  /// 获取路径类型
  StrokeCanvasPaintPathType getPathType(
      {String penId = kStrokeCanvasPainterDefaultPenId}) {
    return _getPen(penId).pathType;
  }

  /// 设置路径类型
  void setPathType(StrokeCanvasPaintPathType type,
      {String penId = kStrokeCanvasPainterDefaultPenId}) {
    _getPen(penId).pathType = type;
  }

  /// 路径透明度
  int get pathAlpha => getPathAlpha();

  /// 路径透明度
  set pathAlpha(int v) => setPathAlpha(v);

  /// 获路径透明度
  int getPathAlpha({String penId = kStrokeCanvasPainterDefaultPenId}) {
    return _getPen(penId).pathAlpha;
  }

  /// 设置路径透明度
  void setPathAlpha(int v, {String penId = kStrokeCanvasPainterDefaultPenId}) {
    _getPen(penId).pathAlpha = v;
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
    int alpha = 255,
  }) {
    _addImage(
      image,
      rect: rect,
      alignment: alignment,
      fit: fit,
      colorFilter: colorFilter,
      alpha: alpha,
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
    int alpha = 255,
  }) {
    _addImage(
      image,
      rect: rect,
      alignment: alignment,
      fit: fit,
      colorFilter: colorFilter,
      alpha: alpha,
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

    _paintableWidgets = [];
    _paintables.dispose();
    _paintables = _StrokeCanvasPaintableList();
    _mergingPaintables.dispose();
    _mergingPaintables = _StrokeCanvasPaintableList();

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
      img = await _createEmptyImage(_sizeWidth, _sizeHeight);
    } else {
      _StrokeCanvasPaintableList _trailPaths = _StrokeCanvasPaintableList();
      _trailPaths.addAll(_mergingPaintables);
      _trailPaths.addAll(_paintables);
      for (var info in _pens.values) {
        if (info.path.isNotEmpty) {
          _trailPaths.add(info.path);
        }
      }

      img = await _paintToImage(_trailPaths, _sizeWidth, _sizeHeight);
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
      info = _StrokeCanvasPen(onClosedPath: (path) => _addPaintable(path));
      _pens[penId] = info;
    }

    return info;
  }

  /// 可绘制对象的集合。
  /// 此集合中往往存放着很多矢量图片数据，矢量数据太多会严重拖累绘制性能，
  /// 所以当数量超过[_mergeThreshold]后，需要将矢量数据转成位图数据，
  /// 这个转成位图的过程称为“合并”。
  _StrokeCanvasPaintableList _paintables = _StrokeCanvasPaintableList();

  /// 合并中的可绘制对象集合。
  /// 合并前会将[_paintables]集合中的对象转移到这个集合中，等待进行合并。
  _StrokeCanvasPaintableList _mergingPaintables = _StrokeCanvasPaintableList();

  /// 绘制的Widget集合，在hd模式下，用来保存绘制的笔迹，提高绘制性能
  List<Widget> _paintableWidgets = [];

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
    final point = _StrokeCanvasPoint(
      x * _pixelRatio,
      y * _pixelRatio,
      w: (isEraser ? eraserW : penW) * _pixelRatio,
    );

    final previousPoint = pen.previousPoint;

    if (pen.pathType == StrokeCanvasPaintPathType.point ||
        previousPoint == null ||
        point.same(previousPoint)) {
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
    int alpha = 255,
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
      alpha: alpha,
    );

    _addPaintable(img);
  }

  // 添加可绘制对象
  void _addPaintable(_StrokeCanvasPaintable d, [int? insertIdx]) {
    if (_mode == StrokeCanvasPaintMode.hd) {
      // 高清模式，将paintable转成picture
      _StrokeCanvasPaintablePictrue paintablePictrue;
      if (d is _StrokeCanvasPaintablePictrue) {
        paintablePictrue = d;
      } else {
        paintablePictrue = _StrokeCanvasPaintablePictrue(
          picture: _paintToPicture(d, _sizeHeight, _sizeHeight),
          width: _sizeHeight,
          height: _sizeHeight,
        );
      }
      // 创建widget
      final pictureWidget = RepaintBoundary(
        child: CustomPaint(
          isComplex: true,
          painter: _StrokeCanvasCustomPainter(
            paintable: paintablePictrue,
            pixelRatio: pixelRatio,
            painter: this,
          ),
          size: _size,
        ),
      );

      if (insertIdx != null) {
        _paintables.insert(insertIdx, paintablePictrue);
        _paintableWidgets.insert(insertIdx, pictureWidget);
      } else {
        _paintables.add(paintablePictrue);
        _paintableWidgets.add(pictureWidget);
      }
    } else {
      if (insertIdx != null) {
        _paintables.insert(insertIdx, d);
      } else {
        _paintables.add(d);
      }
    }

    if (_paintables.length >= _mergeThreshold) {
      // 但数量大于等于10时，合并可绘制对象，节约内存和性能。
      _mergingPaintables.addAll(_paintables);
      _paintables = _StrokeCanvasPaintableList();

      _mergePaintables();
    }
  }

  /// 合并可绘制对象
  Future<void> _mergePaintables() async {
    if (_mode == StrokeCanvasPaintMode.hd) {
      final pictrue = _paintToPaintablePicture(
        _mergingPaintables,
        _sizeWidth,
        _sizeHeight,
      );
      // 1. 一定要先清空之前的widget
      _paintableWidgets = [];
      // 2. 再重新插入到可绘制对象集合中的第一个位置
      _addPaintable(pictrue, 0);
      // 释放数据
      _mergingPaintables.dispose();
      // 新建列表
      _mergingPaintables = _StrokeCanvasPaintableList();

      // 标记当前需要绘制
      _isShouldPaint = true;
    } else {
      // 存储一下画布清理次数
      final tage = _cleanCount;
      // 将可绘制对象绘制到位图中，异步操作
      final image = await _paintToPaintableImage(
        _mergingPaintables,
        _sizeWidth,
        _sizeHeight,
        _pixelRatio,
      );

      // 如果合并完成后，画布清理数据没有变，说明画布没进行清理操作
      if (tage == _cleanCount) {
        // 重新插入到可绘制对象集合中的第一个位置
        _addPaintable(image, 0);
        // 释放数据
        _mergingPaintables.dispose();
        // 新建列表
        _mergingPaintables = _StrokeCanvasPaintableList();
        // 标记当前需要绘制
        _isShouldPaint = true;
      } else {
        // 画布已经清理了，把图片释放掉
        image.dispose();
      }
    }
  }
}
