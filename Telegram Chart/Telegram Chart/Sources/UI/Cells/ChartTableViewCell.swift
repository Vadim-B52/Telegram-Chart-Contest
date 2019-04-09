//
//  ChartTableViewCell.swift
//  Telegram Chart
//
//  Created by Vadim on 11/03/2019.
//  Copyright © 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public protocol ChartTableViewCellDelegate: AnyObject {
    func chartTableViewCell(_ cell: ChartTableViewCell, didChangeSelectedTimeRange timeRange: TimeRange)
}

public class ChartTableViewCell: UITableViewCell {

    private let chartView = CompoundChartView()
    private let miniChartView = ChartView()
    private let timeSelector = MiniChartTimeSelectorView()

    private var chart: Chart?
    private var state: ChartState?
    fileprivate var timeAxisDescription: TimeAxisDescription?

    public weak var delegate: ChartTableViewCellDelegate?
    public weak var chartViewColorSource: ChartViewColorSource? {
        didSet {
            chartView.colorSource = chartViewColorSource
        }
    }
    public weak var timeSelectorViewColorSource: MiniChartTimeSelectorViewColorSource? {
        didSet {
            timeSelector.colorSource = timeSelectorViewColorSource
        }
    }

    public override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        chartView.timeAxisDelegate = self
        chartView.translatesAutoresizingMaskIntoConstraints = false
        miniChartView.translatesAutoresizingMaskIntoConstraints = false

        let miniChartViewWrapper = UIView()
        miniChartViewWrapper.translatesAutoresizingMaskIntoConstraints = false
        miniChartViewWrapper.addSubview(miniChartView)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(
                    item: miniChartViewWrapper, attribute: .top,
                    relatedBy: .equal,
                    toItem: miniChartView, attribute: .top,
                    multiplier: 1, constant: -11),
            NSLayoutConstraint(
                    item: miniChartViewWrapper, attribute: .bottom,
                    relatedBy: .equal,
                    toItem: miniChartView, attribute: .bottom,
                    multiplier: 1, constant: 9),
            NSLayoutConstraint(
                    item: miniChartViewWrapper, attribute: .leading,
                    relatedBy: .equal,
                    toItem: miniChartView, attribute: .leading,
                    multiplier: 1, constant: 0),
            NSLayoutConstraint(
                    item: miniChartViewWrapper, attribute: .trailing,
                    relatedBy: .equal,
                    toItem: miniChartView, attribute: .trailing,
                    multiplier: 1, constant: 0),
        ])

        timeSelector.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chartView)
        contentView.addSubview(miniChartViewWrapper)
        addSubview(timeSelector)

        let views = ["chartView": chartView, "miniChartView": miniChartViewWrapper]
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|[chartView][miniChartView(==60)]|",
            metrics: nil,
            views: views))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-15-[chartView]-15-|",
            metrics: nil,
            views: views))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-15-[miniChartView]-15-|",
            metrics: nil,
            views: views))
        NSLayoutConstraint.activate([
            NSLayoutConstraint(
                item: timeSelector, attribute: .centerX,
                relatedBy: .equal,
                toItem: miniChartViewWrapper, attribute: .centerX,
                multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: timeSelector, attribute: .centerY,
                relatedBy: .equal,
                toItem: miniChartViewWrapper, attribute: .centerY,
                multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: timeSelector, attribute: .height,
                relatedBy: .equal,
                toItem: miniChartViewWrapper, attribute: .height,
                multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: timeSelector, attribute: .width,
                relatedBy: .equal,
                toItem: miniChartViewWrapper, attribute: .width,
                multiplier: 1, constant: 30),
        ])

        timeSelector.addTarget(self, action: #selector(handleValueChanged), for: .valueChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        chartView.displayChart(nil, animated: false)
        miniChartView.displayChart(nil, animated: false)
        timeSelector.timeRange = nil
        timeSelector.selectedTimeRange = nil
    }

    public func display(chart: Chart, state: ChartState) {
        self.timeAxisDescription = nil
        self.chart = chart
        self.state = state
        timeSelector.timeRange = chart.timeRange
        timeSelector.selectedTimeRange = state.selectedTimeRange
        chartView.displayChart(chartViewDrawingChart(), animated: false)
        miniChartView.displayChart(miniChartViewDrawingChart(), animated: false)
    }

    public func hidePlot(plotId: String) {
        guard let _ = chart, let state = state else {
            return
        }
        self.state = state.byDisablingPlotWith(identifier: plotId)
        chartView.displayChart(chartViewDrawingChart(), animated: true)
        miniChartView.displayChart(miniChartViewDrawingChart(), animated: true)
    }

    public func showPlot(plotId: String) {
        guard let _ = chart, let state = state else {
            return
        }
        self.state = state.byEnablingPlotWith(identifier: plotId)
        chartView.displayChart(chartViewDrawingChart(), animated: true)
        miniChartView.displayChart(miniChartViewDrawingChart(), animated: true)
    }

    @objc
    private func handleValueChanged() {
        guard let selectedTimeRange = timeSelector.selectedTimeRange else {
            return
        }
        state = state?.byChanging(selectedTimeRange: selectedTimeRange)
        chartView.displayChart(chartViewDrawingChart(), animated: false)
        delegate?.chartTableViewCell(self, didChangeSelectedTimeRange: selectedTimeRange)
    }

    private func chartViewDrawingChart() -> DrawingChart? {
        guard let chart = chart, let state = state else {
            return nil
        }
        let vrc = SelectedValueRangeCalculation()
        return DrawingChart(
                allPlots: chart.plots,
                enabledPlotId: state.enabledPlotId,
                timestamps: chart.timestamps,
                timeRange: chart.timeRange,
                selectedTimeRange: state.selectedTimeRange,
                valueRangeCalculation: chart.chartType == .yScaled ? YScaledValueRangeCalculation(internalCalculation: vrc) : vrc,
                yAxisCalculation: ValueRangeHasYAxis())
    }

    private func miniChartViewDrawingChart() -> DrawingChart? {
        guard let chart = chart, let state = state else {
            return nil
        }
        let vrc = FullValueRangeCalculation()
        return DrawingChart(
                allPlots: chart.plots,
                enabledPlotId: state.enabledPlotId,
                timestamps: chart.timestamps,
                timeRange: chart.timeRange,
                valueRangeCalculation: chart.chartType == .yScaled ? YScaledValueRangeCalculation(internalCalculation: vrc) : vrc,
                yAxisCalculation: ValueRangeNoYAxisStrategy())
    }
}

extension ChartTableViewCell: ChartViewTimeAxisDelegate {

    public func chartView(_ chartView: CompoundChartView, didChangeTimeAxisDescription description: TimeAxisDescription?) {
        self.timeAxisDescription = description
    }

    public func timeAxisDescription(chartView: CompoundChartView) -> TimeAxisDescription? {
        return timeAxisDescription
    }
}
