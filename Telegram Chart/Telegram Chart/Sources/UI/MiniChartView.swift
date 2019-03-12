//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class MiniChartView: UIView {

    public var data: [PlotDrawingData]? = nil {
        didSet {
            setNeedsDisplay()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        isOpaque = true
    }

    public override required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentMode = .redraw
        isOpaque = true
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let data = data, !data.isEmpty,
              let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        // TODO: move to drawing data
        var ranges = [ValueRange]()
        data.forEach { plot in
            guard let r = plot.ranges?.valueRange else {
                return
            }
            ranges.append(r)
        }
        let valueRange = ValueRange(ranges: ranges)!
        ctx.saveGState()
        ctx.scaleBy(x: 1, y: -1)
        ctx.translateBy(x: 0, y: -rect.size.height)
        data.forEach { plot in
            drawInContext(ctx, plot: plot, valueRange: valueRange)
        }
        ctx.restoreGState()
    }

    private func drawInContext(_ ctx: CGContext, plot: PlotDrawingData, valueRange: ValueRange) {
        guard let timeRange = plot.ranges?.timeRange else {
            return
        }

        plot.plot.color.setStroke()
        ctx.setLineWidth(1)

        let args = plot.plot.timestamps
        let values = plot.plot.values

        ctx.move(to: pointAtTimestamp(args[0], value: values[0], valueRange: valueRange, timeRange: timeRange))

        for i in 1..<args.count {
            let time = args[i]
            let value = values[i]
            ctx.addLine(to: pointAtTimestamp(time, value: value, valueRange: valueRange, timeRange: timeRange))
        }

        ctx.strokePath()
    }

    private func lerp<T: Numeric>(min: T, max: T, value: T) -> T {
        return min + (value * (max - min))
    }

    private func pointAtTimestamp(_ timestamp: Int64,
                                  value: Int64,
                                  valueRange: ValueRange,
                                  timeRange: TimeRange) -> CGPoint {

        let t = CGFloat(timestamp - timeRange.min) / CGFloat(timeRange.size)
        let x = bounds.minX + bounds.size.width * t
        let v = CGFloat(value - valueRange.min) / CGFloat(valueRange.size)
        let y = bounds.minY + bounds.size.height * v
        return CGPoint(x: x, y: y)
    }
}
