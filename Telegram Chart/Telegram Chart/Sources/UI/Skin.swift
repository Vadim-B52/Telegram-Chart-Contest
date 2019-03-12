//
//  Skin.swift
//  Telegram Chart
//
//  Created by Vadim on 11/03/2019.
//  Copyright © 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public protocol Skin {
    var sectionHeaderColor: UIColor { get }
    var cellBackgroundColor: UIColor { get }
    var separatorColor: UIColor { get }
}

//public class NightSkin: Skin {
//
//    public var sectionHeaderColor: UIColor {
//        return
//    }
//
//    public var cellBackgroundColor: UIColor {
//        return
//    }
//}

public class DaySkin: Skin {
    public var sectionHeaderColor: UIColor {
        return UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1)
    }
    
    public var cellBackgroundColor: UIColor {
        return UIColor.white
    }

    public var separatorColor: UIColor {
        return UIColor(red: 0.87, green: 0.87, blue: 0.88, alpha: 1)
    }
}
