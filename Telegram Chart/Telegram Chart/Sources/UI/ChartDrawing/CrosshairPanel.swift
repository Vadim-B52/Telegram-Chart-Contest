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
        let thinLineWidth = ScreenHelper.thinLineWidth

        let xCalc = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)
        let timestamp = chart.timestamps[timestampIndex]
        let x = floor(xCalc.x(in: rect, timestamp: timestamp))
        var line = rect
        line.origin.x = x
        line.size.width = thinLineWidth
        config.lineColor.setFill()
        ctx.fill(line)

        let calc = DrawingChart.Calculator(timeRange: chart.selectedTimeRange, valueRange: chart.valueRange)
        for plot in chart.plots {
            let point = calc.pointAtTimestamp(timestamp, value: plot.values[timestampIndex], rect: rect)
            plot.color.setFill()
            let outer = CGRect(x: point.x - 4.5, y: point.y - 4.5, width: 9, height: 9)
            ctx.fillEllipse(in: outer)
            config.pointFillColor.setFill()
            let inner = CGRect(x: point.x - 2.5, y: point.y - 2.5, width: 5, height: 5)
            ctx.fillEllipse(in: inner)
        }
    }

    public struct Config {
        public let pointFillColor: UIColor
        public let lineColor: UIColor
    }
}
