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
    var mainTextColor: UIColor { get }
    var navigationBarColor: UIColor { get }
    var timeSelectorDimmingColor: UIColor { get }
    var timeSelectorControlColor: UIColor { get }
    var timeSelectorChevronColor: UIColor { get }
    var barStyle: UIBarStyle { get }
    var rowSelectionColor: UIColor { get }
}

extension Skin {
    public var navigationBarColor: UIColor {
        return cellBackgroundColor
    }
}

public class NightSkin: Skin {

    public var sectionHeaderColor: UIColor {
        return UIColor(red: 0.09, green: 0.13, blue: 0.17, alpha: 1)
    }

    public var cellBackgroundColor: UIColor {
        return UIColor(red: 0.13, green: 0.18, blue: 0.24, alpha: 1)
    }

    public var separatorColor: UIColor {
        return UIColor(red: 0.10, green: 0.14, blue: 0.18, alpha: 1)
    }

    public var mainTextColor: UIColor {
        return UIColor.white
    }

    public var timeSelectorDimmingColor: UIColor {
        return  UIColor(red: 0.21, green: 0.27, blue: 0.35, alpha: 0.6)
    }

    public var timeSelectorControlColor: UIColor {
        return  UIColor(red: 0.21, green: 0.27, blue: 0.35, alpha: 0.8)
    }

    public var timeSelectorChevronColor: UIColor {
        return UIColor.white
    }

    public var barStyle: UIBarStyle {
        return .black
    }

    public var rowSelectionColor: UIColor {
        return UIColor(white: 0.85, alpha: 0.3)
    }
}

public class DaySkin: Skin {
    public var sectionHeaderColor: UIColor {
        return UIColor(red: 0.94, green: 0.94, blue: 0.95, alpha: 1)
    }
    
    public var cellBackgroundColor: UIColor {
        return UIColor.white
    }

    public var separatorColor: UIColor {
        return UIColor(red: 0.87, green: 0.87, blue: 0.88, alpha: 1)
    }

    public var mainTextColor: UIColor {
        return UIColor.black
    }

    public var navigationBarColor: UIColor {
        return UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)
    }

    public var timeSelectorDimmingColor: UIColor {
        return  UIColor.black.withAlphaComponent(0.1)
    }

    public var timeSelectorControlColor: UIColor {
        return  UIColor.black.withAlphaComponent(0.2)
    }

    public var timeSelectorChevronColor: UIColor {
        return UIColor.white
    }

    public var barStyle: UIBarStyle {
        return .default
    }

    public var rowSelectionColor: UIColor {
        return UIColor(white: 0.85, alpha: 1)
    }
}
