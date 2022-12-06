part of 'stroke_canvas.dart';

const String kStrokeCanvasPainterDefaultPenId = "robot_pen";

class _StrokeCanvasPen {
  _StrokeCanvasPen({
    required this.onClosedPath,
    Color lineColor = Colors.black,
    bool isEraser = false,
    int pathAlpha = 255,
  })  : _lineColor = lineColor,
        _pathAlpha = min(255, max(0, pathAlpha)),
        path = _StrokeCanvasPaintablePath(
          color: isEraser ? Colors.transparent : lineColor,
          isEraser: isEraser,
          alpha: min(255, max(0, pathAlpha)),
        ),
        _isEraser = isEraser;

  /// 默认的笔画宽度。
  double strokeWidth = 3;

  /// 默认的橡皮宽度。
  double eraserWidth = 30;

  /// 划线类型
  StrokeCanvasPaintPathType pathType = StrokeCanvasPaintPathType.line;

  /// 路径透明度
  int _pathAlpha;

  /// 路径透明度
  int get pathAlpha => _pathAlpha;
  set pathAlpha(int v) {
    if (v == _pathAlpha) return;

    _pathAlpha = min(255, max(0, v));
    path.alpha = _pathAlpha;
  }

  /// 关闭路径的回调
  void Function(_StrokeCanvasPaintablePath path) onClosedPath;

  /// 上一个点
  _StrokeCanvasPoint? previousPoint;

  bool _isEraser;

  /// 是否是橡皮模式
  bool get isEraser => _isEraser;
  set isEraser(bool value) {
    if (value == _isEraser) return;
    _isEraser = value;
    closedPath();
  }

  /// 默认的笔画颜色
  Color _lineColor;

  /// 默认的笔画颜色
  Color get lineColor => _lineColor;
  set lineColor(Color v) {
    if (v == _lineColor) return;
    _lineColor = v;
    closedPath();
  }

  /// 绘制的路径
  _StrokeCanvasPaintablePath path;

  int pointCount = 0;

  /// 触发关闭路径的阈值
  final int closePathThreshold = 3000;

  /// 添加一个点
  void addPoint(_StrokeCanvasPoint point) {
    // 将点添加到路径
    path.addPoint(point);

    pointCount++;
    if (pointCount > closePathThreshold) {
      // 如果点超过阈值，就关闭路径，避免累计太多影响绘制性能。
      pointCount = 0;
      closedPath();
    }
  }

  // 添加一条线
  void addLine(_StrokeCanvasPoint p1, _StrokeCanvasPoint p2) {
    // 将线添加到路径
    path.addLine(p1, p2);

    pointCount++;
    if (pointCount > closePathThreshold) {
      pointCount = 0;
      closedPath();
    }
  }

  void newPath() {
    pointCount = 0;
    path = _StrokeCanvasPaintablePath(
      color: _isEraser ? Colors.transparent : _lineColor,
      isEraser: _isEraser,
      alpha: _pathAlpha,
    );
  }

  void closedPath() {
    if (path.isNotEmpty) onClosedPath(path);
    newPath();
  }
}

class _StrokeCanvasImage {
  _StrokeCanvasImage(this.image);
  ui.Image image;
  bool isDispose = false;

  void dispose() {
    if (isDispose) return;

    isDispose = true;
    image.dispose();
  }
}

class _StrokeCanvasPoint {
  final double x;
  final double y;
  final double w;

  const _StrokeCanvasPoint(this.x, this.y, {this.w = 0});

  /// 是否和另一个点坐标相同。
  bool same(_StrokeCanvasPoint other) => x == other.x && y == other.y;

  /// 加法
  _StrokeCanvasPoint operator +(_StrokeCanvasPoint other) =>
      _StrokeCanvasPoint(x + other.x, y + other.y, w: w);

  /// 减法
  _StrokeCanvasPoint operator -(_StrokeCanvasPoint other) =>
      _StrokeCanvasPoint(x - other.x, y - other.y, w: w);

  /// 减法
  _StrokeCanvasPoint operator *(double s) =>
      _StrokeCanvasPoint(x * s, y * s, w: w);

  /// 点到原点的长度
  double length() => sqrt(x * x + y * y);

  double distance(_StrokeCanvasPoint other) => (this - other).length();

  /// 计算和另一个点之间的距离，算法为：两个点的距离 - 两个点宽度之合
  double space(_StrokeCanvasPoint other) => distance(other) - (w + other.w);

  /// 标准化向量。
  _StrokeCanvasPoint normalize() {
    final length = this.length();

    double x = 0;
    double y = 0;

    if (length != 0) {
      x = this.x / length;
      y = this.y / length;
    }

    return _StrokeCanvasPoint(x, y, w: w);
  }

  /// 向量逆时针旋转90度
  _StrokeCanvasPoint perpendicular() => _StrokeCanvasPoint(0 - y, x, w: w);

  /// 计算向量点和0弧度之间的夹角弧度
  double radian() {
    var r1 = atan2(y, x) - atan2(0, 1);
    if (r1 > pi) {
      r1 = r1 - 2 * pi;
    } else if (r1 < 0 - pi) {
      r1 = r1 + 2 * pi;
    }
    return r1;
  }

  @override
  int get hashCode => Object.hash(x, y, w);

  @override
  bool operator ==(Object other) {
    return other is _StrokeCanvasPoint &&
        x == other.x &&
        y == other.y &&
        w == other.w;
  }
}
