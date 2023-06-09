import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

part 'stroke_canvas_model.dart';
part 'stroke_canvas_painter.dart';
part 'stroke_canvas_paintable.dart';
part 'stroke_canvas_algorithm.dart';

/// Flutter笔迹画布
class StrokeCanvas extends StatefulWidget {
  final StrokeCanvasPainter painter;

  /// Widget的size.
  /// 若[size] != null && != [StrokeCanvasPainter.size]，
  /// 则绘制的结果会拉伸缩放。
  final Size? size;

  const StrokeCanvas({
    Key? key,
    required this.painter,
    this.size,
  }) : super(key: key);

  @override
  State<StrokeCanvas> createState() => _StrokeCanvasState();
}

class _StrokeCanvasState extends State<StrokeCanvas> with SingleTickerProviderStateMixin {
  late Ticker _canvsTicker;

  @override
  void initState() {
    super.initState();
    ui.Paint.enableDithering = true;
    // 帧回调
    _canvsTicker = createTicker((elapsed) => _drawIfNeed())..start();
  }

  @override
  Widget build(BuildContext context) {
    widget.painter._widgetSize = widget.size;

    final pixelRatio = widget.painter.pixelRatio;
    final size = widget.size ?? Size.zero;

    if (widget.painter._mode == StrokeCanvasPaintMode.hd) {
      _StrokeCanvasPaintableList paintableList = _StrokeCanvasPaintableList();
      for (var info in widget.painter._pens.values) {
        if (info.path.isNotEmpty) {
          paintableList.add(info.path);
        }
      }

      List<Widget> widgets = List.from(widget.painter._paintableWidgets);

      widgets.add(CustomPaint(
        isComplex: true,
        painter: _StrokeCanvasCustomPainter(
          paintable: paintableList,
          pixelRatio: pixelRatio,
          painter: widget.painter,
        ),
        size: size,
      ));

      return RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: widgets,
        ),
      );
    } else {
      _StrokeCanvasPaintableList paintableList = _StrokeCanvasPaintableList();
      // 以下顺序不可乱：
      // 1. 添加正在合并中的可绘制对象，因为这些事最早绘制的数据
      paintableList.addAll(widget.painter._mergingPaintables);
      // 2. 添加可绘制对象
      paintableList.addAll(widget.painter._paintables);
      // 3. 添加还没关闭的路径，这些事最新的绘制数据
      for (var info in widget.painter._pens.values) {
        if (info.path.isNotEmpty) {
          paintableList.add(info.path);
        }
      }

      return RepaintBoundary(
        child: CustomPaint(
          isComplex: true,
          painter: _StrokeCanvasCustomPainter(
            paintable: paintableList,
            pixelRatio: pixelRatio,
            painter: widget.painter,
          ),
          size: size,
        ),
      );
    }
  }

  @override
  void dispose() {
    _canvsTicker.stop();
    _canvsTicker.dispose();

    super.dispose();
  }

  void _drawIfNeed() {
    if (mounted && widget.painter._isShouldPaint) {
      // 需要绘制，更新状态，触发界面更新
      setState(() {});
      widget.painter._painted();
    }
  }
}

class _StrokeCanvasCustomPainter extends CustomPainter {
  _StrokeCanvasPaintable? paintable;
  double pixelRatio;
  StrokeCanvasPainter painter;

  _StrokeCanvasCustomPainter({
    required this.painter,
    this.paintable,
    this.pixelRatio = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(1 / pixelRatio);

    Size? widgetSize = painter._widgetSize;
    Size painterSize = painter._size;

    bool needSizeScale = widgetSize != null && widgetSize != painterSize;
    if (needSizeScale) {
      canvas.save();
      canvas.scale(
        widgetSize.width / painterSize.width,
        widgetSize.height / painterSize.height,
      );
    }

    paintable?.paint(canvas, size);
    if (needSizeScale) {
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StrokeCanvasCustomPainter oldDelegate) {
    return paintable != oldDelegate.paintable;
  }
}
