part of 'stroke_canvas.dart';

// 可绘制对象的抽象
abstract class _StrokeCanvasPaintable {
  /// 绘制到Canvas
  void paint(ui.Canvas canvas, Size size);

  /// 释放数据
  @mustCallSuper
  void dispose() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  @override
  int get hashCode;

  @override
  bool operator ==(Object other);
}

/// 可绘制路径对象
class _StrokeCanvasPaintablePath extends _StrokeCanvasPaintable {
  _StrokeCanvasPaintablePath({
    Path? path,
    Color? color,
    this.isEraser = false,
  })  : path = path ?? Path(),
        _color = color ?? Colors.black,
        _paint = Paint()
          ..color = color ?? Colors.black
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..filterQuality = ui.FilterQuality.medium
          ..blendMode = isEraser ? BlendMode.clear : BlendMode.srcOver {
    _cacheHash = Object.hash(_cacheHash, _color.value);
  }

  int _cacheHash = 0;
  final bool isEraser;
  final Path path;
  Color _color;
  final Paint _paint;

  Color get color => _color;
  set color(Color v) {
    _color = v;
    _paint.color = v;
  }

  bool _isEmpty = true;
  bool get isEmpty => _isEmpty;
  bool get isNotEmpty => !_isEmpty;

  /// 添加一点
  void addPoint(_StrokeCanvasPoint point) {
    // 就是绘制一个实心圆
    path.addArc(
        Rect.fromCircle(center: Offset(point.x, point.y), radius: point.w / 2),
        0,
        2 * pi);
    _isEmpty = false;
    // 重新计算hash
    _cacheHash = Object.hash(_cacheHash, point);
  }

  /// 添加一条线。
  /// 并不是简单的连成一条线，因为两个点可能宽度不同。
  /// 而是同自行车链条图形，链条缠绕前大齿轮和后小齿轮，组成两头半圆中间梯形的现状，
  /// 参数[p1]和][p2]就是两个齿轮的中心点。
  void addLine(
    _StrokeCanvasPoint p1,
    _StrokeCanvasPoint p2,
  ) {
    _isEmpty = false;

    _cacheHash = Object.hash(_cacheHash, p1);
    _cacheHash = Object.hash(_cacheHash, p2);

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
  }

  @override
  void paint(ui.Canvas canvas, Size size) {
    canvas.drawPath(path, _paint);
  }

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
    this.alignment = Alignment.topLeft,
    this.fit = BoxFit.fill,
    this.colorFilter,
  }) : _cacheHash = Object.hash(
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
      filterQuality: ui.FilterQuality.medium,
    );

    canvas.restore();
  }

  @override
  void dispose() {
    super.dispose();
    image.dispose();
  }

  @override
  int get hashCode => _cacheHash;

  @override
  bool operator ==(Object other) {
    return other is _StrokeCanvasPaintableImage && hashCode == other.hashCode;
  }
}

class _StrokeCanvasPaintablePictrue extends _StrokeCanvasPaintable {
  _StrokeCanvasPaintablePictrue({
    required this.picture,
    required this.width,
    required this.height,
  }) {
    _cacheHash = Object.hash(_cacheHash, picture);
  }
  final ui.Picture picture;
  final double width;
  final double height;

  @override
  void dispose() {
    super.dispose();
    picture.dispose();
  }

  int _cacheHash = 0;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, width, height));
    canvas.drawPicture(picture);
    canvas.restore();
  }

  @override
  int get hashCode => _cacheHash;

  @override
  bool operator ==(Object other) {
    return other is _StrokeCanvasPaintablePictrue && hashCode == other.hashCode;
  }
}

/// 可绘制对象的集合
class _StrokeCanvasPaintableList<M extends _StrokeCanvasPaintable>
    extends _StrokeCanvasPaintable implements List<M> {
  final List<M> _paintables = [];
  List<M> get paintables => _paintables;

  int _cacheHash = 0;

  @override
  int get length => _paintables.length;

  @override
  void dispose() {
    super.dispose();
    for (var item in paintables) {
      item.dispose();
    }
  }

  @override
  void paint(ui.Canvas canvas, Size size) {
    // 需要savelayer一下，房子橡皮无法绘制
    canvas.saveLayer(null, ui.Paint());
    for (var item in paintables) {
      item.paint(canvas, size);
    }
    canvas.restore();
  }

  @override
  int get hashCode => _cacheHash;

  @override
  bool operator ==(Object other) {
    return other is _StrokeCanvasPaintableList && hashCode == other.hashCode;
  }

  @override
  void add(M paintable) {
    _paintables.add(paintable);
    _cacheHash = Object.hash(_cacheHash, paintable);
  }

  @override
  void insert(int index, M paintable) {
    _paintables.insert(index, paintable);
    _cacheHash = Object.hash(_cacheHash, paintable, index);
  }

  @override
  bool any(bool Function(M element) test) {
    return _paintables.any(test);
  }

  @override
  bool contains(Object? element) {
    return _paintables.contains(element);
  }

  @override
  M elementAt(int i) {
    return _paintables.elementAt(i);
  }

  @override
  bool every(bool Function(M element) test) {
    return _paintables.every(test);
  }

  @override
  Iterable<T> expand<T>(Iterable<T> Function(M element) toElements) {
    return _paintables.expand(toElements);
  }

  @override
  M get first => _paintables.first;

  @override
  M firstWhere(bool Function(M element) test, {M Function()? orElse}) {
    return _paintables.firstWhere(test, orElse: orElse);
  }

  @override
  T fold<T>(T initialValue, T Function(T previousValue, M element) combine) {
    return _paintables.fold(initialValue, combine);
  }

  @override
  Iterable<M> followedBy(Iterable<M> other) {
    return _paintables.followedBy(other);
  }

  @override
  void forEach(void Function(M element) action) {
    _paintables.forEach(action);
  }

  @override
  bool get isEmpty => _paintables.isEmpty;

  @override
  bool get isNotEmpty => _paintables.isNotEmpty;

  @override
  Iterator<M> get iterator => _paintables.iterator;

  @override
  String join([String separator = ""]) {
    return _paintables.join(separator);
  }

  @override
  M get last => _paintables.last;

  @override
  M lastWhere(bool Function(M element) test, {M Function()? orElse}) {
    return _paintables.lastWhere(test, orElse: orElse);
  }

  @override
  Iterable<T> map<T>(T Function(M element) toElement) {
    return _paintables.map(toElement);
  }

  @override
  M reduce(M Function(M value, M element) combine) {
    return _paintables.reduce(combine);
  }

  @override
  M get single => _paintables.single;

  @override
  M singleWhere(bool Function(M element) test, {M Function()? orElse}) {
    return _paintables.singleWhere(test, orElse: orElse);
  }

  @override
  Iterable<M> skip(int count) {
    return _paintables.skip(count);
  }

  @override
  Iterable<M> skipWhile(bool Function(M element) test) {
    return _paintables.skipWhile(test);
  }

  @override
  Iterable<M> take(int count) {
    return _paintables.take(count);
  }

  @override
  Iterable<M> takeWhile(bool Function(M element) test) {
    return _paintables.takeWhile(test);
  }

  @override
  List<M> toList({bool growable = true}) {
    return _paintables.toList(growable: growable);
  }

  @override
  Set<M> toSet() {
    return _paintables.toSet();
  }

  @override
  Iterable<M> where(bool Function(M element) test) {
    return _paintables.where(test);
  }

  @override
  Iterable<T> whereType<T>() {
    return _paintables.whereType();
  }

  @override
  List<M> operator +(List<M> other) {
    return _paintables + other;
  }

  @override
  M operator [](int index) {
    return _paintables[index];
  }

  @override
  void operator []=(int index, M value) {
    _paintables[index] = value;
  }

  @override
  void addAll(Iterable<M> iterable) {
    _paintables.addAll(iterable);
    _cacheHash = Object.hash(_cacheHash, iterable.hashCode);
  }

  @override
  Map<int, M> asMap() {
    return _paintables.asMap();
  }

  @override
  List<R> cast<R>() {
    return _paintables.cast();
  }

  @override
  void clear() {
    _paintables.clear();
  }

  @override
  void fillRange(int start, int end, [M? fillValue]) {
    _paintables.fillRange(start, end, fillValue);
  }

  @override
  set first(M value) {
    _paintables.first = value;
  }

  @override
  Iterable<M> getRange(int start, int end) {
    return _paintables.getRange(start, end);
  }

  @override
  int indexOf(M element, [int start = 0]) {
    return _paintables.indexOf(element, start);
  }

  @override
  int indexWhere(bool Function(M element) test, [int start = 0]) {
    return _paintables.indexWhere(test, start);
  }

  @override
  void insertAll(int index, Iterable<M> iterable) {
    _paintables.insertAll(index, iterable);
    _cacheHash = Object.hash(_cacheHash, iterable, index);
  }

  @override
  set last(M value) {
    _paintables.last = value;
  }

  @override
  int lastIndexOf(M element, [int? start]) {
    return lastIndexOf(element, start);
  }

  @override
  int lastIndexWhere(bool Function(M element) test, [int? start]) {
    return _paintables.lastIndexWhere(test, start);
  }

  @override
  set length(int newLength) {
    _paintables.length = newLength;
  }

  @override
  bool remove(Object? value) {
    final res = _paintables.remove(value);
    if (res) {
      _cacheHash = Object.hashAll(_paintables);
    }
    return res;
  }

  @override
  M removeAt(int index) {
    final res = _paintables.removeAt(index);
    _cacheHash = Object.hashAll(_paintables);

    return res;
  }

  @override
  M removeLast() {
    final res = _paintables.removeLast();
    _cacheHash = Object.hashAll(_paintables);

    return res;
  }

  @override
  void removeRange(int start, int end) {
    _paintables.removeRange(start, end);
    _cacheHash = Object.hashAll(_paintables);
  }

  @override
  void removeWhere(bool Function(M element) test) {
    _paintables.removeWhere(test);
    _cacheHash = Object.hashAll(_paintables);
  }

  @override
  void replaceRange(int start, int end, Iterable<M> replacements) {
    _paintables.replaceRange(start, end, replacements);
    _cacheHash = Object.hashAll(_paintables);
  }

  @override
  void retainWhere(bool Function(M element) test) {
    _paintables.retainWhere(test);
    _cacheHash = Object.hashAll(_paintables);
  }

  @override
  Iterable<M> get reversed => _paintables.reversed;

  @override
  void setAll(int index, Iterable<M> iterable) {
    _paintables.setAll(index, iterable);
    _cacheHash = Object.hashAll(_paintables);
  }

  @override
  void setRange(int start, int end, Iterable<M> iterable, [int skipCount = 0]) {
    _paintables.setRange(start, end, iterable);
    _cacheHash = Object.hashAll(_paintables);
  }

  @override
  void shuffle([Random? random]) {
    _paintables.shuffle(random);
    _cacheHash = Object.hashAll(_paintables);
  }

  @override
  void sort([int Function(M a, M b)? compare]) {
    _paintables.sort(compare);
    _cacheHash = Object.hashAll(_paintables);
  }

  @override
  List<M> sublist(int start, [int? end]) {
    return sublist(start, end);
  }
}
