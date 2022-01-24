# stroke_canvas_flutter

Flutter 实现的笔迹画布插件。

## 插件使用

### 简单使用

1. 引入插件：

   ```dart
   import 'package:stroke_canvas_flutter/stroke_canvas.dart';
   ```
2. 创建 `StrokeCanvasPainter`

   ```
   final _painter = StrokeCanvasPainter();

   final mq = MediaQuery.of(context);
   final size = Size(
     mq.size.width - mq.padding.left - mq.padding.right,
     mq.size.height - mq.padding.top - mq.padding.bottom,
   );

   // 设置画布的大小，必须要正确设置
   _painter.size = size;
   // 设置屏幕像素密度，不设置或者设置的值太小，绘制的笔迹会有严重的锯齿
   _painter.pixelRatio = mq.devicePixelRatio;
   // 设置笔迹默认颜色
   _painter.setLineColor(Colors.red);
   // 设置笔迹的默认宽度
   _painter.setStrokeWidth(2);
   ```
3. 创建 `StrokeCanvas`

   ```dart
   StrokeCanvas(painter: _painter)
   ```
4. 绘制笔迹

   ```dart
   // 新开一条笔迹
   _painter.newLine();
   // 绘制笔迹点
   _painter.drawPoint(10, 10);
   _painter.drawPoint(50, 50, width: 5);
   ```
5. 清空画布 `_painter.clean()`
6. 其他绘制方法

   ```dart
   // 绘制图片到画布
   _painter.drawImage(img);

   // 添加点，但不立刻绘制到界面上
   _painter.addPoint(10, 10);
   // 添加图片到画布，但不立刻绘制到界面上
   _painter.addImage(img);
   // 触发绘制，将addPoint和addImage添加的笔迹绘制并显示回来。
   _painter.shouldPaint()
   ```
7. 获取画布绘制的图片

   ```dart
   // 获取画布绘制的图片，返回类型Image
   _painter.getDrawnImage()
   // 获取画布绘制的图片，返回类型MemoryImage
   _painter.getDrawnMemoryImage()
   ```

### 多画笔支持

为了实现一个画布支持多个设备同时绘制，画布支持多画笔功能。

只需要在调用 `drawPoint`、 `addPoint`、`setLineColor` 和 `setStrokeWidth` 时传入 `penId` 参数。

## 其他
如果项目使用了 `flutter_lints` 代码静态分析插件，最好在`analysis_options.yaml`文件里将plugins文件夹忽略:

``` yaml
analyzer:
  exclude:
    - plugins/**
```
