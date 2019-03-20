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

public class ChartTableViewCell: UITableViewCell, ChartViewDelegate {

    private let chartView = ChartView()
    private let miniChartView = MiniChartView()
    private let timeSelector = MiniChartTimeSelectorView()

    private var chartAnimator: ChartViewAnimator?
    private var miniChartAnimator: ChartViewAnimator?
    private var chart: Chart?
    private var state: ChartState?

    public weak var delegate: ChartTableViewCellDelegate?

    public override var backgroundColor: UIColor? {
        get {
            return super.backgroundColor
        }
        set {
            super.backgroundColor = newValue
            chartView.backgroundColor = newValue
            miniChartView.backgroundColor = newValue
        }
    }

    public override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        chartView.delegate = self
        miniChartView.delegate = self
        chartView.backgroundColor = .white
        miniChartView.backgroundColor = .white

        chartView.translatesAutoresizingMaskIntoConstraints = false
        miniChartView.translatesAutoresizingMaskIntoConstraints = false
        timeSelector.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chartView)
        contentView.addSubview(miniChartView)
        addSubview(timeSelector)

        let views = ["chartView": chartView, "miniChartView": miniChartView]
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[chartView][miniChartView(==60)]|",
                options: [], metrics: nil, views: views))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[chartView]-15-|",
                options: [], metrics: nil, views: views))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[miniChartView]-15-|",
                options: [], metrics: nil, views: views))
        NSLayoutConstraint.activate([
            timeSelector.topAnchor.constraint(equalTo: miniChartView.topAnchor),
            timeSelector.leadingAnchor.constraint(equalTo: miniChartView.leadingAnchor),
            timeSelector.bottomAnchor.constraint(equalTo: miniChartView.bottomAnchor),
            timeSelector.trailingAnchor.constraint(equalTo: miniChartView.trailingAnchor),
        ])

        timeSelector.addTarget(self, action: #selector(handleValueChanged), for: .valueChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        chartView.chart = nil
        miniChartView.chart = nil
        timeSelector.timeRange = nil
        timeSelector.selectedTimeRange = nil
    }

    public func display(chart: Chart, state: ChartState) {
        self.chart = chart
        self.state = state
        timeSelector.timeRange = chart.timeRange
        timeSelector.selectedTimeRange = state.selectedTimeRange
        chartView.chart = chartViewDrawingChart()
        miniChartView.chart = miniChartViewDrawingChart()
    }

    public func hidePlot(plotId: String) {
        guard let _ = chart, let state = state else {
            return
        }
        let oldChart = chartViewDrawingChart()!
        let oldMiniChart = miniChartViewDrawingChart()!
        self.state = state.byDisablingPlotWith(identifier: plotId)
        let newChart = chartViewDrawingChart()!
        let newMiniChart = miniChartViewDrawingChart()!

        chartAnimator = hideAnimator(chartView: chartView, oldChart: oldChart, newChart: newChart, plotId: plotId) {
            self.chartAnimator = nil
        }
        chartAnimator?.startAnimation()

        miniChartAnimator = hideAnimator(chartView: miniChartView, oldChart: oldMiniChart, newChart: newMiniChart, plotId: plotId) {
            self.miniChartAnimator = nil
        }
        miniChartAnimator?.startAnimation()
    }

    public func showPlot(plotId: String) {
        guard let _ = chart, let state = state else {
            return
        }
        let oldChart = chartViewDrawingChart()!
        let oldMiniChart = miniChartViewDrawingChart()!
        self.state = state.byEnablingPlotWith(identifier: plotId)
        let newChart = chartViewDrawingChart()!
        let newMiniChart = miniChartViewDrawingChart()!

        chartAnimator = showAnimator(chartView: chartView, oldChart: oldChart, newChart: newChart, plotId: plotId) {
            self.chartAnimator = nil
        }
        chartAnimator?.startAnimation()

        miniChartAnimator = showAnimator(chartView: miniChartView, oldChart: oldMiniChart, newChart: newMiniChart, plotId: plotId) {
            self.miniChartAnimator = nil
        }
        miniChartAnimator?.startAnimation()
    }

    @objc
    private func handleValueChanged() {
        guard let selectedTimeRange = timeSelector.selectedTimeRange else {
            return
        }
        state = state?.byChanging(selectedTimeRange: selectedTimeRange)
        chartView.chart = chartViewDrawingChart()
        delegate?.chartTableViewCell(self, didChangeSelectedTimeRange: selectedTimeRange)
    }

    private func chartViewDrawingChart() -> DrawingChart? {
        guard let chart = chart, let state = state else {
            return nil
        }
        let plots = chart.plots.filter {
            state.enabledPlotId.contains($0.identifier)
        }
        return DrawingChart(
                plots: plots,
                timestamps: chart.timestamps,
                timeRange: chart.timeRange,
                selectedTimeRange: state.selectedTimeRange,
                valueRangeCalculation: SelectedValueRangeCalculation())
    }

    private func miniChartViewDrawingChart() -> DrawingChart? {
        guard let chart = chart, let state = state else {
            return nil
        }
        let plots = chart.plots.filter {
            state.enabledPlotId.contains($0.identifier)
        }
        return DrawingChart(
                plots: plots,
                timestamps: chart.timestamps,
                timeRange: chart.timeRange,
                valueRangeCalculation: FullValueRangeCalculation())
    }

    private func showAnimator(chartView: ChartViewProtocol,
                              oldChart: DrawingChart,
                              newChart: DrawingChart,
                              plotId: String,
                              completion: @escaping (() -> Void)) -> ChartViewAnimator {
        let startValue = ChartViewAnimator.Value(valueRange: oldChart.valueRange, alpha: 0)
        let endValue = ChartViewAnimator.Value(valueRange: newChart.valueRange, alpha: 1)
        let animator = ChartViewAnimator(identifier: plotId, animationDuration: 0.3, startValue: startValue, endValue: endValue)
        animator.callback = { (finished, value) in
            chartView.chart = DrawingChart(
                    plots: newChart.plots,
                    timestamps: newChart.timestamps,
                    timeRange: newChart.timeRange,
                    selectedTimeRange: newChart.selectedTimeRange,
                    valueRangeCalculation: StaticValueRangeCalculation(valueRange: value.valueRange))

            if finished {
                chartView.chart = newChart
                completion()
            }
        }
        return animator
    }

    private func hideAnimator(chartView: ChartViewProtocol,
                              oldChart: DrawingChart,
                              newChart: DrawingChart,
                              plotId: String,
                              completion: @escaping (() -> Void)) -> ChartViewAnimator {
        let startValue = ChartViewAnimator.Value(valueRange: oldChart.valueRange, alpha: 1)
        let endValue = ChartViewAnimator.Value(valueRange: newChart.valueRange, alpha: 0)
        let animator = ChartViewAnimator(identifier: plotId, animationDuration: 0.3, startValue: startValue, endValue: endValue)
        animator.callback = { (finished, value) in
            chartView.chart = DrawingChart(
                    plots: oldChart.plots,
                    timestamps: oldChart.timestamps,
                    timeRange: oldChart.timeRange,
                    selectedTimeRange: oldChart.selectedTimeRange,
                    valueRangeCalculation: StaticValueRangeCalculation(valueRange: value.valueRange))

            if finished {
                chartView.chart = newChart
                completion()
            }
        }
        return animator
    }

    public func chartView(_ chartView: ChartViewProtocol, alphaForPlot plot: Chart.Plot) -> CGFloat {
        if chartView === self.chartView, let animator = chartAnimator, animator.identifier == plot.identifier  {
            return animator.currentValue.alpha
        } else if chartView === miniChartView, let animator = miniChartAnimator, animator.identifier == plot.identifier {
            return animator.currentValue.alpha
        }
        return 1
    }
}

public extension ChartTableViewCell {
    public weak var timeSelectorViewColorSource: MiniChartTimeSelectorViewColorSource? {
        get {
            return timeSelector.colorSource
        }
        set {
            timeSelector.colorSource = newValue
        }
    }
}

public extension ChartTableViewCell {
    public weak var chartViewColorSource: ChartViewColorSource? {
        get {
            return chartView.colorSource
        }
        set {
            chartView.colorSource = newValue
        }
    }
}
