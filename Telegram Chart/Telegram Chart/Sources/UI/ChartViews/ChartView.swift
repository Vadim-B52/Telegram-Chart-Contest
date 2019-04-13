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
        for l in layers {
            l.frame = frame
        }
        redraw(animated: false)
    }

    public func displayChart(_ chart: DrawingChart?, animated: Bool) {
        self.chart = chart
        updateLayers()
        redraw(animated: animated)
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

    private func redraw(animated: Bool) {
        guard let chart = chart else {
            return
        }

        for (idx, plot) in chart.allPlots.enumerated().reversed() {
            let plotLayer = layers[idx]
            let panel = makeChartPanel(chart: chart, plot: plot)
            panel.drawInLayer(plotLayer, rect: plotLayer.bounds, animated: animated)
        }
    }

    // TODO: type dispatch vs case
    private func makeChartPanel(chart: DrawingChart, plot: Chart.Plot) -> ChartPanel {
        switch plot.type {
        case .line:
            return LineChartPanel(delegate: self, chart: chart, plot: plot, lineWidth: lineWidth)
        case .area:
            return PercentageStackedAreaChartPanel(delegate: self, chart: chart, plot: plot, lineWidth: lineWidth)
        case .bar:
//          TODO: bar chart drawer if needed
            return StackedBarChartPanel(delegate: self, chart: chart, plot: plot, lineWidth: lineWidth)
        }
    }
}

extension ChartView: ChartPanelDelegate {
    public func charPanel(_ panel: ChartPanel, applyPath path: CGPath, isVisible: Bool, toLayer layer: CAShapeLayer, animated: Bool) {
        layer.path = path
        layer.opacity = isVisible ? 1 : 0
        if animated {
            let animationGroup = CAAnimationGroup()
            let pathAnimation = CABasicAnimation(keyPath: "path")
            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            animationGroup.animations = [pathAnimation, opacityAnimation]
            animationGroup.duration = 0.4
            animationGroup.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)

            pathAnimation.fromValue = layer.presentation()?.path ?? layer.path
            pathAnimation.toValue = path

            opacityAnimation.fromValue = layer.presentation()?.opacity ?? layer.opacity
            opacityAnimation.toValue = isVisible ? 1 : 0

            layer.add(animationGroup, forKey: nil)
        }
    }
}
