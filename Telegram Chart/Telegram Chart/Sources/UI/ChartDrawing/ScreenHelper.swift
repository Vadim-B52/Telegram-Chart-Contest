//
// Created by Vadim on 2019-03-22.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ScreenHelper {

    public private(set) static var screenScale = UIScreen.main.scale

    public private(set) static var lightLineWidth : CGFloat =  {
        let scale = screenScale
        if scale < 2 {
            return 1
        }
        if scale < 3 {
            return 0.5
        }
        return 1 / screenScale * 2
    }()
    
    public private(set) static var thinLineWidth =  1 / screenScale
}

// TODO: clean up

extension UIView {
    var integralBounds: CGRect {
        return self.bounds
//        return convert((convert(bounds, to: nil).integral), from: nil)
    }
}

extension CGFloat {
    var screenScaledFloor: CGFloat {
        return self
//        let scale = ScreenHelper.screenScale
//        return floor(self * scale) / scale
    }
}

extension CGPoint {
    var screenScaledFloor: CGPoint {
        return self
//        return CGPoint(x: x.screenScaledFloor, y: y.screenScaledFloor)
    }

    var integralFloor: CGPoint {
        return self
//        return CGPoint(x: floor(x), y: floor(y))
    }
}

extension CGSize {
    var integralCeil: CGSize {
        return self
//        return CGSize(width: ceil(width), height: ceil(height))
    }
}