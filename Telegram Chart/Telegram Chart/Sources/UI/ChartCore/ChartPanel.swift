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

        let plot = chart.plots[plotIndex]
        plot.color.setStroke()
        ctx.setLineWidth(1)

        let args = chart.timestamps
        let values = plot.values

        ctx.move(to: pointAtTimestamp(args[0], value: values[0], rect: rect))

        for i in 1..<args.count {
            let time = args[i]
            let value = values[i]
            ctx.addLine(to: pointAtTimestamp(time, value: value, rect: rect))
        }

        ctx.strokePath()
    }

    private func pointAtTimestamp(_ timestamp: Int64,
                                  value: Int64,
                                  rect: CGRect) -> CGPoint {

        let x = chart.timeRange.x(in: rect, timestamp: timestamp)
        let y = chart.valueRange.y(in: rect, value: value)
        return CGPoint(x: x, y: y)
    }
}
