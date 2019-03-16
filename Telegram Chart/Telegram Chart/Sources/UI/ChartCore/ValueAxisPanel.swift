//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

// TODO: selectedValueRange!
public class ValueAxisPanel {

    public let chart: DrawingChart

    public init(chart: DrawingChart) {
        self.chart = chart
    }

    public func drawInContext(_ ctx: CGContext, rect: CGRect) {
        let font = UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.light)
        let numberOfLines = 6
        let step = ceil((rect.maxY - rect.minY - 0) / CGFloat(numberOfLines))
        let calculator = DrawingChart.YCalculator(valueRange: chart.valueRange)

        var rest = rect
        let thinLineWidth = 1 / UIScreen.main.scale
        let options = NSStringDrawingOptions.usesLineFragmentOrigin
        let attributes: [NSAttributedString.Key: Any]? = nil

        let color = UIColor.gray // TODO: color
        color.setFill()

        for _ in 0..<numberOfLines {
            var slice, line: CGRect
            (slice, rest) = rest.divided(atDistance: step, from: .maxYEdge)
            (line, _) = slice.divided(atDistance: thinLineWidth, from: .maxYEdge)
            color.setFill()
            ctx.fill(line)

            (slice, _) = slice.divided(atDistance: font.lineHeight, from: .maxYEdge)
            let value = calculator.valueAt(y: line.minY, rect: rect)
            let str = "\(value)"
            str.draw(with: slice, options: options, attributes: attributes, context: nil)
        }
    }
}
