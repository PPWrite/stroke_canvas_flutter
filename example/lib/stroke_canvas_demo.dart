import 'package:flutter/material.dart';
import 'package:stroke_canvas_flutter/stroke_canvas.dart';

/// 画布演示demo
class StrokeCanvasDemo extends StatefulWidget {
  const StrokeCanvasDemo({Key? key}) : super(key: key);

  @override
  _StrokeCanvasDemoState createState() => _StrokeCanvasDemoState();
}

class _StrokeCanvasDemoState extends State<StrokeCanvasDemo> {
  final _painter = StrokeCanvasPainter();

  @override
  void initState() {
    super.initState();
  }

  Size? _canvasSize;

  @override
  Widget build(BuildContext context) {
    if (_canvasSize == null) {
      final mq = MediaQuery.of(context);
      final size = Size(
        mq.size.width - mq.padding.left - mq.padding.right,
        mq.size.height - mq.padding.top - mq.padding.bottom,
      );

      _canvasSize = size;
      // 设置画布的大小，必须要正确设置
      _painter.size = size;
      // 设置屏幕像素密度，不设置会有锯齿
      _painter.pixelRatio = mq.devicePixelRatio;
    }

    return GestureDetector(
      child: SizedBox(
        width: _canvasSize!.width,
        height: _canvasSize!.height,
        child: StrokeCanvas(
          painter: _painter,
          size: _canvasSize,
        ),
      ),
      onPanStart: (details) {
        final point = details.localPosition;
        _painter.drawPoint(point.dx, point.dy);
      },
      onPanUpdate: (details) {
        final point = details.localPosition;
        _painter.drawPoint(point.dx, point.dy);
      },
      onPanEnd: (details) {
        _painter.newLine();
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _painter.dispose();
  }
}
