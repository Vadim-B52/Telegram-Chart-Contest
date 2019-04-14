//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public protocol ChartPanel {
    var delegate: ChartPanelDelegate? { get set }

    func drawInLayer(_ layer: CAShapeLayer, rect: CGRect, animated: Bool)
    
    func adjustedColor(_ color: UIColor) -> UIColor
}

extension ChartPanel {
    public func adjustedColor(_ color: UIColor) -> UIColor {
        guard let colorForAdjusting = delegate?.colorToUseForAdjusting(chartPanel: self) else {
            return color
        }
        let r0 = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        let g0 = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        let b0 = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        let ra = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        let ga = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        let ba = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        guard color.getRed(r0, green: g0, blue: b0, alpha: nil),
              colorForAdjusting.getRed(ra, green: ga, blue: ba, alpha: nil) else {

            return color
        }
        return UIColor(
                red: r0.pointee + 0.5 * (ra.pointee - r0.pointee),
                green: g0.pointee + 0.5 * (ga.pointee - g0.pointee),
                blue: b0.pointee + 0.5 * (ba.pointee - b0.pointee),
                alpha: 1)
    }
}

public protocol ChartPanelDelegate: AnyObject {
    func charPanel(
            _ panel: ChartPanel,
            applyPath path: CGPath,
            isVisible: Bool,
            toLayer layer: CAShapeLayer,
            animated: Bool)

    // TODO: separate delegate
    func charPanel(
            _ panel: ChartPanel,
            applyBackgroundColor color: UIColor,
            toSuperlayerAnimated animated: Bool)

    // TODO: separate delegate?
    func colorToUseForAdjusting(chartPanel: ChartPanel) -> UIColor
}

public class LineChartPanel: ChartPanel {

    public let chart: DrawingChart
    public let timestamps: [Int64]
    public let indexRange: TimeIndexRange
    public let timeRange: TimeRange
    public let valueRange: ValueRange
    public let plot: Chart.Plot
    public let lineWidth: CGFloat
    public weak var delegate: ChartPanelDelegate?

    public init(chart: DrawingChart, plot: Chart.Plot, lineWidth: CGFloat) {
        self.chart = chart
        self.timestamps = chart.timestamps
        self.indexRange = chart.timeIndexRange
        self.timeRange = chart.selectedTimeRange
        self.valueRange = chart.valueRange(plot: plot)
        self.plot = plot
        self.lineWidth = lineWidth
    }

    public func drawInLayer(_ layer: CAShapeLayer, rect: CGRect, animated: Bool) {
        let values = plot.values
        let calc = DrawingChart.PointCalculator(timeRange: timeRange, valueRange: valueRange)
        let startIdx = indexRange.startIdx
        let startPoint = calc.pointAtTimestamp(timestamps[startIdx], value: values[startIdx], rect: rect)
        let path = UIBezierPath()
        path.move(to: startPoint)

        for i in (startIdx + 1)...indexRange.endIdx {
            let time = timestamps[i]
            let value = values[i]
            let point = calc.pointAtTimestamp(time, value: value, rect: rect)
            path.addLine(to: point)
        }

        layer.lineJoin = .round
        layer.lineWidth = lineWidth
        layer.strokeColor = plot.color.cgColor
        layer.fillColor = UIColor.clear.cgColor

        delegate?.charPanel(self, applyPath: path.cgPath, isVisible: chart.isPlotVisible(plot), toLayer: layer, animated: animated)
    }
}

// TODO: this is stacked bar drawer?
public class StackedBarChartPanel: ChartPanel {

    public let chart: DrawingChart
    public let timestamps: [Int64]
    public let indexRange: TimeIndexRange
    public let timeRange: TimeRange
    public let valueRange: ValueRange
    public let plot: Chart.Plot
    public let lineWidth: CGFloat
    public weak var delegate: ChartPanelDelegate?

    public init(chart: DrawingChart, plot: Chart.Plot, lineWidth: CGFloat) {
        self.chart = chart
        self.timestamps = chart.timestamps
        self.indexRange = chart.timeIndexRange
        self.timeRange = chart.selectedTimeRange
        self.valueRange = chart.valueRange(plot: plot)
        self.plot = plot
        self.lineWidth = lineWidth
    }

    // FIXME: bug at first and last point
    public func drawInLayer(_ layer: CAShapeLayer, rect: CGRect, animated: Bool) {
        let path = UIBezierPath()
        defer {
            layer.lineWidth = 0
            layer.fillColor = adjustedColor(plot.color).cgColor
            delegate?.charPanel(self, applyPath: path.cgPath, isVisible: chart.isPlotVisible(plot), toLayer: layer, animated: animated)
        }

        guard let plotIdx = chart.visiblePlots.firstIndex(where: { $0 === plot } ) else {
            return
        }

        let xCalc = DrawingChart.XCalculator(timeRange: timeRange)
        let yCalc = DrawingChart.StackedYCalculator(valueRange: valueRange, plots: chart.visiblePlots, plotIdx: plotIdx)
        let startPoint = CGPoint(
                x: xCalc.x(in: rect, timestamp: timestamps[indexRange.startIdx]),
                y: rect.maxY)
        
        path.move(to: startPoint)

        for i in indexRange.startIdx..<indexRange.endIdx {
            let currPoint = CGPoint(
                    x: xCalc.x(in: rect, timestamp: timestamps[i]),
                    y: yCalc.y(in: rect, at: i))

            let nextPoint = CGPoint(
                    x: xCalc.x(in: rect, timestamp: timestamps[i + 1]),
                    y: currPoint.y)

            path.addLine(to: currPoint)
            path.addLine(to: nextPoint)
        }

        let endPoint = CGPoint(
                x: xCalc.x(in: rect, timestamp: timestamps[indexRange.endIdx]),
                y: rect.maxY)

        path.addLine(to: endPoint)
        path.close()
    }
}

public class BarChartPanel: ChartPanel {

    public let chart: DrawingChart
    public let timestamps: [Int64]
    public let indexRange: TimeIndexRange
    public let timeRange: TimeRange
    public let valueRange: ValueRange
    public let plot: Chart.Plot
    public let lineWidth: CGFloat
    public weak var delegate: ChartPanelDelegate?

    public init(chart: DrawingChart, plot: Chart.Plot, lineWidth: CGFloat) {
        self.chart = chart
        self.timestamps = chart.timestamps
        self.indexRange = chart.timeIndexRange
        self.timeRange = chart.selectedTimeRange
        self.valueRange = chart.valueRange(plot: plot)
        self.plot = plot
        self.lineWidth = lineWidth
    }

    // FIXME: bug at first and last point
    public func drawInLayer(_ layer: CAShapeLayer, rect: CGRect, animated: Bool) {
        let path = UIBezierPath()
        defer {
            layer.lineWidth = 0
            layer.fillColor = adjustedColor(plot.color).cgColor
            delegate?.charPanel(self, applyPath: path.cgPath, isVisible: chart.isPlotVisible(plot), toLayer: layer, animated: animated)
        }

        let values = plot.values
        let calc = DrawingChart.PointCalculator(timeRange: timeRange, valueRange: valueRange)
        let startIdx = indexRange.startIdx
        let startPoint = calc.pointAtTimestamp(
                timestamps[startIdx],
                value: values[startIdx], rect: rect)

        path.move(to: CGPoint(x: startPoint.x, y: rect.maxY))

        for i in startIdx..<indexRange.endIdx {
            let currTime = timestamps[i]
            let currValue = values[i]
            let currPoint = calc.pointAtTimestamp(currTime, value: currValue, rect: rect)
            path.addLine(to: currPoint)

            let nextTime = timestamps[i + 1]
            let nextValue = values[i + 1]
            let nextPoint = calc.pointAtTimestamp(nextTime, value: nextValue, rect: rect)
            path.addLine(to: CGPoint(x: nextPoint.x, y: currPoint.y))
        }

        let endTime = timestamps[indexRange.endIdx]
        let endValue = values[indexRange.endIdx]
        let endPoint = calc.pointAtTimestamp(endTime, value: endValue, rect: rect)
        path.addLine(to: CGPoint(x: endPoint.x, y: rect.maxY))
        path.close()
    }
}

public class PercentageStackedAreaChartPanel: ChartPanel {

    public let chart: DrawingChart
    public let timestamps: [Int64]
    public let indexRange: TimeIndexRange
    public let timeRange: TimeRange
    public let valueRange: ValueRange
    public let plot: Chart.Plot
    public let lineWidth: CGFloat
    public weak var delegate: ChartPanelDelegate?

    public init(chart: DrawingChart, plot: Chart.Plot, lineWidth: CGFloat) {
        self.chart = chart
        self.timestamps = chart.timestamps
        self.indexRange = chart.timeIndexRange
        self.timeRange = chart.selectedTimeRange
        self.valueRange = chart.valueRange(plot: plot)
        self.plot = plot
        self.lineWidth = lineWidth
    }

    public func drawInLayer(_ layer: CAShapeLayer, rect: CGRect, animated: Bool) {
        guard let plotIdx = chart.visiblePlots.firstIndex(where: { $0 === plot } ) else {
            let path = UIBezierPath()
            layer.lineWidth = 0
            layer.fillColor = adjustedColor(plot.color).cgColor
            delegate?.charPanel(self, applyPath: path.cgPath, isVisible: false, toLayer: layer, animated: animated)
            return
        }
        guard plotIdx < chart.visiblePlots.count - 1 else {
            delegate?.charPanel(self, applyBackgroundColor: adjustedColor(plot.color), toSuperlayerAnimated: animated)
            return
        }

        let path = UIBezierPath()
        let xCalc = DrawingChart.XCalculator(timeRange: timeRange)
        let yCalc = DrawingChart.PercentageStackedYCalculator(plots: chart.visiblePlots, plotIdx: plotIdx)

        let startIdx = indexRange.startIdx
        let startPoint = CGPoint(
                x: xCalc.x(in: rect, timestamp: timestamps[startIdx]),
                y: rect.maxY)

        path.move(to: startPoint)

        for i in startIdx...indexRange.endIdx {
            let currPoint = CGPoint(
                    x: xCalc.x(in: rect, timestamp: timestamps[i]),
                    y: yCalc.y(in: rect, at: i))

            path.addLine(to: currPoint)
        }

        let endIdx = indexRange.endIdx
        let endPoint = CGPoint(
                x: xCalc.x(in: rect, timestamp: timestamps[endIdx]),
                y: rect.maxY)

        path.addLine(to: endPoint)
        path.close()

        layer.lineWidth = 0
        layer.fillColor = adjustedColor(plot.color).cgColor
        delegate?.charPanel(self, applyPath: path.cgPath, isVisible: true, toLayer: layer, animated: animated)
    }
}
