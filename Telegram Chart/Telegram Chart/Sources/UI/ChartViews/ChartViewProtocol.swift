//
// Created by Vadim on 2019-03-19.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public enum ChartViewAnimation {
    case none, smooth, linear
}

public protocol ChartViewProtocol: AnyObject {
    func displayChart(_ :DrawingChart?, animation: ChartViewAnimation)
}
