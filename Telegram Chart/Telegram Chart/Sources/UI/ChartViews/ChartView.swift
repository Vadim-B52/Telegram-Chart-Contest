//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartView: UIView {

    private let longPress = UILongPressGestureRecognizer()

    private var crosshairTimeIdx: Int? {
        didSet {
            setNeedsDisplay()
        }
    }

    public var chart: DrawingChart? = nil {
        didSet {
            setNeedsDisplay()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        isOpaque = true
        longPress.minimumPressDuration = 0
        longPress.addTarget(self, action: #selector(handleLongPress))
        addGestureRecognizer(longPress)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let chart = chart,
              let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let (timeRect, chartRect) = bounds.divided(atDistance: 30, from: .maxYEdge)

        ctx.saveGState()
        let timePanel = TimeAxisPanel(chart: chart)
        timePanel.drawInContext(ctx, rect: timeRect)
        ctx.restoreGState()

        ctx.saveGState()
        let valuePanel = ValueAxisPanel(chart: chart)
        valuePanel.drawInContext(ctx, rect: chartRect)
        ctx.restoreGState()

        for (idx, _) in chart.plots.enumerated() {
            ctx.saveGState()
            let panel = ChartPanel(chart: chart, plotIndex: idx)
            panel.drawInContext(ctx, rect: chartRect)
            ctx.restoreGState()
        }

        if let idx = crosshairTimeIdx {
            ctx.saveGState()
            let panel = CrosshairPanel(chart: chart, timestampIndex: idx)
            panel.drawInContext(ctx, rect: chartRect)
            ctx.restoreGState()
        }
    }

    @objc
    private func handleLongPress() {
        switch longPress.state {
        case .began:
            updateCrosshair(point: longPress.location(in: self))
            break
        case .changed:
            updateCrosshair(point: longPress.location(in: self))
            break
        default:
            break
        }
    }

    private func updateCrosshair(point: CGPoint) {
        guard let chart = chart else {
            return
        }
        let calc = DrawingChart.XCalculator(timeRange: chart.selectedTimeRange)
        let ts = calc.timestampAt(x: point.x, rect: bounds)
        crosshairTimeIdx = chart.closestIdxTo(timestamp: ts)
    }
}
