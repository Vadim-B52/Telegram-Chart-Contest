//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartView: UIView, ChartViewProtocol {

    private let timeSelector = CrosshairView()
    private var timePanelConfig: TimeAxisPanel.Config!
    private var valuePanelConfig: ValueAxisPanel.Config!

    public weak var colorSource: ChartViewColorSource? {
        didSet {
            reloadColors()
        }
    }

    public weak var dataSource: ChartViewDataSource?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        isOpaque = true
        
        timeSelector.translatesAutoresizingMaskIntoConstraints = false
        addSubview(timeSelector)
        NSLayoutConstraint.activate([
            timeSelector.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            timeSelector.leadingAnchor.constraint(equalTo: leadingAnchor),
            timeSelector.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            timeSelector.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        
        reloadColors()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let dataSource = dataSource,
              let ctx = UIGraphicsGetCurrentContext() else {
            return
        }

        let timestamps = dataSource.timestamps(chartView: self)
        let indexRange = dataSource.indexRange(chartView: self)
        let timeRange = dataSource.selectedTimeRange(chartView: self)
        let valueRange = dataSource.valueRange(chartView: self)
        let numberOfPlots = dataSource.numberOfPlots(chartView: self)
        
        var (timeRect, chartRect) = bounds.divided(atDistance: 24, from: .maxYEdge)
        chartRect = chartRect.inset(by: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0))

        let timePanel = TimeAxisPanel(timeRange: timeRange, config: timePanelConfig)
        timePanel.drawInContext(ctx, rect: timeRect)

        let valuePanel = ValueAxisPanel(valueRange: valueRange, config: valuePanelConfig)
        valuePanel.drawInContext(ctx, rect: chartRect)

        for idx in 0..<numberOfPlots {
            let (plot, alpha) = dataSource.chartView(self, plotDataAt: idx)
            let panel = ChartPanel(
                    timestamps: timestamps,
                    indexRange: indexRange,
                    timeRange: timeRange,
                    valueRange: valueRange,
                    plot: plot,
                    alpha: alpha,
                    lineWidth: 2)
            
            panel.drawInContext(ctx, rect: chartRect)
        }
    }

    public func reloadColors() {
        reloadTimePanelConfig()
        reloadValuePanelConfig()
        setNeedsDisplay()
    }

    public func reloadData() {
        setNeedsDisplay()
        // TODO: implement
    }

    private func reloadValuePanelConfig() {
        guard let colorSource = colorSource else {
            valuePanelConfig = ValueAxisPanel.Config(
                    axisColor: .gray,
                    zeroAxisColor: .gray,
                    textColor: .gray)
            return
        }
        valuePanelConfig = ValueAxisPanel.Config(
                axisColor: colorSource.zeroValueAxisColor(chartView: self),
                zeroAxisColor: colorSource.zeroValueAxisColor(chartView: self),
                textColor: colorSource.chartAxisLabelColor(chartView: self))
    }

    private func reloadTimePanelConfig() {
        guard let colorSource = colorSource else {
            timePanelConfig = TimeAxisPanel.Config(textColor: .gray)
            return
        }
        timePanelConfig = TimeAxisPanel.Config(textColor: colorSource.chartAxisLabelColor(chartView: self))

    }
}

public protocol ChartViewColorSource: AnyObject {
    func valueAxisColor(chartView: ChartView) -> UIColor
    func zeroValueAxisColor(chartView: ChartView) -> UIColor
    func chartAxisLabelColor(chartView: ChartView) -> UIColor
    func popupBackgroundColor(chartView: ChartView) -> UIColor
    func popupLabelColor(chartView: ChartView) -> UIColor
}
