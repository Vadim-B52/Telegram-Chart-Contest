//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class MiniChartView: UIControl, ChartViewProtocol {

    private let timeSelector = MiniChartTimeSelectorView()

    public weak var delegate: ChartViewDelegate?

    public var chart: DrawingChart? {
        didSet {
            timeSelector.timeRange = chart?.timeRange
            timeSelector.selectedTimeRange = chart?.selectedTimeRange
            setNeedsDisplay()
        }
    }

    public var selectedTimeRange: TimeRange? {
        return timeSelector.selectedTimeRange
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
        for plot in chart.plots {
            let alpha: CGFloat = delegate?.chartView(self, alphaForPlot: plot) ?? 1
            let panel = ChartPanel(
                    timestamps: chart.timestamps,
                    indexRange: chart.indexRange,
                    timeRange: chart.timeRange,
                    valueRange: chart.valueRange,
                    plot: plot,
                    alpha: alpha,
                    lineWidth: 1)
            
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
