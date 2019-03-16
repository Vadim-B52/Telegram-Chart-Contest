//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class MiniChartView: UIControl {

    private let timeSelector = MiniChartTimeSelectorView()

    public var chart: DrawingChart? = nil {
        didSet {
            timeSelector.timeRange = chart?.timeRange
            setNeedsDisplay()
        }
    }

    public var selectedTimeRange: TimeRange? {
        get {
            return timeSelector.selectedTimeRange
        }
        set {
            timeSelector.selectedTimeRange = newValue
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        isOpaque = true
        addSubview(timeSelector)

        timeSelector.addTarget(self, action: #selector(handleValueChanged), for: .valueChanged)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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

    @objc
    private func handleValueChanged() {
        sendActions(for: .valueChanged)
    }
}
