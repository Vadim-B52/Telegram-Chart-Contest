//
//  Images.swift
//  Telegram Chart
//
//  Created by Vadim on 12/03/2019.
//  Copyright © 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

extension UIImage {
    static func plotIndicatorWithColor(_ color: UIColor) -> UIImage {
        return imageOf(size: CGSize(width: 10, height: 10), color: color)
    }

    static func navigationBarImage(_ color: UIColor) -> UIImage {
        return imageOf(size: CGSize(width: 1, height: 1), color: color)
    }

    private static func imageOf(size: CGSize, color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
