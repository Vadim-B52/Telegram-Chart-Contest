//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartPanel {

    public let chart: DrawingChart
    public let plotIndex: Int

    public init(chart: DrawingChart, plotIndex: Int) {
        self.chart = chart
        self.plotIndex = plotIndex
    }

    public func drawInContext(_ ctx: CGContext, rect: CGRect) {
        ctx.scaleBy(x: 1, y: -1)
        ctx.translateBy(x: 0, y: -rect.size.height)

        // TODO: fix bug with wrong ranges! etend rect for real 
        let drawingRect = rect
        let plot = chart.plots[plotIndex]
        plot.color.setStroke()
        ctx.setLineWidth(1)

        let time = chart.timeIndexRange
        let timestamps = chart.timestamps
        let values = plot.values

        let calc = Calculator(timeRange: chart.selectedTimeRange, valueRange: chart.valueRange)
        let startIdx = time.startIdx
        let startPoint = calc.pointAtTimestamp(timestamps[startIdx], value: values[startIdx], rect: drawingRect)
        ctx.move(to: startPoint)

        for i in (startIdx + 1)..<(startIdx + time.length) {
            let time = timestamps[i]
            let value = values[i]
            ctx.addLine(to: calc.pointAtTimestamp(time, value: value, rect: drawingRect))
        }

        ctx.strokePath()
    }

    private struct Calculator {
        let timeRange: TimeRange
        let valueRange: ValueRange

        func pointAtTimestamp(_ timestamp: Int64, value: Int64, rect: CGRect) -> CGPoint {
            let x = timeRange.x(in: rect, timestamp: timestamp)
            let y = valueRange.y(in: rect, value: value)
            return CGPoint(x: x, y: y)
        }
    }
}
