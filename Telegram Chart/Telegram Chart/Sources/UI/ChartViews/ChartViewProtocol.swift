//
// Created by Vadim on 2019-03-19.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public protocol ChartViewProtocol: AnyObject {
    var chart: DrawingChart? { get set }

    // TODO: not common - remove
    var animationProgressDataSource: ChartViewAnimationProgressDataSource? { get set }
}

public protocol ChartViewAnimationProgressDataSource: AnyObject {
    func animationProgressAlpha(chartView: ChartViewProtocol) -> CGFloat?
}
