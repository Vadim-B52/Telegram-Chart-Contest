//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class MiniChartView: UIControl, ChartViewProtocol {

    private let timeSelector = MiniChartTimeSelectorView()
    public weak var dataSource: ChartViewDataSource?
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
        guard let dataSource = dataSource,
              let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        let drawingRect = bounds.inset(by: UIEdgeInsets(top: 11, left: 0, bottom: 9, right: 0))
        let timestamps = dataSource.timestamps(chartView: self)
        let indexRange = dataSource.indexRange(chartView: self)
        let timeRange = dataSource.timeRange(chartView: self)
        let valueRange = dataSource.valueRange(chartView: self)
        for idx in 0..<dataSource.numberOfPlots(chartView: self) {
            let (plot, alpha) = dataSource.chartView(self, plotDataAt: idx)
            let panel = ChartPanel(
                    timestamps: timestamps,
                    indexRange: indexRange,
                    timeRange: timeRange,
                    valueRange: valueRange,
                    plot: plot,
                    alpha: alpha,
                    lineWidth: 1)
            
            panel.drawInContext(ctx, rect: drawingRect)
        }
    }

    public func reloadData() {
        timeSelector.timeRange = dataSource?.timeRange(chartView: self)
        timeSelector.selectedTimeRange = dataSource?.selectedTimeRange(chartView: self)
        setNeedsDisplay()
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
