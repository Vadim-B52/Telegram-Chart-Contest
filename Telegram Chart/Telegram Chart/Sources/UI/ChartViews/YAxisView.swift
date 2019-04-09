//
// Created by Vadim on 2019-04-08.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

class YAxisView: UIView, ChartViewProtocol {

    private var chart: DrawingChart?
    var valuePanelConfig: ValueAxisPanel.Config! {
        didSet {
            if valuePanelConfig == nil {
                valuePanelConfig = ValueAxisPanel.Config(
                        axisColor: .gray,
                        zeroAxisColor: .gray,
                        textColor: .gray)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        isOpaque = true
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentMode = .redraw
        isOpaque = true
        backgroundColor = .clear
    }

    func displayChart(_ chart: DrawingChart?, animated: Bool) {
        self.chart = chart
        setNeedsDisplay()
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let chart = chart,
              let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        let bounds = self.integralBounds

        let valuePanelConfig = self.valuePanelConfig!
        let (zeroLine, _) = bounds.divided(atDistance: ScreenHelper.lightLineWidth, from: .maxYEdge)
        valuePanelConfig.zeroAxisColor.setFill()
        ctx.fill(zeroLine)

//        if let animationProgress = animationProgressDataSource?.animationProgressAlpha(chartView: self) {
//            let color = valuePanelConfig.axisColor.withAlphaComponent(animationProgress)
//            valuePanelConfig = ValueAxisPanel.Config(
//                    axisColor: color,
//                    zeroAxisColor: color,
//                    textColor: valuePanelConfig.textColor.withAlphaComponent(animationProgress))
//        }
        let valuePanel = ValueAxisPanel(chart: chart, config: valuePanelConfig)
        valuePanel.drawInContext(ctx, rect: bounds)
    }
}
