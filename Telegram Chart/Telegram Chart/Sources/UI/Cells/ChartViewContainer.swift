//
// Created by Vadim on 2019-03-20.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartViewContainer<ChartViewType: UIView & ChartViewProtocol>: UIView {

    let chartView: ChartViewType
    let transitioningChartView: ChartViewType
    private var animator: ChartViewAnimator?
    private var chart: DrawingChart?

    public init(_ factory: @autoclosure () -> ChartViewType) {
        chartView = factory()
        transitioningChartView = factory()
        super.init(frame: .zero)

        chartView.backgroundColor = .clear
        chartView.frame = .zero
        chartView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(chartView)

        transitioningChartView.backgroundColor = .clear
        transitioningChartView.frame = .zero
        transitioningChartView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(transitioningChartView)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func displayChart(_ chart0: DrawingChart?, animated: Bool = false) {
        defer {
            self.chart = chart0
        }
        guard animated, let chart = chart0, let prevChart = self.chart, animator == nil else {
            animator?.endAnimation()
            performDeadTransitionToChart(chart0)
            return
        }
        performAnimatedTransitionToChart(chart, oldChart: prevChart)
    }

    private func performDeadTransitionToChart(_ chart: DrawingChart?) {
        animator = nil
        chartView.alpha = 1
        chartView.chart = chart
        transitioningChartView.isHidden = true
        transitioningChartView.chart = nil
    }

    private func performAnimatedTransitionToChart(_ newChart: DrawingChart, oldChart: DrawingChart) {
        let startValue = ChartViewAnimator.Value(valueRange: oldChart.valueRange, alpha: 0)
        let endValue = ChartViewAnimator.Value(valueRange: newChart.valueRange, alpha: 1)
        let toShow = oldChart.plots.count < newChart.plots.count

        transitioningChartView.alpha = 1
        transitioningChartView.isHidden = false
        transitioningChartView.chart = oldChart

        let animator = ChartViewAnimator(animationDuration: 0.3, startValue: startValue, endValue: endValue)
        animator.callback = { [weak self] (finished, value) in
            guard let self = self else {
                return
            }

            // TODO: remove bool
            if toShow {
                self.chartView.alpha = value.alpha
            } else {
                self.transitioningChartView.alpha = 1 - value.alpha
            }

            self.chartView.chart = DrawingChart(
                    plots: newChart.plots,
                    timestamps: newChart.timestamps,
                    timeRange: newChart.timeRange,
                    selectedTimeRange: newChart.selectedTimeRange,
                    valueRangeCalculation: StaticValueRangeCalculation(valueRange: value.valueRange))

            self.transitioningChartView.chart = DrawingChart(
                    plots: oldChart.plots,
                    timestamps: oldChart.timestamps,
                    timeRange: oldChart.timeRange,
                    selectedTimeRange: oldChart.selectedTimeRange,
                    valueRangeCalculation: StaticValueRangeCalculation(valueRange: value.valueRange))

            if finished {
                self.performDeadTransitionToChart(newChart)
            }
        }
        self.animator = animator
        animator.startAnimation()
    }
}
