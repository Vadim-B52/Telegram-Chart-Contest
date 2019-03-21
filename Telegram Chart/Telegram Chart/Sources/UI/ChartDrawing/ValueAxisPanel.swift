//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

// TODO: selectedValueRange!
public class ValueAxisPanel {

    public let chart: DrawingChart
    public let config: Config

    public init(chart: DrawingChart, config: Config) {
        self.chart = chart
        self.config = config
    }

    public func drawInContext(_ ctx: CGContext, rect: CGRect) {
        let font = UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.light)
        let calculator = DrawingChart.YCalculator(valueRange: chart.valueRange)

        var rest = rect
        let thinLineWidth = 1 / UIScreen.main.scale
        let options = NSStringDrawingOptions.usesLineFragmentOrigin
        let attributes: [NSAttributedString.Key: Any]? = [NSAttributedString.Key.foregroundColor: config.textColor]

        for (idx, val) in chart.yAxisValues.enumerated() {
            if idx == 0 {
                config.zeroAxisColor.setFill()
            } else {
                config.axisColor.setFill()
            }
            let y = calculator.y(in: rect, value: val)
            let line = CGRect(x: rect.minX, y: y, width: rect.width, height: thinLineWidth)
            let textRect = CGRect(x: rect.minX, y: y - font.lineHeight, width: rect.width, height: font.lineHeight)
            ctx.fill(line)
            "\(val)".draw(with: textRect, options: options, attributes: attributes, context: nil)
        }
    }

    public struct Config {
        let axisColor: UIColor
        let zeroAxisColor: UIColor
        let textColor: UIColor
    }
}
