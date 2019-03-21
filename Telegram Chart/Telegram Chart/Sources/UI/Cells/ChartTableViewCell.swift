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

    private let chartViewContainer: ChartViewContainer<ChartView> = ChartViewContainer(ChartView())
    private let miniChartViewContainer: ChartViewContainer<MiniChartView> = ChartViewContainer(MiniChartView())
    private let timeSelector = MiniChartTimeSelectorView()

    private var chart: Chart?
    private var state: ChartState?

    public weak var delegate: ChartTableViewCellDelegate?
    public weak var chartViewColorSource: ChartViewColorSource? {
        didSet {
            chartViewContainer.chartView1.colorSource = chartViewColorSource
            chartViewContainer.chartView2.colorSource = chartViewColorSource
        }
    }
    public weak var timeSelectorViewColorSource: MiniChartTimeSelectorViewColorSource? {
        didSet {
            timeSelector.colorSource = timeSelectorViewColorSource
        }
    }

    public override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        chartViewContainer.translatesAutoresizingMaskIntoConstraints = false
        miniChartViewContainer.translatesAutoresizingMaskIntoConstraints = false
        timeSelector.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chartViewContainer)
        contentView.addSubview(miniChartViewContainer)
        addSubview(timeSelector)

        let views = ["chartView": chartViewContainer, "miniChartView": miniChartViewContainer]
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[chartView][miniChartView(==60)]|",
                options: [], metrics: nil, views: views))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[chartView]-15-|",
                options: [], metrics: nil, views: views))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[miniChartView]-15-|",
                options: [], metrics: nil, views: views))
        NSLayoutConstraint.activate([
            timeSelector.topAnchor.constraint(equalTo: miniChartViewContainer.topAnchor),
            timeSelector.leadingAnchor.constraint(equalTo: miniChartViewContainer.leadingAnchor),
            timeSelector.bottomAnchor.constraint(equalTo: miniChartViewContainer.bottomAnchor),
            timeSelector.trailingAnchor.constraint(equalTo: miniChartViewContainer.trailingAnchor),
        ])

        timeSelector.addTarget(self, action: #selector(handleValueChanged), for: .valueChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        chartViewContainer.displayChart(nil)
        miniChartViewContainer.displayChart(nil)
        timeSelector.timeRange = nil
        timeSelector.selectedTimeRange = nil
    }

    public func display(chart: Chart, state: ChartState) {
        self.chart = chart
        self.state = state
        timeSelector.timeRange = chart.timeRange
        timeSelector.selectedTimeRange = state.selectedTimeRange
        chartViewContainer.displayChart(chartViewDrawingChart())
        miniChartViewContainer.displayChart(miniChartViewDrawingChart())
    }

    public func hidePlot(plotId: String) {
        guard let _ = chart, let state = state else {
            return
        }
        self.state = state.byDisablingPlotWith(identifier: plotId)
        chartViewContainer.displayChart(chartViewDrawingChart(), animated: true)
        miniChartViewContainer.displayChart(miniChartViewDrawingChart(), animated: true)
    }

    public func showPlot(plotId: String) {
        guard let _ = chart, let state = state else {
            return
        }
        self.state = state.byEnablingPlotWith(identifier: plotId)
        chartViewContainer.displayChart(chartViewDrawingChart(), animated: true)
        miniChartViewContainer.displayChart(miniChartViewDrawingChart(), animated: true)
    }

    @objc
    private func handleValueChanged() {
        guard let selectedTimeRange = timeSelector.selectedTimeRange else {
            return
        }
        state = state?.byChanging(selectedTimeRange: selectedTimeRange)
        chartViewContainer.displayChart(chartViewDrawingChart())
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
}
