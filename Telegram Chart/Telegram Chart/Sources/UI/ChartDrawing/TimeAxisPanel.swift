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

    public func drawInContext(_ ctx: CGContext, rect: CGRect) {
        guard let firstTS = chart.timestamps.first else {
            return
        }
//        let color = UIColor.gray // TODO: color

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM\u{00a0}dd"
        let options = NSStringDrawingOptions.usesLineFragmentOrigin
        let attributes: [NSAttributedString.Key: Any]? = nil
        let calculator = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)
        var rest = rect
        
        let sizingDate = Date(timeIntervalSince1970: Double(firstTS) / 1000.0)
        let sizingStr = formatter.string(from: sizingDate)
        let dateSize = sizingStr.boundingRect(with: rest.size, options: options, attributes: attributes, context: nil)

        var slice: CGRect
        while rest.size.width >= dateSize.width {
            (slice, rest) = rest.divided(atDistance: ceil(dateSize.width), from: .minXEdge)
            let timestamp = calculator.timestampAt(x: slice.midX, rect: rect)
            let date = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
            let str = formatter.string(from: date)
            slice.origin.y = rest.origin.y + floor((rest.size.height - dateSize.height) / 2)
            slice.size.height = ceil(dateSize.size.height)
            str.draw(with: slice, options: options, attributes: attributes, context: nil)
            (_, rest) = rest.divided(atDistance: slice.maxX - rest.minX + 10, from: .minXEdge)
        }
    }
}
