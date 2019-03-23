//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class TimeAxisPanel {

    public let chart: DrawingChart
    public let description: TimeAxisDescription?
    public let config: Config

    private lazy var formatter = ChartTextFormatter.shared
    private lazy var options = NSStringDrawingOptions.usesLineFragmentOrigin
    private lazy var attributes: [NSAttributedString.Key: Any]? = [NSAttributedString.Key.foregroundColor: config.textColor]
    private lazy var calculator = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)

    public init(chart: DrawingChart, description: TimeAxisDescription?, config: Config) {
        self.chart = chart
        self.description = description
        self.config = config
    }

    public func drawInContext(_ ctx: CGContext, rect: CGRect) -> TimeAxisDescription {
        let dateSize = formatter.sizingString.boundingRect(
                with: rect.size,
                options: options,
                attributes: attributes,
                context: nil).size

        var currDescr: TimeAxisDescription
        if let prevDescr = description {
            currDescr = prevDescr

            let c1 = calculator.x(in: rect, timestamp: chart.timestamps[prevDescr.zeroIdx])
            let c2 = calculator.x(in: rect, timestamp: chart.timestamps[prevDescr.zeroIdx + prevDescr.step])
            if c2 - c1 > 3 * dateSize.width {
                currDescr.step = prevDescr.step / 2
            } else if c2 - c1 < 1.5 * dateSize.width {
                currDescr.step = prevDescr.step * 2
            }

            var i = currDescr.zeroIdx
            while i >= chart.indexRange.startIdx {
                i -= currDescr.step
            }
            currDescr.zeroIdx = i + currDescr.step
        } else {
            let zeroIdx = chart.closestIdxTo(timestamp: calculator.timestampAt(x: 10 + dateSize.width / 2, rect: rect))
            let zeroTime = chart.timestamps[zeroIdx]
            var step = 1
            while true {
                let c1 = calculator.x(in: rect, timestamp: zeroTime)
                let c2 = calculator.x(in: rect, timestamp: chart.timestamps[zeroIdx + step])
                if c2 - c1 < 1.5 * dateSize.width {
                    step *= 2
                } else {
                    break
                }
            }
            currDescr = TimeAxisDescription(zeroIdx: zeroIdx, step: step)
        }
        drawInContext(ctx, rect: rect, description: currDescr)
        return currDescr
    }

    private func drawInContext(_ ctx: CGContext, rect: CGRect, description: TimeAxisDescription) {
        var i = description.zeroIdx
        while i <= chart.indexRange.endIdx {
            let timestamp = chart.timestamps[i]
            let str = formatter.axisDateText(timestamp: timestamp)
            let size = str.boundingRect(
                    with: rect.size,
                    options: options,
                    attributes: attributes,
                    context: nil)

            let frame = CGRect(
                    x: (calculator.x(in: rect, timestamp: timestamp) - size.width / 2).screenScaledFloor,
                    y: (rect.origin.y + (rect.size.height - size.height) / 2).screenScaledFloor,
                    width: ceil(size.width),
                    height: ceil(size.size.height))

            str.draw(with: frame, options: options, attributes: attributes, context: nil)
            i += description.step
        }
    }
    
    public struct Config {
        let textColor: UIColor
    }
}
