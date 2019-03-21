//
// Created by Vadim on 2019-03-20.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartViewContainer<ChartViewType: UIView & ChartViewProtocol>: UIView, CAAnimationDelegate {

    public let chartView: ChartViewType
    public let animatableChartView: ChartViewType
    private var chart: DrawingChart?
    private var transitionState: TransitionState?

    public init(_ factory: @autoclosure () -> ChartViewType) {
        chartView = factory()
        animatableChartView = factory()
        super.init(frame: .zero)

        chartView.backgroundColor = .clear
        chartView.frame = .zero
        chartView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(chartView)

        animatableChartView.backgroundColor = .clear
        animatableChartView.frame = .zero
        animatableChartView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(animatableChartView)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func displayChart(_ chart0: DrawingChart?, animated: Bool = false) {
        defer {
            self.chart = chart0
        }
        guard animated, transitionState == nil, let chart = chart0, let prevChart = self.chart else {
            performDeadTransitionToChart(chart0)
            return
        }
        performAnimatedTransitionToChart(chart, previousChart: prevChart)
    }

    private func performDeadTransitionToChart(_ chart: DrawingChart?) {
        chartView.chart = chart
        animatableChartView.chart = nil
        animatableChartView.layer.opacity = 0
        transitionState = nil
        animatableChartView.layer.removeAllAnimations()
    }

    private func performAnimatedTransitionToChart(_ chart: DrawingChart, previousChart: DrawingChart) {
        let link = CADisplayLink(target: self, selector: #selector(onRenderTime))
        link.preferredFramesPerSecond = 30
        link.add(to: .main, forMode: .common)

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.duration = 0.3
        animation.delegate = self
        animation.isRemovedOnCompletion = false

        let toShowPlot = previousChart.plots.count < chart.plots.count
        if toShowPlot {
            animatableChartView.layer.opacity = 0
            animation.fromValue = 0
            animation.toValue = 1
            transitionState = TransitionState(
                    displayLink: link,
                    formula: { $0 },
                    beginChart: previousChart,
                    endChart: chart,
                    beginChartReceiver: chartView,
                    endChartReceiver: animatableChartView)
        } else {
            animatableChartView.layer.opacity = 1
            animation.fromValue = 1
            animation.toValue = 0
            transitionState = TransitionState(
                    displayLink: link,
                    formula: { 1 - $0 },
                    beginChart: previousChart,
                    endChart: chart,
                    beginChartReceiver: animatableChartView,
                    endChartReceiver: chartView)
        }
        animatableChartView.layer.add(animation, forKey: "opacityAnimation")
    }

    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard let state = transitionState else {
            return
        }
        state.displayLink.invalidate()
        performDeadTransitionToChart(state.endChart)
    }

    @objc
    private func onRenderTime() {
        guard let state = transitionState, let opacity = animatableChartView.layer.presentation()?.opacity else {
            return
        }
        let elapsed = state.formula(opacity)

        let minD = state.endChart.valueRange.min - state.beginChart.valueRange.min
        let maxD = state.endChart.valueRange.max - state.beginChart.valueRange.max
        let valueRange = ValueRange(
                min: state.beginChart.valueRange.min + Int64(elapsed * Float(minD)),
                max: state.beginChart.valueRange.max + Int64(elapsed * Float(maxD)))

        state.beginChartReceiver.chart = DrawingChart(
                plots: state.beginChart.plots,
                timestamps: state.beginChart.timestamps,
                timeRange: state.beginChart.timeRange,
                selectedTimeRange: state.beginChart.selectedTimeRange,
                valueRangeCalculation: StaticValueRangeCalculation(valueRange: valueRange))

        state.endChartReceiver.chart = DrawingChart(
                plots: state.endChart.plots,
                timestamps: state.endChart.timestamps,
                timeRange: state.endChart.timeRange,
                selectedTimeRange: state.endChart.selectedTimeRange,
                valueRangeCalculation: StaticValueRangeCalculation(valueRange: valueRange))
    }

    private struct TransitionState {
        let displayLink: CADisplayLink
        let formula: ((Float) -> Float)
        let beginChart: DrawingChart
        let endChart: DrawingChart
        let beginChartReceiver: ChartViewProtocol
        let endChartReceiver: ChartViewProtocol
    }
}
