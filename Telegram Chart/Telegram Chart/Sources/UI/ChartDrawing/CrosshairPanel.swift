//
// Created by Vadim on 2019-03-16.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public protocol CrosshairPanel {
    func drawInContext(_ ctx: CGContext, rect: CGRect)
    // FIXME: govnocod
    func getMoveRectToLeft(bounds: CGRect, frame: CGRect, x: CGFloat) -> Bool?
}

public struct CrosshairPanelConfig {
    public let pointFillColor: UIColor
    public let lineColor: UIColor
}

public struct LineCrosshairPanel: CrosshairPanel {

    public let chart: DrawingChart
    public let timestampIndex: Int
    public let config: CrosshairPanelConfig

    public func drawInContext(_ ctx: CGContext, rect: CGRect) {
        let thinLineWidth = ScreenHelper.lightLineWidth

        let xCalc = DrawingChart.XCalculator(timeRange: chart.timeRange)
        let timestamp = chart.timestamps[timestampIndex]
        let x = xCalc.x(in: rect, timestamp: timestamp)
        var line = rect
        line.origin.x = x
        line.size.width = thinLineWidth
        config.lineColor.setFill()
        ctx.fill(line)

        for plot in chart.visiblePlots {
            let calc = DrawingChart.PointCalculator(timeRange: chart.timeRange, valueRange: chart.valueRange(plot: plot))
            let point = calc.pointAtTimestamp(timestamp, value: plot.values[timestampIndex], rect: rect)
            plot.color.setFill()
            let outer = CGRect(x: point.x - 4, y: point.y - 4, width: 9, height: 9)
            ctx.fillEllipse(in: outer)
            config.pointFillColor.setFill()
            let inner = CGRect(x: point.x - 2, y: point.y - 2, width: 5, height: 5)
            ctx.fillEllipse(in: inner)
        }
    }

    public func getMoveRectToLeft(bounds: CGRect, frame: CGRect, x: CGFloat) -> Bool? {
        for plot in chart.visiblePlots {
            let yCalc = DrawingChart.YCalculator(valueRange: chart.valueRange(plot: plot))
            let y = yCalc.y(in: bounds, value: plot.values[timestampIndex])
            if frame.contains(CGPoint(x: x, y: y)) {
                var frame1 = frame
                frame1.origin.x = x - frame.width - 10
                if bounds.contains(frame1) {
                    return true
                }
                return false
            }
        }
        return nil
    }
}

public struct StackedBarCrosshairPanel: CrosshairPanel {

    public let chart: DrawingChart
    public let timestampIndex: Int
    public let config: CrosshairPanelConfig

    public func drawInContext(_ ctx: CGContext, rect: CGRect) {
        let xCalc = DrawingChart.XCalculator(timeRange: chart.timeRange)
        let timestamp = chart.timestamps[timestampIndex]

        for (plotIdx, plot) in chart.visiblePlots.enumerated() {
            let yCalc = DrawingChart.StackedYCalculator(
                    valueRange: chart.valueRange(plot: plot),
                    plots: chart.visiblePlots,
                    plotIdx: plotIdx)

            let point = CGPoint(
                    x: xCalc.x(in: rect, timestamp: timestamp),
                    y: yCalc.y(in: rect, at: timestampIndex))

            plot.color.setFill()
            let outer = CGRect(x: point.x - 4, y: point.y - 4, width: 9, height: 9)
            ctx.fillEllipse(in: outer)
            config.pointFillColor.setFill()
            let inner = CGRect(x: point.x - 2, y: point.y - 2, width: 5, height: 5)
            ctx.fillEllipse(in: inner)
        }
    }

    public func getMoveRectToLeft(bounds: CGRect, frame: CGRect, x: CGFloat) -> Bool? {
        var frame1 = frame
        frame1.origin.x = x - frame.width - 10
        if bounds.contains(frame1) {
            return true
        }
        return false
    }
}

public struct PercentageAreaCrosshairPanel: CrosshairPanel {

    public let chart: DrawingChart
    public let timestampIndex: Int
    public let config: CrosshairPanelConfig

    public func drawInContext(_ ctx: CGContext, rect: CGRect) {
        let thinLineWidth = ScreenHelper.lightLineWidth

        let xCalc = DrawingChart.XCalculator(timeRange: chart.timeRange)
        let timestamp = chart.timestamps[timestampIndex]
        let x = xCalc.x(in: rect, timestamp: timestamp)
        var line = rect
        line.origin.x = x
        line.size.width = thinLineWidth
        config.lineColor.setFill()
        ctx.fill(line)
    }

    public func getMoveRectToLeft(bounds: CGRect, frame: CGRect, x: CGFloat) -> Bool? {
        var frame1 = frame
        frame1.origin.x = x - frame.width - 10
        if bounds.contains(frame1) {
            return true
        }
        return false
    }
}
