//
// Created by Vadim on 2019-03-22.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ScreenHelper {
    public private(set) static var thinLineWidth =  1 / UIScreen.main.scale
}


extension UIView {
    var integralBounds: CGRect {
        return convert((convert(bounds, to: nil).integral), from: nil)
    }
}

extension CGPoint {
    var integralFloor: CGPoint {
        return CGPoint(x: floor(x), y: floor(y))
    }
}