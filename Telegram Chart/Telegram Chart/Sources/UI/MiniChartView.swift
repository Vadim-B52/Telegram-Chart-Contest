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
        for (idx, _) in chart.plots.enumerated() {
            ctx.saveGState()
            let panel = ChartPanel(chart: chart, plotIndex: idx)
            panel.drawInContext(ctx, rect: bounds)
            ctx.restoreGState()
        }
    }
}
