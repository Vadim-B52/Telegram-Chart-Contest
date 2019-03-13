//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartView: UIView {

    public var chart: DrawingChart? = nil {
        didSet {
            setNeedsDisplay()
        }
    }

    public var selectedTimeRange: TimeRange? {
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
