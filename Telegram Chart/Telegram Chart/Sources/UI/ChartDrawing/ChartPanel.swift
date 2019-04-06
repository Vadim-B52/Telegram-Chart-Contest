//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartPanel {

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

    public func drawInContext(_ layer: CAShapeLayer, rect: CGRect) {
        layer.lineJoin = .round
        layer.lineWidth = lineWidth

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

        path.stroke()
        layer.strokeColor = plot.color.cgColor
        layer.path = path.cgPath
        layer.fillColor = UIColor.clear.cgColor
    }
}
