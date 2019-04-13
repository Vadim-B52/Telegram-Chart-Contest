//
// Created by Vadim on 2019-03-16.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public struct CrosshairPanel {

    public let chart: DrawingChart
    public let timestampIndex: Int
    public let config: Config

    public func drawInContext(_ ctx: CGContext, rect: CGRect) {
        let thinLineWidth = ScreenHelper.lightLineWidth

        let xCalc = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)
        let timestamp = chart.timestamps[timestampIndex]
        let x = xCalc.x(in: rect, timestamp: timestamp)
        var line = rect
        line.origin.x = x
        line.size.width = thinLineWidth
        config.lineColor.setFill()
        ctx.fill(line)

        for plot in chart.visiblePlots {
            let calc = DrawingChart.PointCalculator(timeRange: chart.selectedTimeRange, valueRange: chart.valueRange(plot: plot))
            let point = calc.pointAtTimestamp(timestamp, value: plot.values[timestampIndex], rect: rect)
            plot.color.setFill()
            let outer = CGRect(x: point.x - 4, y: point.y - 4, width: 9, height: 9)
            ctx.fillEllipse(in: outer)
            config.pointFillColor.setFill()
            let inner = CGRect(x: point.x - 2, y: point.y - 2, width: 5, height: 5)
            ctx.fillEllipse(in: inner)
        }
    }

    public struct Config {
        public let pointFillColor: UIColor
        public let lineColor: UIColor
    }
}
