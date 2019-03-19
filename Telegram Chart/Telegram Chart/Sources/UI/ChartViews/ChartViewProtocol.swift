//
// Created by Vadim on 2019-03-19.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public protocol ChartViewProtocol {
    var delegate: ChartViewDelegate? { get }
}

public protocol ChartViewDelegate: AnyObject {
    func chartView(_ chartView: ChartViewProtocol, alphaForPlot plot: Chart.Plot) -> CGFloat
}
