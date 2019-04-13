//
//  Fonts.swift
//  Belotitskiy Chart
//
//  Created by Vadim on 05/04/2019.
//  Copyright © 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public protocol FontsProtocol {
    func bold11() -> UIFont
    func bold13() -> UIFont
    func light11() -> UIFont
    func semibold11() -> UIFont
    func semibold12() -> UIFont
    func regular11() -> UIFont
    func regular12() -> UIFont
}

public struct Fonts {
   public static var current: FontsProtocol {
       if #available(iOS 8.2, *) {
           return ModernFonts()
       }
       return LegacyFonts()
   }
}

@available(iOS 8.2, *)
public struct ModernFonts: FontsProtocol {
    public func bold11() -> UIFont {
        return UIFont.systemFont(ofSize: 11, weight: .bold)
    }

    public func bold13() -> UIFont {
        return UIFont.systemFont(ofSize: 13, weight: .bold)
    }

    public func light11() -> UIFont {
        return UIFont.systemFont(ofSize: 11, weight: .light)
    }

    public func semibold11() -> UIFont {
        return UIFont.systemFont(ofSize: 11, weight: .semibold)
    }

    public func semibold12() -> UIFont {
        return UIFont.systemFont(ofSize: 12, weight: .semibold)
    }

    public func regular11() -> UIFont {
        return UIFont.systemFont(ofSize: 11, weight: .regular)
    }

    public func regular12() -> UIFont {
        return UIFont.systemFont(ofSize: 12, weight: .regular)
    }
}

public struct LegacyFonts: FontsProtocol {
    public func bold11() -> UIFont {
        return UIFont.boldSystemFont(ofSize: 11)
    }

    public func bold13() -> UIFont {
        return UIFont.boldSystemFont(ofSize: 13)
    }

    public func light11() -> UIFont {
        return UIFont.systemFont(ofSize: 11)
    }

    public func semibold11() -> UIFont {
        return UIFont.boldSystemFont(ofSize: 11)
    }

    public func semibold12() -> UIFont {
        return UIFont.boldSystemFont(ofSize: 12)
    }

    public func regular11() -> UIFont {
        return UIFont.systemFont(ofSize: 11)
    }

    public func regular12() -> UIFont {
        return UIFont.systemFont(ofSize: 12)
    }
}
