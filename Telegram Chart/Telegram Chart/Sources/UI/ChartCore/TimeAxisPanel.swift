//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class TimeAxisPanel {

    public let chart: DrawingChart

    public init(chart: DrawingChart) {
        self.chart = chart
    }

    public func drawInContext(_ ctx: CGContext, rect rect0: CGRect) {
        let color = UIColor.gray // TODO: color

        var (line, rest) = rect0.divided(atDistance: 1, from: .minYEdge)
        (line, _) = line.divided(atDistance: 1 / UIScreen.main.scale, from: .minYEdge)
        color.setFill()
        ctx.fill(line)

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM\u{00a0}dd"
        let options = NSStringDrawingOptions.usesLineFragmentOrigin
        let attributes: [NSAttributedString.Key: Any]? = nil
        let indexRange = chart.timeIndexRange
        let calculator = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)

        for i in indexRange.startIdx...indexRange.endIdx {
            let timestamp = chart.timestamps[i]
            let date = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
            let str = formatter.string(from: date)

            let boundingRect = str.boundingRect(with: rest.size, options: options, attributes: attributes, context: nil)
            let textWidth = ceil(boundingRect.size.width)
            var textRect = rest
            textRect.origin.x = floor(calculator.x(in: rect0, timestamp: timestamp)) - textWidth / 2
            textRect.size.width = textWidth

            if rest.contains(textRect) {
                str.draw(with: textRect, options: options, attributes: attributes, context: nil)
                (_, rest) = rest.divided(atDistance: textRect.maxX - rest.minX + 10, from: .minXEdge)
            }
        }
    }
}
