//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class TimeAxisPanel {

    public let timeRange: TimeRange
    public let config: Config

    public init(timeRange: TimeRange, config: Config) {
        self.timeRange = timeRange
        self.config = config
    }

    public func drawInContext(_ ctx: CGContext, rect: CGRect) {
        let firstTS = timeRange.min
        let formatter = ChartTextFormatter.shared
        let options = NSStringDrawingOptions.usesLineFragmentOrigin
        let attributes: [NSAttributedString.Key: Any]? = [NSAttributedString.Key.foregroundColor: config.textColor]
        let calculator = DrawingChart.XCalculator(timeRange: timeRange)
        var rest = rect
        let sizingStr = formatter.axisDateText(timestamp: firstTS)
        let dateSize = sizingStr.boundingRect(with: rest.size, options: options, attributes: attributes, context: nil)

        var slice: CGRect
        while rest.width >= dateSize.width {
            (slice, rest) = rest.divided(atDistance: ceil(dateSize.width), from: .minXEdge)
            let timestamp = calculator.timestampAt(x: slice.midX, rect: rect)
            let str = formatter.axisDateText(timestamp: timestamp)
            slice.origin.y = rest.origin.y + floor((rest.size.height - dateSize.height) / 2)
            slice.size.height = ceil(dateSize.size.height)
            str.draw(with: slice, options: options, attributes: attributes, context: nil)
            (_, rest) = rest.divided(atDistance: slice.maxX - rest.minX + 10, from: .minXEdge)
        }
    }
    
    public struct Config {
        let textColor: UIColor
    }
}
