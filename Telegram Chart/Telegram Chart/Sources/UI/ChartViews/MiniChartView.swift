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
        let drawingRect = bounds.inset(by: UIEdgeInsets(top: 11, left: 0, bottom: 9, right: 0))
        let config = ChartPanel.Config(lineWidth: 1)
        for (idx, _) in chart.plots.enumerated() {
            let panel = ChartPanel(chart: chart, plotIndex: idx, config: config)
            panel.drawInContext(ctx, rect: drawingRect)
        }
    }

    @objc
    private func handleValueChanged() {
        sendActions(for: .valueChanged)
    }
}

public extension MiniChartView {
    public weak var miniChartTimeSelectorViewColorSource: MiniChartTimeSelectorViewColorSource? {
        get {
            return timeSelector.colorSource
        }
        set {
            timeSelector.colorSource = newValue
        }
    }
}
