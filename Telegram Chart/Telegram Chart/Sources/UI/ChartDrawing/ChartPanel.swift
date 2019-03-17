//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartPanel {

    public let chart: DrawingChart
    public let plotIndex: Int
    public let config: Config

    public init(chart: DrawingChart, plotIndex: Int, config: Config) {
        self.chart = chart
        self.plotIndex = plotIndex
        self.config = config
    }

    public func drawInContext(_ ctx: CGContext, rect rect0: CGRect) {
        let rect = drawingRect(with: rect0)
        let plot = chart.plots[plotIndex]
        plot.color.setStroke()
        ctx.setLineWidth(config.lineWidth)

        let time = chart.timeIndexRange
        let timestamps = chart.timestamps
        let values = plot.values

        let calc = DrawingChart.Calculator(timeRange: chart.selectedTimeRange, valueRange: chart.valueRange)
        let startIdx = time.startIdx
        let startPoint = calc.pointAtTimestamp(timestamps[startIdx], value: values[startIdx], rect: rect)
        ctx.move(to: startPoint)

        for i in (startIdx + 1)...time.endIdx {
            let time = timestamps[i]
            let value = values[i]
            ctx.addLine(to: calc.pointAtTimestamp(time, value: value, rect: rect))
        }

        ctx.strokePath()
    }

    private func drawingRect(with rect: CGRect) -> CGRect {
        let time = chart.timeIndexRange
        let timestamps = chart.timestamps
        let timeRange = chart.selectedTimeRange
        if timestamps[time.startIdx] == timeRange.min && timestamps[time.endIdx] == timeRange.max {
            return rect
        }
        let r = rect.size.width / CGFloat(timeRange.size)
        let minD = timeRange.min - timestamps[time.startIdx]
        var drawingRect = rect
        if minD < 0 {
            let d = r * CGFloat(minD)
            drawingRect.origin.x += d
            drawingRect.size.width -= d
        }
        let maxD = timestamps[time.endIdx] - timeRange.max
        if maxD > 0 {
            let d = r * CGFloat(maxD)
            drawingRect.size.width += d
        }
        return drawingRect
    }

    public struct Config {
        public let lineWidth: CGFloat
    }
}
