part of 'stroke_canvas.dart';

abstract class _StrokeCanvasPaintable {
  void paint(ui.Canvas canvas, Size size);
  void dispose();

  @override
  int get hashCode;

  @override
  bool operator ==(Object other);
}

class _StrokeCanvasPaintablePath extends _StrokeCanvasPaintable {
  _StrokeCanvasPaintablePath({Path? path, Color? color})
      : path = path ?? Path(),
        _color = color ?? Colors.black {
    _cacheHash = hashValues(_cacheHash, _color.value);
  }

  int _cacheHash = 0;

  Path path;
  Color _color;
  Color get color => _color;
  set color(ui.Color value) {
    _color = value;
    _cacheHash = hashValues(_cacheHash, _color.value);
  }

  bool _isEmpty = true;
  bool get isEmpty => _isEmpty;
  bool get isNotEmpty => !_isEmpty;

  Paint get _paint => Paint()
    ..color = color
    ..isAntiAlias = true
    ..style = PaintingStyle.fill;

  void addPoint(_StrokeCanvasPoint point) {
    path.addArc(
        Rect.fromCircle(center: Offset(point.x, point.y), radius: point.w / 2),
        0,
        2 * pi);
    _isEmpty = false;
    _cacheHash = hashValues(_cacheHash, point);
  }

  void addLine(
    _StrokeCanvasPoint p1,
    _StrokeCanvasPoint p2,
  ) {
    // 两个点相减得到一个向量， 并进行标准化，然后逆时针旋转90度。
    final perpendicular = (p2 - p1).normalize().perpendicular();

    // 计算出宽度向量。
    final widthDir1 = perpendicular * (p1.w / 2);

    final widthDir2 = perpendicular * (p2.w / 2);

    //
    //   pa             pc
    //    *-------------*
    //    |             |
    // p1 *------------>* p2
    //    |             |
    //    *-------------*
    //   pb             pd
    //

    final pa = p1 + widthDir1;
    // final pb = p1 - widthDir1;
    // final pc = p2 + widthDir2;
    final pd = p2 - widthDir2;

    // a点弧度
    final par = widthDir1.radian();
    // b点在a点对面，所以b点弧度 = par + pi;
    var pbr = par + pi;
    if (pbr > pi) {
      pbr = pbr - 2 * pi;
    }

    // c点弧度
    final pcr = widthDir2.radian();
    // d点弧度
    var pdr = pcr + pi;
    if (pdr > pi) {
      pdr = pdr - 2 * pi;
    }

    path.moveTo(pa.x, pa.y);

    // 创建一个两头半圆形行的形状。
    // 绘制线段开始的圆弧
    path.addArc(
        Rect.fromLTWH(p1.x - p1.w / 2, p1.y - p1.w / 2, p1.w, p1.w), par, pi);

    // 下边框
    path.lineTo(pd.x, pd.y);

    // 绘制结束的圆弧
    path.addArc(
        Rect.fromLTWH(p2.x - p2.w / 2, p2.y - p2.w / 2, p2.w, p2.w), pdr, pi);

    // 上边框
    path.lineTo(pa.x, pa.y);

    _isEmpty = false;

    _cacheHash = hashValues(_cacheHash, p1);
    _cacheHash = hashValues(_cacheHash, p2);
  }

  @override
  void paint(ui.Canvas canvas, Size size) => canvas.drawPath(path, _paint);

  @override
  void dispose() {}

  @override
  int get hashCode => _cacheHash;

  @override
  bool operator ==(Object other) {
    return other is _StrokeCanvasPaintablePath && hashCode == other.hashCode;
  }
}

class _StrokeCanvasPaintableImage extends _StrokeCanvasPaintable {
  _StrokeCanvasPaintableImage({
    required this.image,
    required this.width,
    required this.height,
    this.pixelRatio = 1,
    this.rect,
    this.alignment = Alignment.center,
    this.fit = BoxFit.fill,
    this.colorFilter,
  }) : _cacheHash = hashValues(
          image.image,
          width,
          height,
          pixelRatio,
          rect,
          alignment,
          fit,
          colorFilter,
        );

  final _StrokeCanvasImage image;
  final double width;
  final double height;
  final double pixelRatio;
  final Rect? rect;
  final Alignment alignment;
  final BoxFit fit;
  final ColorFilter? colorFilter;

  final int _cacheHash;

  @override
  void paint(ui.Canvas canvas, Size size) {
    if (image.isDispose) return;

    canvas.save();
    canvas.scale(1 / pixelRatio, 1 / pixelRatio);
    canvas.clipRect(Rect.fromLTWH(0, 0, width, height));

    var rect = this.rect;
    rect ??= Rect.fromLTWH(0, 0, width, height);

    paintImage(
      canvas: canvas,
      rect: rect,
      image: image.image,
      fit: fit,
      alignment: alignment,
      colorFilter: colorFilter,
      isAntiAlias: true,
    );

    canvas.restore();
  }

  @override
  void dispose() {
    image.dispose();
  }

  @override
  int get hashCode => _cacheHash;

  @override
  bool operator ==(Object other) {
    return other is _StrokeCanvasPaintableImage && hashCode == other.hashCode;
  }
}

class _StrokeCanvasPaintableList extends _StrokeCanvasPaintable {
  final List<_StrokeCanvasPaintable> _drawables = [];
  List<_StrokeCanvasPaintable> get drawables => _drawables;

  int _cacheHash = 0;

  int get length => _drawables.length;

  void add(_StrokeCanvasPaintable drawable) {
    _drawables.add(drawable);
    _cacheHash = ui.hashValues(_cacheHash, drawable);
  }

  void append(_StrokeCanvasPaintableList list) {
    _drawables.addAll(list._drawables);
    _cacheHash = ui.hashValues(_cacheHash, list);
  }

  void insert(int index, _StrokeCanvasPaintable drawable) {
    _drawables.insert(index, drawable);
    _cacheHash = ui.hashValues(_cacheHash, drawable, index);
  }

  @override
  void dispose() {
    for (var item in drawables) {
      item.dispose();
    }
  }

  @override
  void paint(ui.Canvas canvas, Size size) {
    for (var item in drawables) {
      item.paint(canvas, size);
    }
  }

  @override
  int get hashCode => _cacheHash;

  @override
  bool operator ==(Object other) {
    return other is _StrokeCanvasPaintableList && hashCode == other.hashCode;
  }
}
