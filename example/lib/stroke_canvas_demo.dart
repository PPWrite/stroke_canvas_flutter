import 'dart:math';

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
  final _painter = StrokeCanvasPainter.supportEraser();
  // this hd is not support eraser.
  // final _painter = StrokeCanvasPainter.hd();
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
    final mq = MediaQuery.of(context);
    final size = Size(
      mq.size.width - mq.padding.left - mq.padding.right,
      mq.size.height - mq.padding.top - mq.padding.bottom,
    );
    if (_canvasSize == null) {
      _painter.setEraserWidth(100);
      _painter.setStrokeWidth(1.5);

      _canvasSize = size;
      // 设置画布的大小，必须要正确设置
      _painter.size = size;
      // 设置屏幕像素密度，不设置会有锯齿
      _painter.pixelRatio = mq.devicePixelRatio;
    }

    return GestureDetector(
      onPanStart: (details) {
        _painter.drawPoint(details.localPosition.dx, details.localPosition.dy);
      },
      onPanUpdate: (details) {
        _painter.drawPoint(details.localPosition.dx, details.localPosition.dy);
      },
      onPanEnd: (details) {
        _painter.newLine();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          StrokeCanvas(
            painter: _painter,
            size: size,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  initFloatingActionButton,
                  FloatingActionButton(
                    elevation: 1,
                    focusElevation: 1,
                    backgroundColor: Colors.red,
                    onPressed: () {
                      setState(() {
                        isEraser = !isEraser;
                      });
                      _painter.setIsEraser(isEraser);
                    },
                    child: Icon(
                      CupertinoIcons.paintbrush_fill,
                      color: isEraser ? Colors.green : Colors.white,
                      size: 30.0,
                    ),
                  ),
                  FloatingActionButton(
                    elevation: 1,
                    focusElevation: 1,
                    backgroundColor: Colors.blue,
                    onPressed: () {
                      _autoDraw = !_autoDraw;
                      _painter.newLine();
                      autoDraw();
                    },
                    child: const Icon(
                      CupertinoIcons.rocket,
                      color: Colors.white,
                      size: 30.0,
                    ),
                  ),
                  FloatingActionButton(
                    elevation: 1,
                    focusElevation: 1,
                    backgroundColor: Colors.green,
                    onPressed: () async {
                      const img = AssetImage('lib/images/share_more.png');
                      final imgInfo = await resolveImageProviderInfo(img);
                      final x = Random().nextInt(300).toDouble();
                      final y = Random().nextInt(300).toDouble();
                      var hw = Random().nextInt(50).toDouble();
                      hw = hw < 10 ? 10 : hw;
                      _painter.drawImage(
                        imgInfo.image,
                        rect: Rect.fromLTWH(x, y, hw, hw),
                      );
                    },
                    child: const Icon(
                      CupertinoIcons.film,
                      color: Colors.white,
                      size: 30.0,
                    ),
                  ),
                ],
              ),
            ),
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

  bool _autoDraw = false;
  double _autoDrawPoint = 0;
  int _autoDrawCount = 0;
  Future<void> autoDraw() async {
    if (!_autoDraw) return;

    final size = _canvasSize;
    await Future.delayed(const Duration(milliseconds: 1), () {
      if (size == null) return;
      final x = _autoDrawPoint % size.width;
      final y = _autoDrawPoint / size.width;
      _painter.drawPoint(x, y + 100);

      _autoDrawPoint += 0.5;
      _autoDrawCount++;

      // print("_autoDrawCount: $_autoDrawCount");
      if (_autoDrawPoint > size.width) {
        _painter.newLine();
      } else if (_autoDrawPoint > size.width * size.height) {
        _painter.newLine();
        _autoDrawPoint = 0;
      }
    });

    if (_autoDraw) {
      autoDraw();
    }
  }

  Widget get initFloatingActionButton {
    return FloatingActionButton(
      backgroundColor: Colors.grey,
      elevation: 1,
      focusElevation: 1,
      onPressed: () {
        _autoDrawCount = 0;
        _autoDrawPoint = 0;
        _autoDraw = false;
        _painter.clean();
      },
      child: const Icon(Icons.clear),
    );
  }
}
