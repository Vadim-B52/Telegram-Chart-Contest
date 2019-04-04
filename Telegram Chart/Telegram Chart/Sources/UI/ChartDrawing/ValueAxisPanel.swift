//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ValueAxisPanel {
    public let chart: DrawingChart
    public let config: Config

    private lazy var calculator: DrawingChart.YCalculator = DrawingChart.YCalculator(valueRange: chart.valueRange)
    private lazy var font: UIFont = Fonts.current.light11()
    private lazy var  thinLineWidth = ScreenHelper.lightLineWidth
    private lazy var  options = NSStringDrawingOptions.usesLineFragmentOrigin
    private lazy var  attributes: [NSAttributedString.Key: Any]? = [NSAttributedString.Key.foregroundColor: config.textColor]

    public init(chart: DrawingChart, config: Config) {
        self.chart = chart
        self.config = config
    }

    public func drawInContext(_ ctx: CGContext, rect: CGRect) {
        let yAxisValues = chart.axisValues
        config.zeroAxisColor.setFill()
        _ = drawLineInContext(ctx, atValue: yAxisValues.zero, rect: rect)
        config.axisColor.setFill()
        var i: Int64 = 1
        while drawLineInContext(ctx, atValue: yAxisValues.zero + i * yAxisValues.step, rect: rect) {
            i += 1
        }
    }

    private func drawLineInContext(_ ctx: CGContext, atValue val: Int64, rect: CGRect) -> Bool {
        let y = calculator.y(in: rect, value: val).screenScaledFloor
        let textHeight = font.lineHeight.screenScaledFloor
        guard y - textHeight >= rect.minY else {
            return false
        }
        let line = CGRect(x: rect.minX, y: y, width: rect.width, height: thinLineWidth)
        let textRect = CGRect(x: rect.minX, y: y - textHeight, width: rect.width, height: textHeight)
        ctx.fill(line)
        "\(val)".draw(with: textRect, options: options, attributes: attributes, context: nil)
        return true
    }

    public struct Config {
        let axisColor: UIColor
        let zeroAxisColor: UIColor
        let textColor: UIColor
    }
}
