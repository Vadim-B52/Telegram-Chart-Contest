//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartView: UIView {

    private let timeSelector = CrosshairView()
    private var timePanelConfig: TimeAxisPanel.Config!
    private var valuePanelConfig: ValueAxisPanel.Config!

    public weak var colorSource: ChartViewColorSource? {
        didSet {
            reloadColors()
        }
    }

    public var chart: DrawingChart? = nil {
        didSet {
            setNeedsDisplay()
            timeSelector.chart = chart
        }
    }

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
        guard let chart = chart,
              let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        
        var (timeRect, chartRect) = bounds.divided(atDistance: 24, from: .maxYEdge)
        chartRect = chartRect.inset(by: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0))

        let timePanel = TimeAxisPanel(chart: chart, config: timePanelConfig)
        timePanel.drawInContext(ctx, rect: timeRect)

        let valuePanel = ValueAxisPanel(chart: chart, config: valuePanelConfig)
        valuePanel.drawInContext(ctx, rect: chartRect)

        let config = ChartPanel.Config(lineWidth: 2)
        for (idx, _) in chart.plots.enumerated() {
            let panel = ChartPanel(chart: chart, plotIndex: idx, config: config)
            panel.drawInContext(ctx, rect: chartRect)
        }
    }

    public func reloadColors() {
        reloadTimePanelConfig()
        reloadValuePanelConfig()
        setNeedsDisplay()
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
