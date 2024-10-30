import 'dart:math';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  return runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const _DirectionalZooming(),
    );
  }
}

class _DirectionalZooming extends StatefulWidget {
  const _DirectionalZooming();

  @override
  State<_DirectionalZooming> createState() => _DirectionalZoomingState();
}

class _DirectionalZoomingState extends State<_DirectionalZooming> {
  final List<_ChartData> _chartData = [
    _ChartData('Jan', 35, 7),
    _ChartData('Feb', 28, 10),
    _ChartData('Mar', 34, 18),
    _ChartData('Apr', 32, 12),
    _ChartData('May', 40, 16),
    _ChartData('Jun', 35, 9),
    _ChartData('Jul', 28, 11),
    _ChartData('Aug', 34, 7),
    _ChartData('Sep', 32, 3),
    _ChartData('Oct', 40, 11),
    _ChartData('nov', 32, 15),
    _ChartData('dec', 40, 10),
  ];

  CategoryAxis xAxis = const CategoryAxis();
  NumericAxis yAxis = const NumericAxis();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: xAxis,
              primaryYAxis: yAxis,
              zoomPanBehavior: _CustomZoomPanBehavior(xAxis, yAxis),
              series: <CartesianSeries<_ChartData, String>>[
                LineSeries<_ChartData, String>(
                  dataSource: _chartData,
                  xValueMapper: (_ChartData sales, int index) => sales.x,
                  yValueMapper: (_ChartData sales, int index) => sales.y1,
                  markerSettings: const MarkerSettings(isVisible: true),
                ),
                LineSeries<_ChartData, String>(
                  dataSource: _chartData,
                  xValueMapper: (_ChartData sales, int index) => sales.x,
                  yValueMapper: (_ChartData sales, int index) => sales.y2,
                  markerSettings: const MarkerSettings(isVisible: true),
                )
              ],
              legend: const Legend(
                isVisible: true,
                position: LegendPosition.bottom,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y1, this.y2);
  final String x;
  final double y1;
  final double y2;
}

class _CustomZoomPanBehavior extends ZoomPanBehavior {
  _CustomZoomPanBehavior(this.xAxis, this.yAxis);

  CategoryAxis xAxis;
  NumericAxis yAxis;

  @override
  bool get enablePinching => true;

  @override
  bool get enablePanning => true;

  double _previousXZoomFactor = 1;
  double _previousYZoomFactor = 1;
  double _previousXZoomPosition = 0;
  double _previousYZoomPosition = 0;
  double? _previousScale;
  Offset? _previousMovedPosition;

  @override
  void handleScaleStart(ScaleStartDetails details) {
    _previousScale = null;
  }

  @override
  void handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount == 2 && enablePinching) {
      _pinch(details, details.localFocalPoint);
    }
  }

  @override
  void handleScaleEnd(ScaleEndDetails details) {
    _previousScale = null;
  }

  @override
  void handleHorizontalDragStart(DragStartDetails details) {
    _previousScale = null;
    _previousMovedPosition = null;
  }

  @override
  void handleHorizontalDragUpdate(DragUpdateDetails details) {
    _pan(details.localPosition);
  }

  @override
  void handleHorizontalDragEnd(DragEndDetails details) {
    _previousScale = null;
    _previousMovedPosition = null;
  }

  @override
  void handleVerticalDragStart(DragStartDetails details) {
    _previousScale = null;
    _previousMovedPosition = null;
  }

  @override
  void handleVerticalDragUpdate(DragUpdateDetails details) {
    _pan(details.localPosition);
  }

  @override
  void handleVerticalDragEnd(DragEndDetails details) {
    _previousScale = null;
    _previousMovedPosition = null;
  }

  void _pan(Offset position) {
    double currentZoomPosition;
    double calcZoomPosition;
    if (_previousMovedPosition != null) {
      final Offset translatePosition = _previousMovedPosition! - position;
      _previousScale ??= _toScaleValue(_previousXZoomFactor);
      // xAxis.
      calcZoomPosition = _toPanValue(parentBox!.paintBounds, translatePosition,
          _previousXZoomPosition, _previousScale!, false);
      currentZoomPosition =
          _minMax(calcZoomPosition, 0, 1 - _previousXZoomFactor);
      zoomToSingleAxis(xAxis, currentZoomPosition, _previousXZoomFactor);
      _previousXZoomPosition = currentZoomPosition;
      // yAxis.
      calcZoomPosition = _toPanValue(parentBox!.paintBounds, translatePosition,
          _previousYZoomPosition, _previousScale!, true);
      currentZoomPosition =
          _minMax(calcZoomPosition, 0, 1 - _previousYZoomFactor);
      zoomToSingleAxis(yAxis, currentZoomPosition, _previousYZoomFactor);
      _previousYZoomPosition = currentZoomPosition;
    }
    _previousMovedPosition = position;
  }

  void _pinch(ScaleUpdateDetails details, Offset position) {
    final double scale = details.scale;
    final double hScale = details.horizontalScale;
    final double vScale = details.verticalScale;
    bool isHorizontal = false;
    if ((scale - hScale).abs() < (scale - vScale).abs()) {
      isHorizontal = true;
      _previousScale ??= _toScaleValue(_previousXZoomFactor);
    } else {
      _previousScale ??= _toScaleValue(_previousYZoomFactor);
    }
    final double origin =
        _calculateOrigin(parentBox!.paintBounds, position, isHorizontal);
    final double currentScale = _previousScale! * details.scale;
    if (scale != 1 && details.pointerCount == 2) {
      _zoom(origin, currentScale, isHorizontal);
    }
  }

  void _zoom(
      double originPoint, double cumulativeZoomLevel, bool isHorizontal) {
    double currentZoomPosition;
    double currentZoomFactor;
    if (cumulativeZoomLevel == 1) {
      currentZoomFactor = 1;
      currentZoomPosition = 0;
    } else if (isHorizontal) {
      currentZoomFactor = _minMax(1 / cumulativeZoomLevel, 0, 1);
      currentZoomPosition = _previousXZoomPosition +
          ((_previousXZoomFactor - currentZoomFactor) * originPoint);
    } else {
      currentZoomFactor = _minMax(1 / cumulativeZoomLevel, 0, 1);
      currentZoomPosition = _previousYZoomPosition +
          ((_previousYZoomFactor - currentZoomFactor) * originPoint);
    }
    if (isHorizontal) {
      zoomToSingleAxis(xAxis, currentZoomPosition, currentZoomFactor);
      _previousXZoomFactor = currentZoomFactor;
      _previousXZoomPosition = currentZoomPosition;
    } else {
      zoomToSingleAxis(yAxis, currentZoomPosition, currentZoomFactor);
      _previousYZoomFactor = currentZoomFactor;
      _previousYZoomPosition = currentZoomPosition;
    }
  }

  double _toScaleValue(double zoomFactor) {
    return max(1 / _minMax(zoomFactor, 0, 1), 1);
  }

  double _toPanValue(Rect bounds, Offset position, double zoomPosition,
      double scale, bool isVertical) {
    double value = (isVertical
            ? position.dy / bounds.height
            : position.dx / bounds.width) /
        scale;
    return isVertical ? zoomPosition - value : zoomPosition + value;
  }

  double _calculateOrigin(
      Rect bounds, Offset? manipulation, bool isHorizontal) {
    if (manipulation == null) {
      return 0.5;
    }

    double origin;
    const double plotOffset = 0;
    if (isHorizontal) {
      origin = (manipulation.dx - plotOffset) / bounds.width;
    } else {
      origin = 1 - ((manipulation.dy - plotOffset) / bounds.height);
    }

    return origin;
  }

  double _minMax(double value, double min, double max) {
    return value > max ? max : (value < min ? min : value);
  }
}
