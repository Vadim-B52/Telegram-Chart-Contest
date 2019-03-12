//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class MiniChartView: UIView {

    public var chart: DrawingChart? = nil {
        didSet {
            setNeedsDisplay()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        isOpaque = true
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentMode = .redraw
        isOpaque = true
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard var chart = chart,
              let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        ctx.saveGState()
        ctx.scaleBy(x: 1, y: -1)
        ctx.translateBy(x: 0, y: -rect.size.height)
        chart.plots.forEach { plot in
            drawInContext(ctx, chart: chart, plot: plot)
        }
        ctx.restoreGState()
    }

    private func drawInContext(_ ctx: CGContext, chart: DrawingChart, plot: Chart.Plot) {
        plot.color.setStroke()
        ctx.setLineWidth(1)

        let args = chart.timestamps
        let values = plot.values

        ctx.move(to: pointAtTimestamp(args[0], value: values[0], chart: chart))

        for i in 1..<args.count {
            let time = args[i]
            let value = values[i]
            ctx.addLine(to: pointAtTimestamp(time, value: value, chart: chart))
        }

        ctx.strokePath()
    }

    private func pointAtTimestamp(_ timestamp: Int64,
                                  value: Int64,
                                  chart: DrawingChart) -> CGPoint {

        let timeRange = chart.timeRange
        let valueRange = chart.valueRange
        let t = CGFloat(timestamp - timeRange.min) / CGFloat(timeRange.size)
        let x = bounds.minX + bounds.size.width * t
        let v = CGFloat(value - valueRange.min) / CGFloat(valueRange.size)
        let y = bounds.minY + bounds.size.height * v
        return CGPoint(x: x, y: y)
    }
}
