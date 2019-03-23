//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class MiniChartView: UIControl, ChartViewProtocol {
    
    public var chart: DrawingChart? {
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
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let chart = chart,
              let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        let bounds = integralBounds
        let drawingRect = bounds.inset(by: UIEdgeInsets(top: 11, left: 0, bottom: 9, right: 0))
        for plot in chart.plots {
            let panel = ChartPanel(
                    timestamps: chart.timestamps,
                    indexRange: chart.indexRange,
                    timeRange: chart.timeRange,
                    valueRange: chart.valueRange,
                    plot: plot,
                    lineWidth: 1)
            
            panel.drawInContext(ctx, rect: drawingRect)
        }
    }
}
