//
// Created by Vadim on 2019-03-16.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class CrosshairPanel {

    public let chart: DrawingChart
    public let timestampIndex: Int

    public init(chart: DrawingChart, timestampIndex: Int) {
        self.chart = chart
        self.timestampIndex = timestampIndex
    }

    public func drawInContext(_ ctx: CGContext, rect: CGRect) {
        let thinLineWidth = 1 / UIScreen.main.scale
        let color = UIColor.gray // TODO: color
        color.setFill()

        let xCalc = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)
        let timestamp = chart.timestamps[timestampIndex]
        let x = xCalc.x(in: rect, timestamp: timestamp)
        var line = rect
        line.origin.x = x
        line.size.width = thinLineWidth
        ctx.fill(line)

        let calc = DrawingChart.Calculator(timeRange: chart.selectedTimeRange, valueRange: chart.valueRange)
        for plot in chart.plots {
            let point = calc.pointAtTimestamp(timestamp, value: plot.values[timestampIndex], rect: rect)
            plot.color.setFill()
            let outer = CGRect(x: point.x - 4.5, y: point.y - 4.5, width: 9, height: 9)
            ctx.fillEllipse(in: outer)
            // TODO: color
            UIColor.white.setFill()
            let inner = CGRect(x: point.x - 2.5, y: point.y - 2.5, width: 5, height: 5)
            ctx.fillEllipse(in: inner)
        }
    }
}