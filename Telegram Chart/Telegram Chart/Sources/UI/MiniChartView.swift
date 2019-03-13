//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class MiniChartView: UIView {

    private let timeSelector = TimeSelectorView()

    public var chart: DrawingChart? = nil {
        didSet {
            setNeedsDisplay()

            if let chart = chart {
                timeSelector.timeRange = chart.timeRange
                timeSelector.selectedTimeRange = TimeRange(min: chart.timestamps[10], max: chart.timestamps[30])
            }
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        isOpaque = true
        addSubview(timeSelector)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentMode = .redraw
        isOpaque = true
        addSubview(timeSelector)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        timeSelector.frame = bounds
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let chart = chart,
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
        
        let x = chart.timeRange.x(in: bounds, timestamp: timestamp)
        let y = chart.valueRange.y(in: bounds, value: value)
        return CGPoint(x: x, y: y)
    }
}
