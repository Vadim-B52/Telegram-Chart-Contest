//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public protocol ChartPanel {
    func drawInContext(_ layer: CAShapeLayer, rect: CGRect, apply: ((CAShapeLayer, CGPath) -> Void)?)
}

public class LineChartPanel: ChartPanel {

    public let timestamps: [Int64]
    public let indexRange: TimeIndexRange
    public let timeRange: TimeRange
    public let valueRange: ValueRange
    public let plot: Chart.Plot
    public let lineWidth: CGFloat

    public init(timestamps: [Int64],
                indexRange: TimeIndexRange,
                timeRange: TimeRange,
                valueRange: ValueRange,
                plot: Chart.Plot,
                lineWidth: CGFloat) {

        self.timestamps = timestamps
        self.indexRange = indexRange
        self.timeRange = timeRange
        self.valueRange = valueRange
        self.plot = plot
        self.lineWidth = lineWidth
    }

    public func drawInContext(_ layer: CAShapeLayer, rect: CGRect, apply: ((CAShapeLayer, CGPath) -> Void)? = nil) {
        let values = plot.values
        let calc = DrawingChart.Calculator(timeRange: timeRange, valueRange: valueRange)
        let startIdx = indexRange.startIdx
        let startPoint = calc.pointAtTimestamp(timestamps[startIdx], value: values[startIdx], rect: rect).screenScaledFloor
        let path = UIBezierPath()
        path.move(to: startPoint)

        for i in (startIdx + 1)...indexRange.endIdx {
            let time = timestamps[i]
            let value = values[i]
            let point = calc.pointAtTimestamp(time, value: value, rect: rect).screenScaledFloor
            path.addLine(to: point)
        }

        layer.lineJoin = .round
        layer.lineWidth = lineWidth
        layer.strokeColor = plot.color.cgColor
        layer.fillColor = UIColor.clear.cgColor

        if let apply = apply {
            apply(layer, path.cgPath)
        } else {
            layer.path = path.cgPath
        }
    }
}
