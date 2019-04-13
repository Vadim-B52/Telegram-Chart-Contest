//
// Created by Vadim on 2019-03-12.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartView: UIControl, ChartViewProtocol {

    private var layers = [CAShapeLayer]()
    private var chart: DrawingChart?

    public var lineWidth: CGFloat = 1

    public override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true // TODO: improve?
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        clipsToBounds = true
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let frame = plotFrame()
        layers.forEach { $0.frame = frame }
        redraw()
    }

    public func displayChart(_ chart: DrawingChart?, animated: Bool) {
        self.chart = chart
        updateLayers()
        if animated {
            redrawAnimated()
        } else {
            redraw()
        }
    }

    private func updateLayers() {
        let plotsCount = chart?.allPlots.count ?? 0
        let d = layers.count - plotsCount
        if d > 0 {
            for _ in 0..<d {
                layers.removeLast().removeFromSuperlayer()
            }
        } else if d < 0 {
            let frame = plotFrame()
            for _ in 0..<(-d) {
                let plotLayer = CAShapeLayer()
                plotLayer.frame = frame
                layer.insertSublayer(plotLayer, at: 0)
                layers.append(plotLayer)
            }
        }
    }

    private func plotFrame() -> CGRect {
        return layer.bounds
    }

    private func redraw() {
        guard let chart = chart else {
            return
        }

        for (idx, plot) in chart.allPlots.enumerated().reversed() {
            let plotLayer = layers[idx]
            let panel = makeChartPanel(chart: chart, plot: plot)
            panel.drawInContext(plotLayer, rect: plotLayer.bounds, apply: nil)
            plotLayer.opacity = chart.isPlotVisible(plot) ? 1 : 0
        }
    }

    private func redrawAnimated() {
        guard let chart = chart else {
            return
        }

        for (idx, plot) in chart.allPlots.enumerated() {
            let plotLayer = layers[idx]
            let animationGroup = CAAnimationGroup()
            let pathAnimation = CABasicAnimation(keyPath: "path")
            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            animationGroup.animations = [pathAnimation, opacityAnimation]
            animationGroup.duration = 0.4
            animationGroup.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)

            let panel = makeChartPanel(chart: chart, plot: plot)
            pathAnimation.fromValue = plotLayer.presentation()?.path ?? plotLayer.path
            panel.drawInContext(plotLayer, rect: plotLayer.bounds) { layer, path in
                pathAnimation.toValue = path
                plotLayer.path = path
            }

            opacityAnimation.fromValue = plotLayer.presentation()?.opacity ?? plotLayer.opacity
            opacityAnimation.toValue = chart.isPlotVisible(plot) ? 1 : 0
            plotLayer.opacity = chart.isPlotVisible(plot) ? 1 : 0

            plotLayer.add(animationGroup, forKey: nil)
        }
    }

    // TODO: type dispatch vs case
    private func makeChartPanel(chart: DrawingChart, plot: Chart.Plot) -> ChartPanel {
        switch plot.type {
        case .line:
            return LineChartPanel(chart: chart, plot: plot, lineWidth: lineWidth)
        case .area:
            return PercentageStackedAreaChartPanel(chart: chart, plot: plot, lineWidth: lineWidth)
        case .bar:
//          TODO: bar chart drawer if needed
            return StackedBarChartPanel(chart: chart, plot: plot, lineWidth: lineWidth)
        }
    }
}
