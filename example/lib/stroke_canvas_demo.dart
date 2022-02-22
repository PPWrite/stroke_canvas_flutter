import 'package:flutter/cupertino.dart';
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
  bool isEraser = false;
  @override
  void initState() {
    super.initState();
  }

  Size? _canvasSize;
  late double dx = 50;
  late double dy = 175;
  @override
  Widget build(BuildContext context) {
    _painter.setEraserWidth(100);
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
      onPanStart: (details) {
        if (isEraser) {
          dx = details.localPosition.dx;
          dy = details.localPosition.dy;
          setState(() {});
        }
        final point = details.localPosition;
        _painter.drawPoint(point.dx, point.dy);
      },
      onPanUpdate: (details) {
        if (isEraser) {
          dx = details.localPosition.dx;
          dy = details.localPosition.dy;
          setState(() {});
        }
        final point = details.localPosition;
        _painter.drawPoint(point.dx, point.dy);
      },
      onPanEnd: (details) {
        _painter.newLine();
      },
      onPanDown: (detail) {
        Rect rect =
            Rect.fromCenter(center: Offset(dx, dy), width: 50, height: 50);
        isEraser = rect.contains(detail.localPosition);
        _painter.setIsEraser(isEraser);
      },
      child: Stack(
        children: [
          SizedBox(
            width: _canvasSize!.width,
            height: _canvasSize!.height,
            child: StrokeCanvas(
              painter: _painter,
              size: _canvasSize,
            ),
          ),
          Positioned(
            child: initFloatingActionButton,
            bottom: 100,
            right: 100,
          ),
          Positioned(
            child: FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () {},
              child: const Icon(
                CupertinoIcons.paintbrush_fill,
                color: Colors.white,
                size: 50.0,
              ),
            ),
            left: dx - 25,
            top: dy - 25,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _painter.dispose();
  }

  Widget get initFloatingActionButton {
    return FloatingActionButton(
      backgroundColor: Colors.grey,
      elevation: 1,
      focusElevation: 1,
      onPressed: () {
        _painter.clean();
      },
      child: const Icon(Icons.clear),
    );
  }
}
