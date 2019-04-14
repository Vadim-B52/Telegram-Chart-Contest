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
    var valueAxisColor: UIColor { get }
    var zeroValueAxisColor: UIColor { get }
    var chartAxisLabelColor: UIColor { get }
    var popupBackgroundColor: UIColor { get }
    var popupLabelColor: UIColor { get }
    var colorToUseForAdjusting: UIColor { get }
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

    public var valueAxisColor: UIColor {
        return UIColor(red: 0.11, green: 0.16, blue: 0.21, alpha: 1)
    }

    public var zeroValueAxisColor: UIColor {
        return UIColor(red: 0.07, green: 0.12, blue: 0.14, alpha: 1)
    }

    public var chartAxisLabelColor: UIColor {
        return UIColor(red: 0.37, green: 0.43, blue: 0.49, alpha: 1)
    }

    public var popupBackgroundColor: UIColor {
        return UIColor(red: 0.11, green: 0.16, blue: 0.21, alpha: 1)
    }

    public var popupLabelColor: UIColor {
        return UIColor.white
    }

    public var colorToUseForAdjusting: UIColor {
        return UIColor(red: 0.129, green: 0.184, blue: 0.247, alpha: 1)
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
    
    public var valueAxisColor: UIColor {
        return UIColor(white: 0.95, alpha: 1)
    }
    
    public var zeroValueAxisColor: UIColor {
        return UIColor(white: 0.87, alpha: 1)
    }
    
    public var chartAxisLabelColor: UIColor {
        return UIColor(red: 0.56, green: 0.59, blue: 0.61, alpha: 1)
    }
    
    public var popupBackgroundColor: UIColor {
        return UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1)
    }
    
    public var popupLabelColor: UIColor {
        return UIColor(red: 0.42, green: 0.42, blue: 0.4, alpha: 1)
    }

    public var colorToUseForAdjusting: UIColor {
        return UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    }
}
