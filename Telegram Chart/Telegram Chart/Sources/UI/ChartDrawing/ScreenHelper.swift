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