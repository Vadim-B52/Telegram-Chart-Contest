//
// Created by Vadim on 2019-03-22.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ScreenHelper {
    public private(set) static var lightLineWidth : CGFloat =  {
        let scale = UIScreen.main.scale
        if scale < 2 {
            return 1
        }
        if scale < 3 {
            return 0.5
        }
        return 1 / UIScreen.main.scale * 2
    }()
    
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